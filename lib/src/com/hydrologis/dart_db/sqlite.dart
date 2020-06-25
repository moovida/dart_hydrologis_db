part of dart_hydrologis_db;

/// The Sqlite database used for project and datasets as mbtiles.
class SqliteDb {
  Database _db;
  String _dbPath;
  bool _isClosed = false;

  SqliteDb(this._dbPath);

  SqliteDb.memory() {
    _dbPath = null;
  }

  /// Open the database or create a new one.
  ///
  /// If supplied the [dbCreateFunction] is used.
  void open({Function dbCreateFunction}) {
    bool existsAlready;
    if (_dbPath == null) {
      _db = Database.memory();
      existsAlready = false;
    } else {
      var dbFile = File(_dbPath);
      existsAlready = dbFile.existsSync();
      _db = Database.openFile(dbFile);
    }
    if (!existsAlready && dbCreateFunction != null) {
      // db is open already, we can use the wrapper for the create function.
      dbCreateFunction(this);
    }
  }

  /// Get the database path.
  String get path => _dbPath;

  /// Checks if the database is open.
  bool isOpen() {
    if (_db == null) return false;
    return !_isClosed;
  }

  /// Close the database.
  void close() {
    _isClosed = true;
    return _db?.close();
  }

  /// This should only be used when a custom function is necessary,
  /// which forces to use the method from the moor database.
  Database getInternalDb() {
    return _db;
  }

  /// Get a list of items defined by the [queryObj].
  ///
  /// Optionally a custom [whereString] piece can be passed in. This needs to start with the word where.
  List<T> getQueryObjectsList<T>(QueryObjectBuilder<T> queryObj,
      {whereString = ""}) {
    String querySql = "${queryObj.querySql()} $whereString";

    List<T> items = [];
    var res = select(querySql);
    res.forEach((row) {
      var obj = queryObj.fromMap(row);
      items.add(obj);
    });
    return items;
  }

  /// Execute a insert, update or delete using [sqlToExecute] in normal
  /// or prepared mode using [arguments].
  ///
  /// This returns the number of affected rows. Only if [getLastInsertId]
  /// is set to true, the id of the last inserted row is returned.
  int execute(String sqlToExecute,
      {List<dynamic> arguments, bool getLastInsertId = false}) {
    PreparedStatement stmt;
    try {
      stmt = _db.prepare(sqlToExecute);
      stmt.execute(arguments);

      if (getLastInsertId) {
        return _db.getLastInsertId();
      } else {
        return _db.getUpdatedRows();
      }
    } finally {
      stmt?.close();
    }
  }

  /// The standard query method.
  Iterable<Row> select(String sql, [List<dynamic> arguments]) {
    PreparedStatement selectStmt;
    try {
      selectStmt = _db.prepare(sql);
      final Result result = selectStmt.select(arguments);
      return result;
    } finally {
      selectStmt?.close();
    }
  }

  /// Insert a new record using a map [values] into a given [table].
  ///
  /// This returns the id of the inserted row.
  int insertMap(String table, Map<String, dynamic> values) {
    List<dynamic> args = [];
    var keys;
    var questions;
    values.forEach((key, value) {
      if (keys == null) {
        keys = key;
        questions = "?";
      } else {
        keys = keys + "," + key;
        questions = questions + ",?";
      }
      args.add(value);
    });

    var sql = "insert into $table ( $keys ) values ( $questions );";
    return execute(sql, arguments: args, getLastInsertId: true);
  }

  /// Update a new record using a map and a where condition.
  ///
  /// This returns the number of rows affected.
  int updateMap(String table, Map<String, dynamic> values, String where) {
    List<dynamic> args = [];
    var keysVal;
    values.forEach((key, value) {
      if (keysVal == null) {
        keysVal = "$key=?";
      } else {
        keysVal += ",$key=?";
      }
      args.add(value);
    });

    var sql = "update $table set $keysVal where $where;";
    return execute(sql, arguments: args);
  }

  /// Run a set of operations inside a transaction.
  ///
  /// This returns whatever the function's return value is.
  dynamic transaction(Function transactionOperations) {
    return Transaction(this).runInTransaction(transactionOperations);
  }

  /// Get the list of table names, if necessary [doOrder].
  List<String> getTables({bool doOrder = false}) {
    List<String> tableNames = [];
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
      tableNames.add(name);
    });
    return tableNames;
  }

  /// Check is a given [tableName] exists.
  bool hasTable(String tableName) {
    String sql = "SELECT name FROM sqlite_master WHERE type='table'";
    tableName = tableName.toLowerCase();

    var res = select(sql);
    for (var row in res) {
      var name = row['name'];
      if (name.toLowerCase() == tableName) {
        return true;
      }
    }
    return false;
  }

  /// Get the [tableName] columns as array of name, type and isPrimaryKey.
  List<List<dynamic>> getTableColumns(String tableName) {
    String sql = "PRAGMA table_info(" + tableName + ")";
    List<List<dynamic>> columnsList = [];

    var res = select(sql);
    res.forEach((row) {
      String colName = row['name'];
      String colType = row['type'];
      int isPk = row['pk'];
      columnsList.add([colName, colType, isPk]);
    });
    return columnsList;
  }

  /// Get the primary key from a non spatial db.
  String getPrimaryKey(String tableName) {
    String sql = "PRAGMA table_info(" + tableName + ")";
    var res = select(sql);
    for (var map in res) {
      var pk = map["pk"];
      if (pk == 1) {
        return map["name"];
      }
    }
    return null;
  }
}
