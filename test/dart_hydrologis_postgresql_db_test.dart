import 'package:dart_hydrologis_db/dart_hydrologis_db.dart';
import 'package:dart_hydrologis_utils/dart_hydrologis_utils.dart';
import 'package:test/test.dart';

void main() {
  late PostgresqlDb db;

  setUpAll(() {
    db = PostgresqlDb(
      "localhost",
      "test",
      port: 5432,
      user: "postgres",
      pwd: "postgres",
    );
    return db.open(populateFunction: createDbFunction);
  });

  tearDownAll(() {
    return db.close();
  });

  test('test creation', () async {
    expect(true, await db.hasTable(t1Name));
    expect(true, await db.hasTable(t2Name));
    expect(true, await db.hasTable(tNameWithSchema));

    var tableColumns = await db.getTableColumns(t1Name);
    expect(3, tableColumns.length);
    tableColumns = await db.getTableColumns(t2Name);
    expect(2, tableColumns.length);
    tableColumns = await db.getTableColumns(tNameWithSchema);
    expect(3, tableColumns.length);
  });

  test('test select', () async {
    var select =
        await db.select("select * from ${t1Name.fixedDoubleName} order by id");
    var row = select!.first;

    expect(row.get('id'), 1);
    expect(row.get('name'), 'Tscherms');
    expect(row.get('temperature'), 36.0);

    select = await db
        .select("select * from ${tNameWithSchema.fixedDoubleName} order by id");
    row = select!.first;

    expect(row.get('id'), 1);
    expect(row.get('name'), 'Tscherms');
    expect(row.get('temperature'), 36.0);
  });

  test('test insert', () async {
    var sql = "INSERT INTO ${t1Name.fixedDoubleName} VALUES(4, 'Egna', 27.0);";
    await db.execute(sql);

    var map = {
      'id': 5,
      'name': 'Trento',
      'temperature': 18.0,
    };
    await db.insertMap(t1Name, map);

    var select =
        await db.select("select * from ${t1Name.fixedDoubleName} where id=4");
    var row = select!.first;
    expect(row.get('id'), 4);
    expect(row.get('name'), 'Egna');
    expect(row.get('temperature'), 27.0);

    select =
        await db.select("select * from ${t1Name.fixedDoubleName} where id=5");
    row = select!.first;
    expect(row.get('id'), 5);
    expect(row.get('name'), 'Trento');
    expect(row.get('temperature'), 18.0);

    sql =
        "INSERT INTO ${tNameWithSchema.fixedDoubleName} VALUES(4, 'Egna', 27.0);";
    await db.execute(sql);

    map = {
      'id': 5,
      'name': 'Trento',
      'temperature': 18.0,
    };
    await db.insertMap(tNameWithSchema, map);

    select = await db
        .select("select * from ${tNameWithSchema.fixedDoubleName} where id=4");
    row = select!.first;
    expect(row.get('id'), 4);
    expect(row.get('name'), 'Egna');
    expect(row.get('temperature'), 27.0);

    select = await db
        .select("select * from ${tNameWithSchema.fixedDoubleName} where id=5");
    row = select!.first;
    expect(row.get('id'), 5);
    expect(row.get('name'), 'Trento');
    expect(row.get('temperature'), 18.0);
  });

  test('test insert with return', () async {
    var pk = await db.getPrimaryKey(t1Name);
    var sql = "INSERT INTO ${t1Name.fixedDoubleName} VALUES(44, 'Egna', 27.0);";
    var lastId = await db.execute(sql, getLastInsertId: true, primaryKey: pk);
    expect(lastId, 44);

    var map = {
      'id': 55,
      'name': 'Trento',
      'temperature': 18.0,
    };
    var lastId2 = await db.insertMap(t1Name, map);
    expect(lastId2, 55);

    var select =
        await db.select("select * from ${t1Name.fixedDoubleName} where id=44");
    var row = select!.first;
    expect(row.get('id'), 44);
    expect(row.get('name'), 'Egna');
    expect(row.get('temperature'), 27.0);

    select =
        await db.select("select * from ${t1Name.fixedDoubleName} where id=55");
    row = select!.first;
    expect(row.get('id'), 55);
    expect(row.get('name'), 'Trento');
    expect(row.get('temperature'), 18.0);
  });

  test('test update', () async {
    var sql =
        "UPDATE  ${t1Name.fixedDoubleName} set name='Egna', temperature=27.0 where id=3;";
    await db.execute(sql);

    var select =
        await db.select("select * from ${t1Name.fixedDoubleName} where id=3");
    var row = select!.first;
    expect(row.get('id'), 3);
    expect(row.get('name'), 'Egna');
    expect(row.get('temperature'), 27.0);

    var map = {
      'name': 'Trento',
      'temperature': 18.0,
    };
    await db.updateMap(t1Name, map, "id=3");

    select =
        await db.select("select * from ${t1Name.fixedDoubleName} where id=3");
    row = select!.first;
    expect(row.get('id'), 3);
    expect(row.get('name'), 'Trento');
    expect(row.get('temperature'), 18.0);

    sql =
        "UPDATE  ${tNameWithSchema.fixedDoubleName} set name='Egna', temperature=27.0 where id=3;";
    await db.execute(sql);

    select = await db
        .select("select * from ${tNameWithSchema.fixedDoubleName} where id=3");
    row = select!.first;
    expect(row.get('id'), 3);
    expect(row.get('name'), 'Egna');
    expect(row.get('temperature'), 27.0);

    map = {
      'name': 'Trento',
      'temperature': 18.0,
    };
    await db.updateMap(tNameWithSchema, map, "id=3");

    select = await db
        .select("select * from ${tNameWithSchema.fixedDoubleName} where id=3");
    row = select!.first;
    expect(row.get('id'), 3);
    expect(row.get('name'), 'Trento');
    expect(row.get('temperature'), 18.0);
  });

  // test('test ugly names', () async {
  //   var db = await createDb(createUglyDbFunction);

  //   expect(true, await db.hasTable(t3Name));

  //   var tableColumns = await db.getTableColumns(t3Name);
  //   expect(2, tableColumns.length);

  //   var select = await db.select(
  //       "select ${col1Name.bracketName} from ${t3Name.fixedName} where id=1");
  //   var row = select.first;
  //   expect(row.get(col1Name.name), 1);

  //   var map = {
  //     col1Name.fixedName: 1000,
  //   };
  //   await db.updateMap(t3Name, map, "id=1");

  //   select = await db.select(
  //       "select ${col1Name.bracketName} from ${t3Name.fixedName} where id=1");
  //   row = select.first;
  //   expect(row.get(col1Name.name), 1000);

  //
  // });

  test('test pk', () async {
    var primaryKey = await db.getPrimaryKey(t1Name);
    expect('id', primaryKey);

    primaryKey = await db.getPrimaryKey(tNameWithSchema);
    expect('id', primaryKey);
  });

  test('test names with schema', () {
    var sqlName = TableName("myschema.mytable");

    expect(sqlName.getSchema(), "myschema");

    sqlName = TableName("mytable");

    expect(sqlName.getSchema(), "public");
  });

  test('test transaction', () async {
    await db.transaction((_db) async {
      await _db.execute(dropTable3);
      await _db.execute(createTable3);
      for (var sql in insertTable3) {
        await _db.execute(sql);
      }
    });

    expect(await db.hasTable(t3Name), true);
    // await db.execute(dropTable3);

    // try {
    //   // with error
    //   await db.transaction((_db) async {
    //     await _db.execute(dropTable3);
    //     await _db.execute(createTable3);
    //     for (var sql in insertTable3) {
    //       await _db.execute(sql);
    //     }

    //     var sql = "INSERT INTO ${t3Name.fixedDoubleName} VALUES(1, 1);";
    //     await _db.execute(sql);
    //   });
    // } on Exception {
    //   print("bau");
    // }
    // expect(await db.hasTable(t3Name), false);

    //manual transaction
    // TransactionAsync tx = TransactionAsync(db);
    // await tx.openTransaction();
    // await db.execute(dropTable3);
    // await db.execute(createTable3);
    // await tx.closeTransaction();

    // expect(await db.hasTable(t3Name), true);
  });

  // test('test manual transaction block', () async {
  //   TransactionAsync tx = TransactionAsync(db);
  //   await tx.openTransaction();
  //   await db.execute(dropTable3);
  //   await db.execute(createTable3);
  //   await tx.rollback();

  //   expect(await db.hasTable(t3Name), false);
  // });

  test('test query object builder', () async {
    Table1ObjBuilder builder = Table1ObjBuilder();

    List<Table1Obj> objectsList =
        await db.getQueryObjectsList(builder, whereString: "id=1 order by id");
    expect(objectsList.length, 1);
    expect(objectsList.first.id, 1);
    expect(objectsList.first.name, 'Tscherms');
    expect(objectsList.first.temperature, 36.0);

    objectsList = await db.getQueryObjectsList(builder);
    for (var obj in objectsList) {
      if (obj.id == 2) {
        expect(obj.name, 'Meran');
        expect(obj.temperature, 34.0);
      }
    }
  });

  // test('test transaction with class', () async {
  //   await TransactionAsync(db).runInTransaction((_db) async {
  //     await _db.execute(createTable1);
  //     await _db.execute(createTable2);
  //   });
  //   expect(await db.hasTable(t1Name), true);
  // });
}

