part of dart_hydrologis_db;

abstract class ADb {
  /// Open the database or create a new one.
  ///
  /// If supplied the [populateFunction] is used.
  ///
  /// For sqlite this happens if the db didn't exist, while
  /// for postgres the function is executed no matter what,
  /// if available.
  void open({Function populateFunction});

  /// Checks if the database is open.
  bool isOpen();

  /// Close the database.
  void close();

  /// Get the list of user created schemas, if necessary [doOrder].
  List<String> getSchemas({bool doOrder = false});

  /// Get the list of table names, if necessary [doOrder].
  List<TableName> getTables({bool doOrder = false});

  /// Check is a given [tableName] exists.
  bool hasTable(TableName tableName);

  /// Get the [tableName] columns as array of:
  ///   - name (string),
  ///   - type (string),
  ///   - isPrimaryKey (int, 1 for true)
  ///   - notnull (int).
  List<List<dynamic>> getTableColumns(TableName tableName);

  /// Get the primary key from a non spatial db.
  String? getPrimaryKey(TableName tableName);

  /// Get a list of items defined by the [queryObj].
  ///
  /// Optionally a custom [whereString] piece can be passed in.
  /// It can start with the keyword where.
  List<T> getQueryObjectsList<T>(QueryObjectBuilder<T> queryObj,
      {String? whereString}) {
    String querySql = "${queryObj.querySql()}";
    if (whereString != null && whereString.isNotEmpty) {
      if (whereString.trim().toLowerCase().startsWith("where")) {
        querySql += whereString;
      } else {
        querySql += " where $whereString";
      }
    }

    List<T> items = [];
    var res = select(querySql);
    res.forEach((QueryResultRow row) {
      var obj = queryObj.fromRow(row);
      items.add(obj);
    });
    return items;
  }

  /// Execute an insert, update or delete using [sqlToExecute] in normal
  /// or prepared mode using [arguments].
  ///
  /// This returns the number of affected rows. Only if [getLastInsertId]
  /// is set to true, the id of the last inserted row is returned. The [primaryKey]
  /// is sometimes necessary to retrieve the last inserted id.
  int? execute(String sqlToExecute,
      {List<dynamic> arguments,
      bool getLastInsertId = false,
      String? primaryKey});

  /// The standard query method.
  QueryResult select(String sql, [List<dynamic> arguments]);

  /// Insert a new record using a map [values] into a given [table].
  ///
  /// This returns the id of the inserted row.
  int? insertMap(TableName table, Map<String, dynamic> values) {
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

    var pk = getPrimaryKey(table);
    var sql = "insert into ${table.fixedName} ( $keys ) values ( $questions );";
    return execute(sql, arguments: args, getLastInsertId: true, primaryKey: pk);
  }

  /// Update a new record using a map and a where condition.
  ///
  /// This returns the number of rows affected.
  int? updateMap(TableName table, Map<String, dynamic> values, String where) {
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

    var sql = "update ${table.fixedName} set $keysVal where $where;";
    return execute(sql, arguments: args);
  }

  /// Run a set of operations inside a transaction.
  ///
  /// This returns whatever the function's return value is.
  dynamic transaction(Function transactionOperations) {
    return Transaction(this).runInTransaction(transactionOperations);
  }
}

abstract class ADbAsync {
  /// Open the database and returns true upon success.
  ///
  /// If supplied the [populateFunction] is used.
  ///
  /// For sqlite this happens if the db didn't exist, while
  /// for postgres the function is executed no matter what,
  /// if available.
  Future<bool> open({Function populateFunction});

  /// Checks if the database is open.
  bool isOpen();

  /// Close the database.
  Future<void> close();

  /// Get the list of user created schemas, if necessary [doOrder].
  Future<List<SqlName>> getSchemas({bool doOrder = false});

  /// Get the list of table names, if necessary [doOrder].
  Future<List<TableName>> getTables({bool doOrder = false});

  /// Check is a given [tableName] exists.
  Future<bool> hasTable(TableName tableName);

  /// Get the [tableName] columns as array of:
  ///   - name (string),
  ///   - type (string),
  ///   - isPrimaryKey (int, 1 for true)
  ///   - notnull (int).
  Future<List<List<dynamic>>> getTableColumns(TableName tableName);

  /// Get the primary key for a given table.
  Future<String?> getPrimaryKey(TableName tableName);

  /// Get a list of items defined by the [queryObj].
  ///
  /// Optionally a custom [whereString] piece can be passed in. This needs to start with the word where.
  Future<List<T>> getQueryObjectsList<T>(QueryObjectBuilder<T> queryObj,
      {whereString = ""}) async {
    String querySql = "${queryObj.querySql()}";
    if (whereString != null && whereString.isNotEmpty) {
      querySql += " where $whereString";
    }

    List<T> items = [];
    var res = await select(querySql);
    res?.forEach((QueryResultRow row) {
      var obj = queryObj.fromRow(row);
      items.add(obj);
    });
    return items;
  }

  /// Execute an insert, update or delete using [sqlToExecute] in normal
  /// or prepared mode using [arguments].
  ///
  /// This returns the number of affected rows. Only if [getLastInsertId]
  /// is set to true, the id of the last inserted row is returned. The [primaryKey]
  /// is sometimes necessary to retrieve the last inserted id.
  Future<int?> execute(String sqlToExecute,
      {List<dynamic> arguments,
      bool getLastInsertId = false,
      String? primaryKey});

  /// The standard query method.
  Future<QueryResult?> select(String sql, [List<dynamic> arguments]);

  /// Insert a new record using a map [values] into a given [table].
  ///
  /// This returns the id of the inserted row.
  Future<int?> insertMap(TableName table, Map<String, dynamic> values) async {
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

    var pk = await getPrimaryKey(table);
    var sql = "insert into ${table.fixedName} ( $keys ) values ( $questions );";
    return await execute(sql,
        arguments: args, getLastInsertId: true, primaryKey: pk);
  }

  /// Update a new record using a map and a where condition.
  ///
  /// This returns the number of rows affected.
  Future<int?> updateMap(
      TableName table, Map<String, dynamic> values, String where) async {
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

    var sql = "update ${table.fixedName} set $keysVal where $where;";
    return await execute(sql, arguments: args);
  }

  /// Run a set of operations inside a transaction.
  ///
  /// This returns whatever the function's return value is.
  Future<dynamic>? transaction(Function transactionOperations) async {
    return await TransactionAsync(this).runInTransaction(transactionOperations);
  }
}
