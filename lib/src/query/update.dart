part of '_query.dart';

class UpdateQuery<R, TX> extends Query<R, TX>
    with _Where<R, TX>, _Returning<R, TX> {
  final List<String> _updateColumns = [];

  UpdateQuery({super.databaseDriver}) : super(name: 'UpdateQuery');

  void update(String table) {
    if (table.isEmpty) {
      throw UpdateQueryError(
          method: 'update', message: 'Table cannot be empty. table: $table');
    }
    this.table = table;
  }

  void setSingle(String column, dynamic value) {
    if (column.isEmpty) {
      throw UpdateQueryError(method: 'set', message: 'Column cannot be empty.');
    }
    _values.add(value);
    _updateColumns.add(replaceDelimiterMark('$column = $delimiter'));
  }

  void set(Map<String, dynamic> rows) {
    if (table == null) {
      throw UpdateQueryError(
          method: 'set',
          message:
              'Table is not set. Use `update()` method to set the table to update.');
    }
    for (final entry in rows.entries) {
      setSingle(entry.key, entry.value);
    }
  }

  @override
  String build() {
    if (table == null) {
      throw UpdateQueryError(
          method: 'build',
          message:
              'Table is not set. Use `update()` method to set the table to update.');
    }

    if (_updateColumns.isEmpty) {
      throw UpdateQueryError(
          method: 'build',
          message:
              'No columns to update have been set. Use `set()` method to set columns and values to update.');
    }

    final query = StringBuffer();

    query.write('UPDATE $table SET ');
    query.write(_updateColumns.join(', '));

    if (_condition.isNotEmpty) {
      query.write(' WHERE ${_getWhereString()}');
    }

    if (_returning.isNotEmpty) {
      query.write(' RETURNING ');
      query.write(_returning.join(', '));
    }

    return query.toString();
  }
}
