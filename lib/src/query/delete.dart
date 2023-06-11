part of '_query.dart';

class DeleteQuery<R, TX> extends Query<R, TX>
    with _Where<R, TX>, _Returning<R, TX> {
  String? _table;
  final List<String> _orderBy = [];
  int? _limit;
  bool _cascade = false;

  DeleteQuery({super.databaseDriver}) : super(name: 'DeleteQuery');

  void deleteFrom(String table) {
    _table = table;
  }

  void limit(int count) {
    _limit = count;
  }

  void orderBy(String column, {Order order = Order.asc}) {
    _orderBy.add('$column ${order.toQueryString}');
  }

  void cascadeDelete() {
    _cascade = true;
  }

  @override
  String build() {
    if (_table == null) {
      throw const DeleteQueryError(
          method: 'build',
          message:
              'Table not specified. Use `deleteFrom()` method to specify the table.');
    }

    final query = StringBuffer();

    query.write('DELETE FROM $_table');

    if (_condition.isNotEmpty) {
      query.write(' WHERE ${_getWhereString()}');
    }

    if (_orderBy.isNotEmpty) {
      query.write(' ORDER BY ${_orderBy.join(', ')}');
    }

    if (_limit != null) {
      query.write(' LIMIT $_limit');
    }

    if (_cascade) {
      query.write(' CASCADE');
    }

    if (_returning.isNotEmpty) {
      query.write(' RETURNING ${_returning.join(', ')}');
    }

    return query.toString();
  }
}
