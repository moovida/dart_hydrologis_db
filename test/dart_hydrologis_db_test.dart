import 'package:dart_hydrologis_db/dart_hydrologis_db.dart';
import 'package:test/test.dart';

var t1Name = SqlName("table 1");
var t2Name = SqlName("table2");
var t3Name = SqlName("10table with,nasty");
var col1Name = SqlName("10col with,nasty");

var createTable1 = '''
CREATE TABLE ${t1Name.fixedName} (  
  id INTEGER PRIMARY KEY AUTOINCREMENT, 
  name TEXT,  
  temperature REAL
);
''';

var insertTable1 = [
  "INSERT INTO ${t1Name.fixedName} VALUES(1, 'Tscherms', 36.0);", //
  "INSERT INTO ${t1Name.fixedName} VALUES(2, 'Meran', 34.0);", //
  "INSERT INTO ${t1Name.fixedName} VALUES(3, 'Bozen', 42.0);", //
];

var createTable2 = '''
  CREATE TABLE ${t2Name.fixedName} (  
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    table1id INTEGER,  
    FOREIGN KEY (table1id) REFERENCES ${t1Name.fixedName} (id)
  );
  ''';
var insertTable2 = [
  "INSERT INTO ${t2Name.fixedName} VALUES(1, 1);", //
  "INSERT INTO ${t2Name.fixedName} VALUES(2, 2);", //
  "INSERT INTO ${t2Name.fixedName} VALUES(3, 3);", //
];

var createTable3 = '''
  CREATE TABLE ${t3Name.fixedName} (  
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    ${col1Name.fixedName} INTEGER
  );
  ''';
var insertTable3 = [
  "INSERT INTO ${t3Name.fixedName} VALUES(1, 1);", //
  "INSERT INTO ${t3Name.fixedName} VALUES(2, 2);", //
  "INSERT INTO ${t3Name.fixedName} VALUES(3, 3);", //
];

class Table1Obj {
  int id;
  String name;
  double temperature;
}

class Table1ObjBuilder implements QueryObjectBuilder<Table1Obj> {
  @override
  Table1Obj fromMap(dynamic map) {
    Table1Obj obj = Table1Obj()
      ..id = map['id']
      ..name = map['name']
      ..temperature = map['temperature'];
    return obj;
  }

  @override
  String querySql() {
    return "select id, name, temperature from 'table 1' order by id;";
  }

  @override
  Map<String, dynamic> toMap(Table1Obj obj) {
    return {
      'id': obj.id,
      'name': obj.name,
      'temperature': obj.temperature,
    };
  }
}

