part of dart_hydrologis_db;

/// The Postgresql database instance.
class PostgresqlDb extends ADbAsync {
  final String _host;
  final String _dbName;
  String? user;
  String? pwd;
  int port;
  bool _isClosed = false;
  PostgreSQLConnection? _db;

  PostgresqlDb(
    this._host,
    this._dbName, {
    this.port = 5432,
    this.user,
    this.pwd,
  });

  @override
  Future<bool> open({Function? populateFunction}) async {
    try {
      if (_db != null) {
        throw StateError("Database already opened.");
      }
      _db = PostgreSQLConnection(_host, port, _dbName,
          username: user, password: pwd);
      await _db?.open();

      if (populateFunction != null) {
        await populateFunction(this);
      }
      return true;
    } on Exception {
      _db = null;
      rethrow;
      // return false;
    }
  }

  /// Get the database path.
  // String get path => _dbPath;

  @override
  bool isOpen() {
    if (_db == null || _db!.isClosed) return false;
    return !_isClosed;
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    return await _db?.close();
  }

  /// This should only be used when a custom function is necessary,
  /// which forces to use the method from the moor database.
  PostgreSQLConnection? getInternalDb() {
    return _db;
  }

  @override
  Future<int?> execute(String sqlToExecute,
      {List<dynamic>? arguments, bool getLastInsertId = false}) async {
    int count = 1;
    Map<String, dynamic>? paramsMap;
    if (arguments != null) {
      paramsMap = {};
      for (var arg in arguments) {
        String placeHolder = "p$count";
        paramsMap[placeHolder] = arg;
        sqlToExecute = sqlToExecute.replaceFirst("?", "@" + placeHolder);
        count++;
      }
    }

    PostgreSQLResult? sqlResult;
    try {
      sqlResult = await _db?.query(sqlToExecute, substitutionValues: paramsMap);
      if (getLastInsertId) {
        throw Exception("Not implemented");
        // return _db.lastInsertRowId;

        // TODO this is now supported as
        // final primaryKeyName = 'id';
        // final res = await yourConnection.query('INSERT INTO $tableName ($keys) VALUES ($values) RETURNING $primaryKeyName;');
        // final lastInsertedId = res.last[0] as int;
      } else {
        return sqlResult?.affectedRowCount;
      }
    } on Exception catch (e, s) {
      SLogger().e("Execute error.", e, s);
    }
    return null;
  }

  @override
  Future<QueryResult?> select(String sql, [List<dynamic>? arguments]) async {
    int count = 1;
    Map<String, dynamic>? paramsMap;
    if (arguments != null) {
      paramsMap = {};
      for (var arg in arguments) {
        String placeHolder = "p$count";
        paramsMap[placeHolder] = arg;
        sql = sql.replaceFirst("?", "@" + placeHolder);
        count++;
      }
    }
    try {
      var sqlResult = await _db?.query(sql, substitutionValues: paramsMap);
      return QueryResult.fromPostgresqlResult(sqlResult);
    } on Exception catch (ex, s) {
      SLogger().e("Execute error.", ex, s);
    }
    return null;
  }

  @override
  Future<int?> insertMap(SqlName table, Map<String, dynamic> values) async {
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

    var sql =
        "insert into ${table.fixedDoubleName} ( $keys ) values ( $questions );";
    await execute(sql, arguments: args, getLastInsertId: false);

    var pkName = await getPrimaryKey(table);
    var maxPk = 0;
    if (values.containsKey(pkName)) {
      sql = "select max($pkName) from ${table.fixedDoubleName}";
      var queryResult = await select(sql);
      maxPk = queryResult?.first.getAt(0);
    }
    return maxPk;
  }

  @override
  Future<int?> updateMap(
      SqlName table, Map<String, dynamic> values, String where) async {
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

    var sql = "update ${table.fixedDoubleName} set $keysVal where $where;";
    return await execute(sql, arguments: args);
  }

