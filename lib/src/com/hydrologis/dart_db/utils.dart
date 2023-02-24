part of dart_hydrologis_db;

abstract class QueryObjectBuilder<T> {
  String querySql();

  Map<String, dynamic> toMap(T item);

  /// Extract the item from resultobject row.
  T fromRow(QueryResultRow row);
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
    double? num = double.tryParse(name.substring(0, 1));

    if (num != null ||
        name.contains("-") ||
        name.contains(",") ||
        name.contains(RegExp(r'\s+'))) {
      return "'" + name + "'";
    }
    return name;
  }

  /// Check the tablename and fix it if necessary.
  ///
  /// @param name the name to check.
  /// @return the fixed name.
  static String fixWithDoubleQuotes(String name) {
    if (name[0] == '\"') {
      // already fixed
      return name;
    }
    double? num = double.tryParse(name.substring(0, 1));

    if (num != null ||
        name.contains("-") ||
        name.contains(",") ||
        name.contains(RegExp(r'\s+'))) {
      return "\"" + name + "\"";
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
    double? num = double.tryParse(name.substring(0, 1));

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
  late String name;

  /// The name fixed by quoting, if necessary.
  ///
  /// This might be needed for strange table names.
  late String fixedName;

  /// The name fixed by double quoting, if necessary.
  ///
  /// This might be needed for strange table names in some cases (ex. create table on postgresql).
  late String fixedDoubleName;

  /// The name fixed by surrounding with square brackets, if necessary.
  ///
  /// This might be needed for example in select queries for strange column names.
  late String bracketName;

  SqlName(this.name) {
    fixedName = DbsUtilities.fixWithQuotes(name);
    bracketName = DbsUtilities.fixWithBrackets(name);
    fixedDoubleName = DbsUtilities.fixWithDoubleQuotes(name);
  }
}

/// A name for sql related strings (table names and column names ex.).
///
/// This will contain the original name,the fixed one and the one between square brackets.
class TableName {
  late String name;

  /// The name fixed by quoting, if necessary.
  ///
  /// This might be needed for strange table names.
  late String fixedName;

  /// The name fixed by double quoting, if necessary.
  ///
  /// This might be needed for strange table names in some cases (ex. create table on postgresql).
  late String fixedDoubleName;

  /// The name fixed by surrounding with square brackets, if necessary.
  ///
  /// This might be needed for example in select queries for strange column names.
  late String bracketName;

  String? _schema = "public";

  /// Create a [TableName]. If schemas are not supported , set [schemaSupported] to false].
  TableName(this.name, {bool schemaSupported = true}) {
    if (schemaSupported) {
      if (name.contains(".")) {
        var split = name.split(".");
        name = split[1];
        _schema = split[0];
      }
    } else {
      _schema = null;
    }

    if (_schema != null) {
      fixedName = _schema! + "." + DbsUtilities.fixWithQuotes(name);
      bracketName = _schema! + "." + DbsUtilities.fixWithBrackets(name);
      fixedDoubleName = _schema! + "." + DbsUtilities.fixWithDoubleQuotes(name);
    } else {
      fixedName = DbsUtilities.fixWithQuotes(name);
      bracketName = DbsUtilities.fixWithBrackets(name);
      fixedDoubleName = DbsUtilities.fixWithDoubleQuotes(name);
    }
  }

  String getFullName() {
    String fullName = name;
    if (hasSchema()) {
      fullName = _schema! + "." + name;
    }
    return fullName;
  }

  bool hasSchema() {
    return _schema != null;
  }

  /// Returns the schema.
  ///
  /// This throws an exception if called when schemas are not supported.
  String getSchema() {
    return _schema!;
  }
}
