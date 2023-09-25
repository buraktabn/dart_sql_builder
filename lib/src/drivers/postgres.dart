// ignore_for_file: invalid_use_of_protected_member

import 'package:collection/collection.dart';
import 'package:dart_sql_builder/src/drivers/utils.dart';
import 'package:postgres/postgres.dart';

import '../query/_query.dart';
import '_driver.dart';

typedef QueryMappedResult = List<Map<String, Map<String, dynamic>>>;
typedef PostgresTx = PostgreSQLExecutionContext;

typedef QueryPostgres = Query<PostgreSQLResult, PostgresTx>;
typedef SelectQueryPostgres = SelectQuery<PostgreSQLResult, PostgresTx>;
typedef InsertQueryPostgres = InsertQuery<PostgreSQLResult, PostgresTx>;
typedef UpdateQueryPostgres = UpdateQuery<PostgreSQLResult, PostgresTx>;
typedef DeleteQueryPostgres = DeleteQuery<PostgreSQLResult, PostgresTx>;

class PostgresSQL extends DatabaseDriver<PostgreSQLResult, PostgresTx> {
  final PostgreSQLConnection connection;

  PostgresSQL(this.connection);

  factory PostgresSQL.connectionString(String connectionString) {
    return PostgresSQL(parsePsqlConnectionString(connectionString));
  }

  SelectQueryPostgres get select => SelectQuery(databaseDriver: this);
  InsertQueryPostgres get insert => InsertQuery(databaseDriver: this);
  UpdateQueryPostgres get update => UpdateQuery(databaseDriver: this);
  DeleteQueryPostgres get delete => DeleteQuery(databaseDriver: this);

  Future<void> open() async {
    await connection.open();
  }

  Future<void> close() async {
    await connection.close();
  }

  @override
  Future<PostgreSQLResult> query(Query q, {PostgresTx? tx}) {
    final query = q.build();
    return (tx ?? connection)
        .query(query, substitutionValues: _buildSubstitutionValues(q.values));
  }

  @override
  Future<QueryMappedResult> queryMapped(Query q, {PostgresTx? tx}) {
    final query = q.build();
    return (tx ?? connection).mappedResultsQuery(query,
        substitutionValues: _buildSubstitutionValues(q.values));
  }

  @override
  Future<int> execute(Query q, {PostgresTx? tx}) {
    final query = q.build();
    return (tx ?? connection)
        .execute(query, substitutionValues: _buildSubstitutionValues(q.values));
  }

  Map<String, dynamic> _buildSubstitutionValues(List values) {
    return Map.fromEntries(
        values.mapIndexed((i, e) => MapEntry('${i + 1}', e)));
  }

  Future<PostgreSQLResult> rawQuery(String query,
      {Map<String, dynamic> substitutionValues = const {}, PostgresTx? tx}) {
    return (tx ?? connection)
        .query(query, substitutionValues: substitutionValues);
  }

  Future<QueryMappedResult> rawQueryMapped(String query,
      {Map<String, dynamic> substitutionValues = const {}, PostgresTx? tx}) {
    return (tx ?? connection)
        .mappedResultsQuery(query, substitutionValues: substitutionValues);
  }

  Future<int> rawExecute(String query,
      {Map<String, dynamic> substitutionValues = const {}, PostgresTx? tx}) {
    return (tx ?? connection)
        .execute(query, substitutionValues: substitutionValues);
  }

  Future tx(Future Function(PostgresTx connection) queryBlock) async {
    return connection.transaction(queryBlock);
  }
}
