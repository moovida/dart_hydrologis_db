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

  /// Get the list of table names, if necessary [doOrder].
  List<SqlName> getTables({bool doOrder = false});

  /// Check is a given [tableName] exists.
  bool hasTable(SqlName tableName);

  /// Get the [tableName] columns as array of:
  ///   - name (string),
  ///   - type (string),
  ///   - isPrimaryKey (int, 1 for true)
  ///   - notnull (int).
  List<List<dynamic>> getTableColumns(SqlName tableName);

  /// Get the primary key from a non spatial db.
  String getPrimaryKey(SqlName tableName);

  /// Get a list of items defined by the [queryObj].
  ///
  /// Optionally a custom [whereString] piece can be passed in. This needs to start with the word where.
  List<T> getQueryObjectsList<T>(QueryObjectBuilder<T> queryObj,
      {whereString = ""});

  /// Execute an insert, update or delete using [sqlToExecute] in normal
  /// or prepared mode using [arguments].
  ///
  /// This returns the number of affected rows. Only if [getLastInsertId]
  /// is set to true, the id of the last inserted row is returned.
  int execute(String sqlToExecute,
      {List<dynamic> arguments, bool getLastInsertId = false});

  /// The standard query method.
  QueryResult select(String sql, [List<dynamic> arguments]);

  /// Insert a new record using a map [values] into a given [table].
  ///
  /// This returns the id of the inserted row.
  int insertMap(SqlName table, Map<String, dynamic> values) {
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

    var sql = "insert into ${table.fixedName} ( $keys ) values ( $questions );";
    return execute(sql, arguments: args, getLastInsertId: true);
  }

  /// Update a new record using a map and a where condition.
  ///
  /// This returns the number of rows affected.
  int updateMap(SqlName table, Map<String, dynamic> values, String where) {
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

abstract class ASpatialDb {}

class QueryResult {
  ResultSet resultSet;
  QueryResult.fromResultSet(this.resultSet);

  int get length {
    if (resultSet != null) {
      return resultSet.length;
    }
    throw StateError("No query result defined.");
  }

  QueryResultRow get first {
    if (resultSet != null) {
      return QueryResultRow.fromResultSetRow(resultSet.first);
    }
    throw StateError("No query result defined.");
  }

  /// Run a function taking a [QueryResultRow] on the whole [QueryResult].
  void forEach(Function rowFunction) {
    if (resultSet != null) {
      resultSet.forEach((row) {
        rowFunction(row);
      });
      return;
    }
    throw StateError("No query result defined.");
  }

  /// Find the [QueryResultRow] given a field and value.
  QueryResultRow find(String field, dynamic value) {
    if (resultSet != null) {
      for (var map in resultSet) {
        var checkValue = map[field];
        if (checkValue == value) {
          return QueryResultRow.fromResultSetRow(map);
        }
      }
      return null;
    }
    throw StateError("No query result defined.");
  }
}

class QueryResultRow {
  Row resultSetRow;
  QueryResultRow.fromResultSetRow(this.resultSetRow);

  dynamic get(String filedName) {
    if (resultSetRow != null) {
      return resultSetRow[filedName];
    }
    throw StateError("No query result defined.");
  }

  dynamic getAt(int index) {
    if (resultSetRow != null) {
      return resultSetRow.columnAt(index);
    }
    throw StateError("No query result defined.");
  }
}
