part of dart_hydrologis_db;

abstract class QueryObjectBuilder<T> {
  String querySql();

  String insertSql();

  Map<String, dynamic> toMap(T item);

  /// Extract the item from a [key, value] object.
  T fromMap(dynamic map);
}