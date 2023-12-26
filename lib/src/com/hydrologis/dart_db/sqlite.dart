part of dart_hydrologis_db;

/// The Sqlite database used for project and datasets as mbtiles.
class SqliteDb extends ADb {
  Database? _db;
  String? _dbPath;
  Function? _populateFunction;
  bool _isClosed = false;

  SqliteDb(this._dbPath);

  SqliteDb.memory() {
    _dbPath = null;
  }

  bool isAsync() {
    return false;
  }

  @override
  void open({Function? populateFunction}) {
    _populateFunction = populateFunction;
    bool existsAlready;
    if (_dbPath == null) {
      _db = sqlite3.openInMemory();
      // _db = Database.memory();
      existsAlready = false;
    } else {
      var dbFile = File(_dbPath!);
      existsAlready = dbFile.existsSync();
      _db = sqlite3.open(_dbPath!);
      // _db = Database.openFile(dbFile);
    }
    if (!existsAlready && populateFunction != null) {
      // db is open already, we can use the wrapper for the create function.
      populateFunction(this);
    }
  }

  void checkOpen() {
    if (_db == null || _isClosed) {
      // reopen it
      open(populateFunction: _populateFunction);
    }
  }

  /// Get the database path.
  String? get path => _dbPath;

  @override
  bool isOpen() {
    if (_db == null) return false;
    return !_isClosed;
  }

  @override
  void close() {
    _isClosed = true;
    return _db?.dispose();
    // return _db?.close();
  }

  /// This should only be used when a custom function is necessary,
  /// which forces to use the method from the moor database.
  Database? getInternalDb() {
    return _db;
  }

  @override
  int? execute(String sqlToExecute,
      {List<dynamic>? arguments,
      bool getLastInsertId = false,
      String? primaryKey}) {
    checkOpen();
    PreparedStatement? stmt;
    try {
      stmt = _db?.prepare(sqlToExecute);

      List<Object?> args = [];
      arguments?.forEach((element) {
        args.add(element);
      });
      stmt?.execute(args);

      if (getLastInsertId) {
        return _db?.lastInsertRowId;
        // return _db.getLastInsertId();
      } else {
        return _db?.getUpdatedRows();
      }
    } finally {
      stmt?.dispose();
      // stmt?.close();
    }
  }

  @override
  QueryResult select(String sql, [List<dynamic>? arguments]) {
    checkOpen();
    PreparedStatement? selectStmt;
    try {
      selectStmt = _db?.prepare(sql);
      List<Object?> args = [];
      arguments?.forEach((element) {
        args.add(element);
      });
      final ResultSet? result = selectStmt?.select(args);
      return SqliteQueryResult.fromResultSet(result);
    } finally {
      selectStmt?.dispose();
      // selectStmt?.close();
    }
  }

  @override
  List<String> getSchemas({bool doOrder = false}) {
    /// sqlite doesn't use schemas in that sense.
    return [];
  }

  @override
  List<TableName> getTables({bool doOrder = false}) {
    checkOpen();
    List<TableName> tableNames = [];
    String orderBy = " ORDER BY name";
    if (!doOrder) {
      orderBy = "";
    }
    String sql =
        "SELECT name FROM sqlite_master WHERE type='table' or type='view'" +
            orderBy;
    var res = select(sql);
    res.forEach((QueryResultRow row) {
      var name = row.get('name');
      tableNames.add(TableName(name, schemaSupported: false));
    });
    return tableNames;
  }

  @override
  bool hasTable(TableName tableName) {
    checkOpen();
    String sql = """
      SELECT count(name) FROM sqlite_master WHERE type='table' 
      and lower(name)=lower(?)
    """;

    var res = select(sql, [tableName.name]);
    if (res.length == 1) {
      var row = res.first;
      var count = row.getAt(0);
      return count == 1;
    }
    return false;
  }

