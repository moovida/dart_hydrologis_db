part of dart_hydrologis_db;

abstract class ADb {
  /// Open the database or create a new one.
  ///
  /// If supplied the [dbCreateFunction] is used.
  void open({Function dbCreateFunction});

  /// Checks if the database is open.
  bool isOpen();

  /// Close the database.
  void close();

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