Future<void> createDbFunction(ADbAsync _db) async {
  try {
    await _db.execute(createSchema);
    await _db.execute(dropTable1);
    await _db.execute(dropTable2);
    await _db.execute(dropTableWithSchema);
    await _db.execute(createTable1);
    await _db.execute(createTable2);
    await _db.execute(createTableWithSchema);
    for (var sql in insertTable1) {
      await _db.execute(sql);
    }
    for (var sql in insertTable2) {
      await _db.execute(sql);
    }
    for (var sql in insertTableWithSchema) {
      await _db.execute(sql);
    }
  } on Exception catch (e, s) {
    SLogger().e("Error on db creation.", e, s);
  }
}

Future<void> createUglyDbFunction(ADbAsync _db) async {
  await _db.execute(dropTable3);
  await _db.execute(createTable3);
  for (var sql in insertTable3) {
    await _db.execute(sql);
  }
}

var t1Name = TableName("table 1");
var t2Name = TableName("table2");
var t3Name = TableName("10table with,nasty");
var col1Name = SqlName("10col with,nasty");
var tNameWithSchema = TableName("testschema.table 1");

var createSchema = '''
CREATE SCHEMA IF NOT EXISTS ${tNameWithSchema.getSchema()};
''';
var dropTable1 = '''
drop table if exists ${t1Name.fixedDoubleName} cascade;
''';

