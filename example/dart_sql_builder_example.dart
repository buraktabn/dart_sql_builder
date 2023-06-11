// FOR SELECTION
import 'package:dart_sql_builder/dart_sql_builder.dart';

const psqlConnectionString =
    'postgresql://postgres:123456@localhost:5432/postgres';

Future<void> selectExample() async {
  final db = PostgresSQL.connectionString(psqlConnectionString);

  await db.open();

  final query = db.select..from('your_table');
  query.where('column_name = ?', ['value']);

  final result = await query.queryMapped();
  print(result);

  await db.close();
}

// FOR INSERTION
Future<void> insertExample() async {
  final db = PostgresSQL.connectionString(psqlConnectionString);

  await db.open();

  final query = db.insert;
  query.into('your_table');
  query.insert({
    'column1': 'value1',
    'column2': 'value2',
    'column3': 'value3',
  });

  final resultInfo = await query.queryMapped();
  print(resultInfo);

  await db.close();
}

// FOR UPDATION
Future<void> updateExample() async {
  final db = PostgresSQL.connectionString(psqlConnectionString);

  await db.open();

  final query = db.update;
  query.update('your_table');
  query.set({
    'column1': 'value1',
    'column2': 'value2',
    'column3': 'value3',
  });

  query.where('id = 1');
  await query.execute();

  await db.close();
}

// FOR DELETION
Future<void> deleteExample() async {
  final db = PostgresSQL.connectionString(psqlConnectionString);

  await db.open();

  final query = db.delete;
  query.deleteFrom('your_table');
  query.where('id = 1');
  await query.execute();

  await db.close();
}

// FOR TRANSACTIONS
Future<void> transactionExample() async {
  final db = PostgresSQL.connectionString(psqlConnectionString);

  await db.open();

  await db.tx((connection) async {
    final selectQuery = db.select..from('your_table');
    final updateQuery = db.update..update('your_table');

    // Run your queries with `connection` provided by the block parameter.
    await selectQuery.query(tx: connection);
    await updateQuery.execute(tx: connection);
  });

  await db.close();
}

void main() async {
  print("\n---Select Example---");
  await selectExample();

  print("\n---Insert Example---");
  await insertExample();

  print("\n---Update Example---");
  await updateExample();

  print("\n---Delete Example---");
  await deleteExample();

  print("\n---Transaction Example---");
  await transactionExample();
}