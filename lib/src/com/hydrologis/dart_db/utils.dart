part of dart_hydrologis_db;

abstract class QueryObjectBuilder<T> {
  String querySql();

  Map<String, dynamic> toMap(T item);

  /// Extract the item from a [key, value] object.
  T fromMap(dynamic map);
}

class SqliteTypes {
  static const INTEGER = SqliteTypes._([
    "INT",
    "INTEGER",
    "TINYINT",
    "SMALLINT",
    "MEDIUMINT",
    "BIGINT",
    "UNSIGNED BIG INT",
    "INT2",
    "INT8",
  ]);
  static const DOUBLE = SqliteTypes._([
    "REAL",
    "DOUBLE",
    "DOUBLE PRECISION",
    "FLOAT",
    "NUMERIC",
    "BOOLEAN",
    "DATE",
    "DATETIME",
  ]);
  static const DOUBLE_SW = SqliteTypes._([
    "DECIMAL",
  ]);
  static const TEXT = SqliteTypes._([
    "TEXT",
    "CLOB",
  ]);
  static const TEXT_SW = SqliteTypes._([
    "TEXT",
    "CHARACTER",
    "VARCHAR",
    "VARYING CHARACTER",
    "NCHAR",
    "NATIVE CHARACTER",
    "NVARCHAR",
    "CLOB",
  ]);

  // static get values => [APPLE, BANANA];

  final List<String> value;

  const SqliteTypes._(this.value);

  /// Checks if a [upperCaseTypeString] is of a integer type.
  ///
  /// The typeString comes from the [SqliteDb.getTableColumns] method.
  static bool isInteger(String upperCaseTypeString) {
    return INTEGER.value.contains(upperCaseTypeString);
  }

  /// Checks if a [upperCaseTypeString] is of a text type.
  ///
  /// The typeString comes from the [SqliteDb.getTableColumns] method.
  static bool isString(String upperCaseTypeString) {
    bool isText = TEXT.value.contains(upperCaseTypeString);
    if (!isText) {
      isText = TEXT_SW.value.indexWhere(
              (element) => upperCaseTypeString.startsWith(element)) !=
          -1;
    }
    return isText;
  }

  /// Checks if a [upperCaseTypeString] is of a double type.
  ///
  /// The typeString comes from the [SqliteDb.getTableColumns] method.
  static bool isDouble(String upperCaseTypeString) {
    bool isDouble = DOUBLE.value.contains(upperCaseTypeString);
    if (!isDouble) {
      isDouble = DOUBLE_SW.value.indexWhere(
              (element) => upperCaseTypeString.startsWith(element)) !=
          -1;
    }
    return isDouble;
  }
}

class DbsUtilities {
  /// Check the tablename and fix it if necessary.
  ///
  /// @param name the name to check.
  /// @return the fixed name.
  static String fixWithQuotes(String name) {
    if (name[0] == '\'') {
      // already fixed
      return name;
    }
    double num = double.tryParse(name.substring(0, 1));

    if (num != null ||
        name.contains("-") ||
        name.contains(",") ||
        name.contains(RegExp(r'\s+'))) {
      return "'" + name + "'";
    }
    return name;
  }

  /// Check the columnName and fix it if necessary.
  ///
  /// @param name the name to check.
  /// @return the fixed name.
  static String fixWithBrackets(String name) {
    if (name[0] == '[') {
      // already fixed
      return name;
    }
    double num = double.tryParse(name.substring(0, 1));

    if (num != null ||
        name.contains("-") ||
        name.contains(",") ||
        name.contains(RegExp(r'\s+'))) {
      return "[" + name + "]";
    }
    return name;
  }
}

/// A name for sql related strings (table names and column names ex.).
///
/// This will contain the original name,the fixed one and the one between square brackets.
class SqlName {
  final String name;

  /// The name fixed by quoting, if necessary.
  ///
  /// This might be needed for strange table names.
  final String fixedName;

  /// The name fixed by surrounding with square brackets, if necessary.
  ///
  /// This might be needed for example in select queries for strange column names.
  final String bracketName;

  SqlName(this.name)
      : fixedName = DbsUtilities.fixWithQuotes(name),
        bracketName = DbsUtilities.fixWithBrackets(name);
}