var createTable1 = '''
CREATE TABLE ${t1Name.fixedDoubleName} (
  id SERIAL PRIMARY KEY, 
  name TEXT,  
  temperature REAL
);
''';

var insertTable1 = [
  "INSERT INTO ${t1Name.fixedDoubleName} VALUES(1, 'Tscherms', 36.0);", //
  "INSERT INTO ${t1Name.fixedDoubleName} VALUES(2, 'Meran', 34.0);", //
  "INSERT INTO ${t1Name.fixedDoubleName} VALUES(3, 'Bozen', 42.0);", //
];

var dropTable2 = '''
  drop table if exists ${t2Name.fixedDoubleName} cascade;
  ''';
var createTable2 = '''
  CREATE TABLE ${t2Name.fixedDoubleName} (  
    id SERIAL PRIMARY KEY, 
    table1id INTEGER,  
    FOREIGN KEY (table1id) REFERENCES ${t1Name.fixedDoubleName} (id)
  );
  ''';
var insertTable2 = [
  "INSERT INTO ${t2Name.fixedDoubleName} VALUES(1, 1);", //
  "INSERT INTO ${t2Name.fixedDoubleName} VALUES(2, 2);", //
  "INSERT INTO ${t2Name.fixedDoubleName} VALUES(3, 3);", //
];

var dropTable3 = '''
  drop table if exists ${t3Name.fixedDoubleName} cascade;
  ''';
var createTable3 = '''
  CREATE TABLE ${t3Name.fixedDoubleName} (  
    id SERIAL PRIMARY KEY, 
    ${col1Name.fixedDoubleName} INTEGER
  );
  ''';
var insertTable3 = [
  "INSERT INTO ${t3Name.fixedDoubleName} VALUES(1, 1);", //
  "INSERT INTO ${t3Name.fixedDoubleName} VALUES(2, 2);", //
  "INSERT INTO ${t3Name.fixedDoubleName} VALUES(3, 3);", //
];

var createTableWithSchema = '''
CREATE TABLE ${tNameWithSchema.fixedDoubleName} (
  id SERIAL PRIMARY KEY, 
  name TEXT,  
  temperature REAL
);
''';

var insertTableWithSchema = [
  "INSERT INTO ${tNameWithSchema.fixedDoubleName} VALUES(1, 'Tscherms', 36.0);", //
  "INSERT INTO ${tNameWithSchema.fixedDoubleName} VALUES(2, 'Meran', 34.0);", //
  "INSERT INTO ${tNameWithSchema.fixedDoubleName} VALUES(3, 'Bozen', 42.0);", //
];

var dropTableWithSchema = '''
  drop table if exists ${tNameWithSchema.fixedDoubleName} cascade;
  ''';

class Table1Obj {
  late int id;
  late String name;
  late double temperature;
}

class Table1ObjBuilder implements QueryObjectBuilder<Table1Obj> {
  @override
  Table1Obj fromRow(QueryResultRow map) {
    Table1Obj obj = Table1Obj()
      ..id = map.get('id')
      ..name = map.get('name')
      ..temperature = map.get('temperature');
    return obj;
  }

  @override
  String querySql() {
    return "select id, name, temperature from ${t1Name.fixedDoubleName}";
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
