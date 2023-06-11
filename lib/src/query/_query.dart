import 'package:meta/meta.dart';

import '../drivers/_driver.dart';

part 'select.dart';

part 'insert.dart';

part 'update.dart';

part 'delete.dart';

const _defaultDelimiter = '?';

sealed class Query<R, TX> {
  final String name;
  final String delimiter;
  final DatabaseDriver<R, TX>? databaseDriver;

  Query(
      {required this.name,
      this.databaseDriver,
      this.delimiter = _defaultDelimiter});

  final List<dynamic> _values = [];
  int _conditionIndex = 1;

  @protected
  List<dynamic> get values => _values;

  String build();

  String replaceDelimiterMark(String query) {
    return query.replaceAllMapped(delimiter, (match) {
      final replacement = '@${_conditionIndex++}';
      return replacement;
    });
  }

  List<String> valuesToDelimiter(List<dynamic> values) {
    return values.map((e) => '@${_conditionIndex++}').toList();
  }

  Future<int> execute({TX? tx}) {
    if (databaseDriver == null) {
      _notSupportedError('execute');
    }
    return databaseDriver!.execute(this, tx: tx);
  }

  Future<R> query({TX? tx}) {
    if (databaseDriver == null) {
      _notSupportedError('query');
    }
    return databaseDriver!.query(this, tx: tx);
  }

  Future queryMapped({TX? tx}) {
    if (databaseDriver == null) {
      _notSupportedError('queryMapped');
    }
    return databaseDriver!.queryMapped(this, tx: tx);
  }

  Never _notSupportedError(String method) {
    const message = "Driver not set. Database queries are disabled.";
    throw switch (this) {
      (SelectQuery _) => SelectQueryError(method: method, message: message),
      (InsertQuery _) => InsertQueryError(method: method, message: message),
      (UpdateQuery _) => UpdateQueryError(method: method, message: message),
      (DeleteQuery _) => DeleteQueryError(method: method, message: message),
      // ignore: unreachable_switch_case
      (final q) => QueryError(type: q.name, method: method, message: message),
    };
  }
}

mixin QueryString on Enum {
  String get toQueryString => name.toUpperCase();
}

mixin _Where<R, TX> on Query<R, TX> {
  final List<String> _condition = [];
  final List<Operator> _operators = [];

  void where(String condition, [List<dynamic>? values]) {
    _condition.add(replaceDelimiterMark(condition));
    _values.addAll(values ?? []);
  }

  void and() {
    _operators.add(Operator.and);
  }

  void or() {
    _operators.add(Operator.or);
  }

  String _getWhereString() {
    final joinedList = <String>[];
    for (var i = 0; i < _condition.length || i < _operators.length; i++) {
      if (i < _condition.length) {
        joinedList.add(_condition[i]);
      }
      if (i < _operators.length) {
        joinedList.add(_operators[i].toQueryString);
      }
    }
    return joinedList.join(' ');
  }
}

mixin _Returning<R, TX> on Query<R, TX> {
  final List<String> _returning = [];

  void returning(List<String> columns) {
    if (columns.isEmpty) {
      throw QueryError(
          type: name,
          method: 'returning',
          message: 'returning columns cannot be empty');
    }
    _returning.addAll(columns);
  }

  void returnAll() {
    _returning.add('*');
  }
}

enum Order with QueryString {
  asc,
  desc;

  bool get isAsc => this == Order.asc;

  bool get isDsc => this == Order.desc;
}

enum JoinType with QueryString { inner, left, right, full }

enum Operator with QueryString { and, or, not }

class QueryError implements Exception {
  final String type;
  final String method;
  final String message;

  const QueryError(
      {required this.type, required this.method, required this.message});

  @override
  String toString() {
    return "$type ERROR. method: $method, message: $message";
  }
}

class SelectQueryError extends QueryError {
  const SelectQueryError({required super.method, required super.message})
      : super(type: 'SelectQuery');
}

class InsertQueryError extends QueryError {
  const InsertQueryError({required super.method, required super.message})
      : super(type: 'InsertQuery');
}

class UpdateQueryError extends QueryError {
  const UpdateQueryError({required super.method, required super.message})
      : super(type: 'UpdateQuery');
}

class DeleteQueryError extends QueryError {
  const DeleteQueryError({required super.method, required super.message})
      : super(type: 'DeleteQuery');
}
