part of dart_hydrologis_db;

/// A very simple Logger singleton class without external logger dependencies.
///
/// Logs to console and a database on the device.
class SLogger {
  static final SLogger _instance = SLogger._internal();

  LogDb _logDb;
  String _folder;

  bool doConsoleLogging = true;

  factory SLogger() => _instance;

  SLogger._internal();

  /// Initialize database logging. Without this call, everything goes just to standard out.
  bool init(String folder) {
    _folder = folder;
    i("Initializing SLogger with folder: $_folder");

    _logDb = LogDb();
    return _logDb.init(_folder);
  }

  /// Delete all the log db content.
  void clearLog() {
    _logDb._db.execute("delete from ${LogDb.TABLE_NAME};");
  }

  String get folder => _folder;

  String get dbPath => _logDb?.path;

  void v(dynamic message) {
    _logDb?.put(Level.verbose, message);
    if (doConsoleLogging) {
      print("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
      print("v: ${message.toString()}");
      print("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
    }
  }

  void d(dynamic message) {
    _logDb?.put(Level.debug, message);
    if (doConsoleLogging) {
      print("ddddddddddddddddddddddddddddddddddd");
      print("d: ${message.toString()}");
      print("ddddddddddddddddddddddddddddddddddd");
    }
  }

  void i(dynamic message) {
    _logDb?.put(Level.info, message);
    if (doConsoleLogging) {
      print("iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii");
      print("i: ${message.toString()}");
      print("iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii");
    }
  }

  void w(dynamic message) {
    _logDb?.put(Level.warning, message);
    if (doConsoleLogging) {
      print("wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww");
      print("w: ${message.toString()}");
      print("wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww");
    }
  }

  void e(dynamic message, [StackTrace stackTrace]) {
    _logDb?.put(Level.error, message);
    if (stackTrace != null) {
      _logDb?.put(Level.error, Trace.format(stackTrace));
    }
    if (doConsoleLogging) {
      print("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
      print("e: ${message.toString()}");
      if (stackTrace != null) {
        print(stackTrace);
      }
      print("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
    }
  }

  /// Get the current list of log items.
  List<GpLogItem> getLogItems({int limit}) {
    return _logDb.getLogItems(limit: limit);
  }
}

/// [Level]s to control logging output. Logging can be enabled to include all
/// levels above certain [Level].
enum Level {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf,
  nothing,
}

/// [QueryObjectBuilder] to allow easy extraction from the db.
class GpLogItemQueryBuilder extends QueryObjectBuilder<GpLogItem> {
  var limit;

  @override
  GpLogItem fromMap(dynamic map) {
    GpLogItem l = GpLogItem()
      ..level = map[LogDb.level_NAME]
      ..message = map[LogDb.message_NAME]
      ..ts = map[LogDb.TimeStamp_NAME];
    return l;
  }

  @override
  String insertSql() {
    // UNUSED
    return null;
  }

  @override
  String querySql() {
    String sql = '''
        SELECT ${LogDb.level_NAME}, ${LogDb.message_NAME}, ${LogDb.TimeStamp_NAME}
        FROM ${LogDb.TABLE_NAME}
        ORDER BY ${LogDb.TimeStamp_NAME} DESC ${limit != null ? " LIMIT " + limit.toString() : ""}
    ''';
    return sql;
  }

  @override
  Map<String, dynamic> toMap(GpLogItem item) {
    return item.toMap();
  }
}

class GpLogItem {
  String level;
  String message;
  int ts = DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      LogDb.level_NAME: level,
      LogDb.message_NAME: message,
      LogDb.TimeStamp_NAME: ts,
    };
  }
}

class LogDb {
  static final String DB_NAME = "gp_debug.sqlite";
  static final String TABLE_NAME = "debug";
  static final String ID_NAME = "id";
  static final String message_NAME = "msg";
  static final String TimeStamp_NAME = "ts";
  static final String level_NAME = "level";

  static final String CREATE_STATEMENT = '''
    CREATE TABLE $TABLE_NAME (
      $ID_NAME INTEGER PRIMARY KEY AUTOINCREMENT,
      $TimeStamp_NAME INTEGER,
      $level_NAME TEXT,
      $message_NAME TEXT
    );"
  ''';

  SqliteDb _db;
  String _dbPath;

  List<GpLogItem> getLogItems({int limit}) {
    var queryObj = GpLogItemQueryBuilder();
    if (limit != null) {
      queryObj.limit = limit;
    }
    List<GpLogItem> result = _db.getQueryObjectsList(queryObj);
    return result;
  }

  bool init(String folder) {
    try {
      SLogger().i("Init LogDb with folder: $folder and app name: $DB_NAME");
      _dbPath = joinPaths(folder, DB_NAME);
      _db = SqliteDb(_dbPath);
      _db.open(populateFunction: createLogDatabase);
    } catch (e, s) {
      SLogger().e("Error initializing LogDb", s);
      return false;
    }
    return true;
  }

  static String joinPaths(String path1, String path2) {
    if (path2.startsWith('/')) {
      path2 = path2.substring(1);
      if (!path1.endsWith('/')) {
        path1 = path1 + '/';
      }
    }
    return join(path1, path2);
  }

  String get path => _dbPath;

  void createLogDatabase(var db) {
    db?.execute(CREATE_STATEMENT);
  }

  void put(Level level, String message) {
    var item = GpLogItem()
      ..level = level.toString()
      ..message = message;
    _db?.insertMap(SqlName(TABLE_NAME), item.toMap());
  }
}
