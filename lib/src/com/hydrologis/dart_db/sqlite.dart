part of dart_hydrologis_db;

/// The Sqlite database used for project and datasets as mbtiles.
class SqliteDb extends ADb {
  Database _db;
  String _dbPath;
  bool _isClosed = false;

  SqliteDb(this._dbPath);

  SqliteDb.memory() {
    _dbPath = null;
  }

  @override
  bool isAsync() {
    return false;
  }

  @override
  void open({Function populateFunction}) {
    bool existsAlready;
    if (_dbPath == null) {
      _db = sqlite3.openInMemory();
      // _db = Database.memory();
      existsAlready = false;
    } else {
      var dbFile = File(_dbPath);
      existsAlready = dbFile.existsSync();
      _db = sqlite3.open(_dbPath);
      // _db = Database.openFile(dbFile);
    }
    if (!existsAlready && populateFunction != null) {
      // db is open already, we can use the wrapper for the create function.
      populateFunction(this);
    }
  }

  /// Get the database path.
  String get path => _dbPath;

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
  Database getInternalDb() {
    return _db;
  }

  @override
  int execute(String sqlToExecute,
      {List<dynamic> arguments, bool getLastInsertId = false}) {
    PreparedStatement stmt;
    try {
      stmt = _db.prepare(sqlToExecute);
      stmt.execute(arguments);

      if (getLastInsertId) {
        return _db.lastInsertRowId;
        // return _db.getLastInsertId();
      } else {
        return _db.getUpdatedRows();
      }
    } finally {
      stmt?.dispose();
      // stmt?.close();
    }
  }

  @override
  QueryResult select(String sql, [List<dynamic> arguments]) {
    PreparedStatement selectStmt;
    try {
      selectStmt = _db.prepare(sql);
      final ResultSet result = selectStmt.select(arguments);
      return QueryResult.fromResultSet(result);
    } finally {
      selectStmt?.dispose();
      // selectStmt?.close();
    }
  }

  @override
  List<SqlName> getTables({bool doOrder = false}) {
    List<SqlName> tableNames = [];
    String orderBy = " ORDER BY name";
    if (!doOrder) {
      orderBy = "";
    }
    String sql =
        "SELECT name FROM sqlite_master WHERE type='table' or type='view'" +
            orderBy;
    var res = select(sql);
    res.forEach((row) {
      var name = row['name'];
      tableNames.add(SqlName(name));
    });
    return tableNames;
  }

  @override
  bool hasTable(SqlName tableName) {
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
  List<List<dynamic>> getTableColumns(SqlName tableName) {
    String sql = "PRAGMA table_info(${tableName.fixedName})";
    List<List<dynamic>> columnsList = [];

    var res = select(sql);
    res.forEach((row) {
      String colName = row.get('name');
      String colType = row.get('type');
      int isPk = row.get('pk');
      int notNull = row.get('notnull');
      columnsList.add([colName, colType, isPk, notNull]);
    });
    return columnsList;
  }

  @override
  String getPrimaryKey(SqlName tableName) {
    String sql = "PRAGMA table_info(${tableName.fixedName})";
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
    String functionName,
    ScalarFunction function,
    int argumentCount,
    bool deterministic = false,
    bool directOnly = true,
  }) {
    _db.createFunction(
      functionName: functionName,
      argumentCount: AllowedArgumentCount(argumentCount),
      deterministic: deterministic,
      directOnly: directOnly,
      function: function,
    );
  }
}
