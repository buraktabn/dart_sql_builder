import 'package:postgres/postgres.dart';

PostgreSQLConnection parsePsqlConnectionString(String connectionString) {
  final Uri uri = Uri.parse(connectionString);

  final String host = uri.host;
  final int port = uri.port;
  final String databaseName =
      uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres';
  final String? username = uri.userInfo.isNotEmpty
      ? Uri.decodeComponent(uri.userInfo).split(':')[0]
      : null;
  final String? password = uri.userInfo.isNotEmpty
      ? Uri.decodeComponent(uri.userInfo).split(':')[1]
      : null;

  final Map<String, String> queryParameters = uri.queryParameters;
  final int timeoutInSeconds =
      int.tryParse(queryParameters['timeoutInSeconds'] ?? '30') ?? 30;
  final int queryTimeoutInSeconds =
      int.tryParse(queryParameters['queryTimeoutInSeconds'] ?? '30') ?? 30;
  final String timeZone = queryParameters['timeZone'] ?? 'UTC';
  final bool useSSL = queryParameters['ssl']?.toLowerCase() == 'true';
  final bool isUnixSocket =
      queryParameters['unixSocket']?.toLowerCase() == 'true';
  final bool allowClearTextPassword =
      queryParameters['allowClearTextPassword']?.toLowerCase() == 'true';
  final ReplicationMode replicationMode =
      parseReplicationMode(queryParameters['replicationMode']);

  return PostgreSQLConnection(
    host,
    port,
    databaseName,
    username: username,
    password: password,
    timeoutInSeconds: timeoutInSeconds,
    queryTimeoutInSeconds: queryTimeoutInSeconds,
    timeZone: timeZone,
    useSSL: useSSL,
    isUnixSocket: isUnixSocket,
    allowClearTextPassword: allowClearTextPassword,
    replicationMode: replicationMode,
  );
}

ReplicationMode parseReplicationMode(String? mode) {
  if (mode == 'physical') {
    return ReplicationMode.physical;
  } else if (mode == 'logical') {
    return ReplicationMode.logical;
  } else {
    return ReplicationMode.none;
  }
}