  @override
  List<List<dynamic>> getTableColumns(TableName tableName) {
    checkOpen();
    String sql = "PRAGMA table_info(${tableName.fixedName})";
    List<List<dynamic>> columnsList = [];

    var res = select(sql);
    res.forEach((QueryResultRow row) {
      String colName = row.get('name');
      String colType = row.get('type');
      int isPk = row.get('pk');
      int notNull = row.get('notnull');
      columnsList.add([colName, colType, isPk, notNull]);
    });
    return columnsList;
  }

  @override
  String? getPrimaryKey(TableName tableName) {
    checkOpen();
    String sql = "PRAGMA table_info(${tableName.fixedDoubleName})";
    var res = select(sql);
    var resultRow = res.find("pk", 1);
    if (resultRow != null) {
      return resultRow.get("name");
    }
    return null;
  }

  /// Creater a custom callback function.
  ///
  /// The [function] will get a list of objects as argument.
  /// It needs to be of the form:
  ///
  /// (args) {
  ///   return yourValue;
  /// }
  /// The [deterministic] flag (defaults to `false`) can be set to indicate that
  /// the function always gives the same output when the input parameters are
  /// the same (for optimization).
  /// The [directOnly] flag (defaults to `true`) is a security measure. When
  /// enabled, the function may only be invoked form top-level SQL, and cannot
  /// be used in VIEWs or TRIGGERs nor in schema structures (such as CHECK,
  /// DEFAULT, etc.).
  void createFunction({
    required String functionName,
    required ScalarFunction function,
    required int argumentCount,
    bool deterministic = false,
    bool directOnly = true,
  }) {
    checkOpen();
    _db?.createFunction(
      functionName: functionName,
      argumentCount: AllowedArgumentCount(argumentCount),
      deterministic: deterministic,
      directOnly: directOnly,
      function: function,
    );
  }
}

class SqliteQueryResult implements QueryResult {
  ResultSet? sqliteResultSet;
  PostgreSQLResult? postgreSQLResult;

  SqliteQueryResult.fromResultSet(this.sqliteResultSet);

  @override
  int get length {
    if (sqliteResultSet != null) {
      return sqliteResultSet!.length;
    } else if (postgreSQLResult != null) {
      return postgreSQLResult!.length;
    }
    throw StateError("No query result defined.");
  }

  @override
  QueryResultRow get first {
    if (sqliteResultSet != null) {
      return SqliteQueryResultRow.fromSqliteResultSetRow(
          sqliteResultSet!.first);
    }
    throw StateError("No query result defined.");
  }

  /// Run a function taking a [QueryResultRow] on the whole [QueryResult].
  @override
  void forEach(Function rowFunction) {
    if (sqliteResultSet != null) {
      sqliteResultSet!.forEach((row) {
        rowFunction(SqliteQueryResultRow.fromSqliteResultSetRow(row));
      });
      return;
    }
    throw StateError("No query result defined.");
  }

  /// Find the [QueryResultRow] given a field and value.
  @override
  QueryResultRow? find(String field, dynamic value) {
    if (sqliteResultSet != null) {
      for (var map in sqliteResultSet!) {
        var checkValue = map[field];
        if (checkValue == value) {
          return SqliteQueryResultRow.fromSqliteResultSetRow(map);
        }
      }
      return null;
    }
    throw StateError("No query result defined.");
  }
}

class SqliteQueryResultRow implements QueryResultRow {
  Row? sqliteResultSetRow;

  SqliteQueryResultRow.fromSqliteResultSetRow(this.sqliteResultSetRow);

  @override
  dynamic get(String filedName) {
    if (sqliteResultSetRow != null) {
      return sqliteResultSetRow![filedName];
    }
    throw StateError("No query result defined.");
  }

  @override
  dynamic getAt(int index) {
    if (sqliteResultSetRow != null) {
      return sqliteResultSetRow!.columnAt(index);
    }
    throw StateError("No query result defined.");
  }

  /// Run a function taking a a key and its value on the whole [QueryResultRow].
  @override
  void forEach(Function keyValueFunction) {
    if (sqliteResultSetRow == null) {
      throw StateError("No query result defined.");
    }
    sqliteResultSetRow!.forEach((key, value) {
      keyValueFunction(key, value);
    });
  }
}
