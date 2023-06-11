part of '_query.dart';

enum ConflictAction with QueryString {
  doNothing,
  doUpdate;

  @override
  String get toQueryString => switch (this) {
        (ConflictAction.doNothing) => "DO NOTHING",
        (ConflictAction.doUpdate) => "DO UPDATE",
      };
}

class InsertQuery<T, TX> extends Query<T, TX> with _Returning<T, TX> {
  String? _table;
  int _insertCnt = 0;
  final List<String> _columns = [];
  final List<String> _conflictColumns = [];
  ConflictAction? _conflictAction;
  Map<String, dynamic>? _updateValues;

  InsertQuery({super.databaseDriver}) : super(name: 'InsertQuery');

  @override
  String build() {
    if (_table == null) {
      throw const InsertQueryError(
          method: 'build',
          message:
              'table is not set. use `into()` to set table to insert data into.');
    }
    assert(_columns.length == _values.length);
    final colLen = _columns.length ~/ _insertCnt;
    final query = StringBuffer();

    query.write('INSERT INTO $_table');
    query.write(' (${_columns.sublist(0, colLen).join(', ')})');
    query.write(' VALUES');

    for (int i = 0; i < _insertCnt; i++) {
      query.write(
          ' (${valuesToDelimiter(_values.sublist(i * colLen, i * colLen + colLen)).join(', ')})');
      if (i != _insertCnt - 1) {
        query.write(',');
      }
    }

    if (_conflictAction != null) {
      query.write(
          ' ON CONFLICT (${_conflictColumns.join(', ')}) ${_conflictAction!.toQueryString}');

      if (_conflictAction == ConflictAction.doUpdate) {
        assert(_updateValues != null);
        query.write(' SET ');

        final updateStatements = _updateValues!.entries.map((entry) {
          final column = entry.key;
          final value = entry.value;
          final placeholder = replaceDelimiterMark('?');
          _values.add(value);
          return '$column = $placeholder';
        }).join(', ');

        query.write(updateStatements);
      }
    }

    if (_returning.isNotEmpty) {
      query.write(' RETURNING ');
      query.write(_returning.join(', '));
    }

    return query.toString();
  }

  void into(String tableName) {
    _table = tableName;
  }

  void insert(Map<String, dynamic> rows) {
    for (final entry in rows.entries) {
      _columns.add(entry.key);
      _values.add(entry.value);
    }
    _insertCnt++;
  }

  void insertAll(List<Map<String, dynamic>> allRows) {
    for (var rows in allRows) {
      insert(rows);
    }
  }

  void onConflict(ConflictAction conflictAction, List<String> conflictColumns,
      {Map<String, dynamic>? updateValues}) {
    if (conflictColumns.isEmpty) {
      throw const InsertQueryError(
          method: 'onConflict', message: 'conflictColumns cannot be empty');
    }
    if (conflictAction == ConflictAction.doUpdate &&
        (updateValues == null || updateValues.isEmpty)) {
      throw const InsertQueryError(
          method: 'onConflict', message: 'updateValues is not set');
    }
    _conflictAction = conflictAction;
    _updateValues = updateValues;
    _conflictColumns.addAll(conflictColumns);
  }

  void onConflictDoNothing(List<String> conflictColumns) {
    onConflict(ConflictAction.doNothing, conflictColumns);
  }

  void onConflictDoUpdate(
      List<String> conflictColumns, Map<String, dynamic> updateValues) {
    onConflict(ConflictAction.doUpdate, conflictColumns,
        updateValues: updateValues);
  }
}
