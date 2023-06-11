import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dart_sql_builder/dart_sql_builder.dart';

import '../test/test_utils.dart';

class InsertQueryBenchmark extends BenchmarkBase {
  InsertQueryBenchmark() : super("InsertQuery");

  static void main() {
    InsertQueryBenchmark().report();
  }

  @override
  void run() {
    final query = InsertQuery()
      ..into('users')
      ..insert({'name': 'John Doe', 'age': 30})
      ..onConflictDoNothing(['age']);
    final _ = query.build();
  }

  @override
  void setup() {}

  @override
  void teardown() {}
}

class InsertQueryPostgresBenchmark extends AsyncBenchmarkBase {
  InsertQueryPostgresBenchmark() : super("InsertQueryPostgres");

  static void main() {
    InsertQueryPostgresBenchmark().report();
  }

  final postgreSQL = PostgresSQL.connectionString(psqlConnectionString);

  @override
  Future<void> run() async {
    final q = InsertQuery()
      ..into('users')
      ..insert({'name': 'John Doe', 'age': 30})
      ..onConflictDoNothing(['age']);
    await postgreSQL.execute(q);
  }

  @override
  Future<void> setup() async {
    await postgreSQL.open();
    await createUsers(postgreSQL);
  }

  @override
  Future<void> teardown() async {
    await dropUsers(postgreSQL);
    await postgreSQL.close();
  }
}

void main() {
  InsertQueryBenchmark.main();
  InsertQueryPostgresBenchmark.main();
}