void main() {
  test('test creation', () {
    var db = SqliteDb.memory();
    db.open(dbCreateFunction: createDbFunction);

    expect(true, db.hasTable(t1Name));
    expect(true, db.hasTable(t2Name));

    var tableColumns = db.getTableColumns(t1Name);
    expect(3, tableColumns.length);
    tableColumns = db.getTableColumns(t2Name);
    expect(2, tableColumns.length);

    db.close();
  });
  test('test select', () {
    var db = SqliteDb.memory();
    db.open(dbCreateFunction: createDbFunction);

    var select = db.select("select * from 'table 1' order by id");
    var row = select.first;

    expect(row.get('id'), 1);
    expect(row.get('name'), 'Tscherms');
    expect(row.get('temperature'), 36.0);

    db.close();
  });
  test('test insert', () {
    var db = SqliteDb.memory();
    db.open(dbCreateFunction: createDbFunction);

    var sql = "INSERT INTO 'table 1' VALUES(4, 'Egna', 27.0);";
    db.execute(sql);

    var map = {
      'id': 5,
      'name': 'Trento',
      'temperature': 18.0,
    };
    db.insertMap(t1Name, map);

    var select = db.select("select * from ${t1Name.fixedName} where id=4");
    var row = select.first;
    expect(row.get('id'), 4);
    expect(row.get('name'), 'Egna');
    expect(row.get('temperature'), 27.0);

    select = db.select("select * from ${t1Name.fixedName} where id=5");
    row = select.first;
    expect(row.get('id'), 5);
    expect(row.get('name'), 'Trento');
    expect(row.get('temperature'), 18.0);

    db.close();
  });
  test('test update', () {
    var db = SqliteDb.memory();
    db.open(dbCreateFunction: createDbFunction);

    var sql =
        "UPDATE  ${t1Name.fixedName} set name='Egna', temperature=27.0 where id=3;";
    db.execute(sql);

    var select = db.select("select * from ${t1Name.fixedName} where id=3");
    var row = select.first;
    expect(row.get('id'), 3);
    expect(row.get('name'), 'Egna');
    expect(row.get('temperature'), 27.0);

    var map = {
      'name': 'Trento',
      'temperature': 18.0,
    };
    db.updateMap(t1Name, map, "id=3");

    select = db.select("select * from ${t1Name.fixedName} where id=3");
    row = select.first;
    expect(row.get('id'), 3);
    expect(row.get('name'), 'Trento');
    expect(row.get('temperature'), 18.0);

    db.close();
  });

  test('test ugly names', () {
    var db = SqliteDb.memory();
    db.open(dbCreateFunction: createUglyDbFunction);

    expect(true, db.hasTable(t3Name));

    var tableColumns = db.getTableColumns(t3Name);
    expect(2, tableColumns.length);

    var select = db.select(
        "select ${col1Name.bracketName} from ${t3Name.fixedName} where id=1");
    var row = select.first;
    expect(row.get(col1Name.name), 1);

    var map = {
      col1Name.fixedName: 1000,
    };
    db.updateMap(t3Name, map, "id=1");

    select = db.select(
        "select ${col1Name.bracketName} from ${t3Name.fixedName} where id=1");
    row = select.first;
    expect(row.get(col1Name.name), 1000);

    db.close();
  });

  test('test pk', () {
    var db = SqliteDb.memory();
    db.open(dbCreateFunction: createDbFunction);

    var primaryKey = db.getPrimaryKey(t1Name);
    expect('id', primaryKey);

    db.close();
  });

  test('test transaction', () {
    var db = SqliteDb.memory();
    db.open();

    db.transaction((_db) {
      _db.execute(createTable1);
      _db.execute(createTable2);
      insertTable1.forEach((sql) {
        _db.execute(sql);
      });
      insertTable2.forEach((sql) {
        _db.execute(sql);
      });
    });

    expect(db.hasTable(t1Name), true);

    db.close();
  });

  test('test transaction block - error printed is expected', () {
    var db = SqliteDb.memory();
    db.open();

    db.transaction((_db) {
      _db.execute(createTable1);
      _db.execute(createTable2);
      insertTable1.forEach((sql) {
        _db.execute(sql);
      });
      insertTable2.forEach((sql) {
        _db.execute(sql);
      });

      var sql = "INSERT INTO 'table 1' VALUES(1, 'Tscherms', 36.0);";
      _db.execute(sql);
    });

    expect(db.hasTable(t1Name), false);

    db.close();
  });

  test('test manual transaction', () {
    var db = SqliteDb.memory();
    db.open();

    Transaction tx = Transaction(db);
    tx.openTransaction();
    db.execute(createTable1);
    db.execute(createTable2);
    tx.closeTransaction();

    expect(db.hasTable(t1Name), true);

    db.close();
  });

  test('test manual transaction block', () {
    var db = SqliteDb.memory();
    db.open();

    Transaction tx = Transaction(db);
    tx.openTransaction();
    db.execute(createTable1);
    db.execute(createTable2);
    tx.rollback();

    expect(db.hasTable(t1Name), false);

    db.close();
  });

  test('test query object builder', () {
    var db = SqliteDb.memory();
    db.open(dbCreateFunction: createDbFunction);

    Table1ObjBuilder builder = Table1ObjBuilder();

    List<Table1Obj> objectsList =
        db.getQueryObjectsList(builder, whereString: "id=1");
    expect(objectsList.first.id, 1);
    expect(objectsList.first.name, 'Tscherms');
    expect(objectsList.first.temperature, 36.0);

    objectsList = db.getQueryObjectsList(builder);
    expect(objectsList.length, 3);
    expect(objectsList.last.id, 3);
    expect(objectsList.last.name, 'Bozen');
    expect(objectsList.last.temperature, 42.0);

    db.close();
  });

  test('test transaction with class', () {
    var db = SqliteDb.memory();
    db.open();
    Transaction(db).runInTransaction((_db) {
      _db.execute(createTable1);
      _db.execute(createTable2);
    });
    expect(db.hasTable(t1Name), true);

    db.close();
  });

  test('test datatypes', () {
    SqliteTypes.DOUBLE.value.forEach((v) {
      expect(SqliteTypes.isDouble(v), true);
    });
    SqliteTypes.DOUBLE_SW.value.forEach((v) {
      expect(SqliteTypes.isDouble(v), true);
    });
    SqliteTypes.INTEGER.value.forEach((v) {
      expect(SqliteTypes.isInteger(v), true);
    });
    SqliteTypes.TEXT.value.forEach((v) {
      expect(SqliteTypes.isString(v), true);
    });
    SqliteTypes.TEXT_SW.value.forEach((v) {
      expect(SqliteTypes.isString(v), true);
    });
    expect(SqliteTypes.isString("TEXT(48)"), true);
  });

  test('test tablename fix', () {
    var tableName = "3numericStart";
    var newTableName = DbsUtilities.fixWithQuotes(tableName);
    expect(newTableName, "'$tableName'");

    tableName = "with spaces   and    tabs";
    newTableName = DbsUtilities.fixWithQuotes(tableName);
    expect(newTableName, "'$tableName'");

    tableName = "with-dash";
    newTableName = DbsUtilities.fixWithQuotes(tableName);
    expect(newTableName, "'$tableName'");

    tableName = "'already escaped'";
    newTableName = DbsUtilities.fixWithQuotes(tableName);
    expect(newTableName, tableName);
  });

  // test('test custom function creation', () {
  //   final db = sqlite3.openInMemory();
  //   db.createFunction(
  //     functionName: 'dart_version',
  //     argumentCount: const AllowedArgumentCount(0),
  //     function: (args) {
  //       return Platform.version;
  //     },
  //     deterministic: true,
  //     directOnly: false,
  //   );
  //   var version = db.select('SELECT dart_version()');
  //   print(version.first);
  //   db.dispose();

  //   // var db = SqliteDb.memory();
  //   // db.open();
  //   //     var func = (args) {
  //   //   return Platform.version;
  //   // };
  //   // db.createFunction(
  //   //   functionName: 'dart_version',
  //   //   argumentCount: 0,
  //   //   function: func,
  //   //   deterministic: true,
  //   //   directOnly: false,
  //   // );
  //   // var version = db.select('SELECT dart_version()');
  //   // db.close();
  // });

  /// Old moor version test, not working on macos
  // test('test custom function creation', () {
  //   var db = SqliteDb.memory();
  //   db.open();
  //   var moorDb = db.getInternalDb();
  //   moorDb.createFunction(
  //       'dart_version', 0, Pointer.fromFunction(versionFunction),
  //       isDeterministic: true, directOnly: false);

  //   var version = db.select('SELECT dart_version()');
  //   print(version.first);
  //   db.close();
  // });
}

/// Old moor version test, not working on macos
// void versionFunction(Pointer<FunctionContext> ctx, int argCount,
//     Pointer<Pointer<SqliteValue>> args) {
//   String version = Platform.version;
//   ctx.resultNum(10);
// }

void createDbFunction(SqliteDb _db) {
  _db.execute(createTable1);
  _db.execute(createTable2);
  insertTable1.forEach((sql) {
    _db.execute(sql);
  });
  insertTable2.forEach((sql) {
    _db.execute(sql);
  });
}

void createUglyDbFunction(SqliteDb _db) {
  _db.execute(createTable3);
  insertTable3.forEach((sql) {
    _db.execute(sql);
  });
}
