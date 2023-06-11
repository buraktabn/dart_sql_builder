import 'package:dart_sql_builder/src/query/_query.dart';

abstract class DatabaseDriver<R, TX> {
  Future<R> query(Query q, {TX? tx});

  Future queryMapped(Query q, {TX? tx});

  Future<int> execute(Query q, {TX? tx});
}