  @override
  Future<List<SqlName>> getTables({bool doOrder = false}) async {
    List<SqlName> tableNames = [];
    String orderBy = " ORDER BY table_name";
    if (!doOrder) {
      orderBy = "";
    }
    String sql = """SELECT table_name FROM INFORMATION_SCHEMA.TABLES
        WHERE (TABLE_TYPE='BASE TABLE' or TABLE_TYPE='VIEW' or TABLE_TYPE='EXTERNAL')
        and table_schema='public'
        and table_name != 'geography_columns'
        and table_name != 'geometry_columns'
        and table_name != 'spatial_ref_sys'
        and table_name != 'raster_columns'
        and table_name != 'raster_overviews'
        $orderBy;""";
    var res = await select(sql);
    res?.forEach((QueryResultRow row) {
      var name = row.get('table_name');
      tableNames.add(SqlName(name));
    });
    return tableNames;
  }

  @override
  Future<bool> hasTable(SqlName tableName) async {
    String sql = """SELECT count(table_name) FROM INFORMATION_SCHEMA.TABLES
                WHERE (TABLE_TYPE='BASE TABLE' or TABLE_TYPE='VIEW' or TABLE_TYPE='EXTERNAL') 
                and table_schema='public' 
                and upper(table_name) = upper(?)
                """;

    var res = await select(sql, [tableName.name]);
    if (res != null && res.length == 1) {
      var row = res.first;
      var count = row.getAt(0);
      return count == 1;
    }
    return false;
  }

  @override
  Future<List<List>> getTableColumns(SqlName tableName) async {
    var pkName = await getPrimaryKey(tableName);

    String sql = """select column_name, data_type 
                    from information_schema.columns 
                    where upper(table_name)=upper(?) 
                    and table_Schema!='information_schema'""";

    List<List<dynamic>> columnsList = [];

    var res = await select(sql, [tableName.name]);
    res?.forEach((QueryResultRow row) {
      String colName = row.get('column_name');
      String colType = row.get('data_type');
      int isPk = 0;
      if (pkName != null && colName == pkName) {
        isPk = 1;
      }
      // TODO check
      int? notNull; //row['notnull'];
      columnsList.add([colName, colType, isPk, notNull]);
    });
    return columnsList;
  }

  @override
  Future<String?> getPrimaryKey(SqlName tableName) async {
    var queryResult = await select(getIndexSql(tableName));
    if (queryResult?.length == 0) {
      return null;
    }
    var queryResultRow = queryResult?.first;
    String? pkName;
    String? indexName = queryResultRow?.get("index_name").toString();
    if (indexName != null && indexName.toLowerCase().contains("pkey")) {
      String? columnDef = queryResultRow?.get("column").toString();
      pkName = columnDef?.split(RegExp(r"\s+"))[0];
    }
    return pkName;
  }

  String getIndexSql(SqlName tableName) {
    return "SELECT  tnsp.nspname AS schema_name,   trel.relname AS table_name,   irel.relname AS index_name,   " + //
        " a.attname    || ' ' || CASE o.option & 1 WHEN 1 THEN 'DESC' ELSE 'ASC' END   || ' ' || CASE  " + //
        " o.option & 2 WHEN 2 THEN 'NULLS FIRST' ELSE 'NULLS LAST' END   AS column, " + //
        " pi.indexdef " + //
        " FROM pg_index AS i JOIN pg_class AS trel ON trel.oid = i.indrelid JOIN pg_namespace AS tnsp  " + //
        " ON trel.relnamespace = tnsp.oid JOIN pg_class AS irel ON irel.oid = i.indexrelid CROSS JOIN LATERAL " + //
        "  unnest (i.indkey) WITH ORDINALITY AS c (colnum, ordinality) LEFT JOIN LATERAL unnest (i.indoption)  " + //
        "  WITH ORDINALITY AS o (option, ordinality)   ON c.ordinality = o.ordinality JOIN  " + //
        "  pg_attribute AS a ON trel.oid = a.attrelid AND  " + //
        "  a.attnum = c.colnum , " + //
        "  pg_indexes pi " + //
        "  where pi.indexname=irel.relname " + //
        "  and upper(trel.relname)=upper('" +
        tableName.name +
        "')";
  }

  @override
  Future<dynamic>? transaction(Function transactionOperations) async {
    return await _db?.transaction(transactionOperations as Future Function(
        PostgreSQLExecutionContext connection));
  }
}
