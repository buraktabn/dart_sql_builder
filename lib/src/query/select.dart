part of '_query.dart';

class SelectQuery<R, TX> extends Query<R, TX> with _Where<R, TX> {
  SelectQuery({super.databaseDriver}) : super(name: 'SelectQuery');

  List<String> _columns = [];
  final List<String> _joins = [];
  List<String> _groupBy = [];
  String _having = '';
  List<String> _orderBy = [];
  List<Order> _orderByConditions = [];
  int _limit = -1;
  int _offset = -1;

  void select(List<String> columns) {
    if (columns.isEmpty) {
      throw SelectQueryError(method: 'select', message: 'No column provided');
    }
    _columns = columns;
  }

  void selectAll() {
    _columns = ['*'];
  }

  void selectDistinct(List<String> columns) {
    if (columns.isEmpty) {
      throw SelectQueryError(method: 'select', message: 'No column provided');
    }
    _columns = ['DISTINCT ${columns.join(',')}'];
  }

  void from(String table) {
    this.table = table;
  }

  void join(String table, String condition,
      [JoinType joinType = JoinType.inner]) {
    final joinTypeString = joinType.toQueryString;
    final joinClause = '$joinTypeString JOIN $table ON $condition';
    _joins.add(joinClause);
  }

  void groupBy(List<String> columns) {
    if (columns.isEmpty) {
      throw SelectQueryError(method: 'groupBy', message: 'No column provided');
    }
    _groupBy = columns;
  }

  void having(String condition, [List<dynamic>? values]) {
    _having = replaceDelimiterMark(condition);
    _values.addAll(values ?? []);
  }

  void orderBy(List<String> columns, [List<Order>? ascendings]) {
    if (columns.isEmpty) {
      throw SelectQueryError(method: 'orderBy', message: 'No column provided');
    }
    _orderBy = columns;
    _orderByConditions = ascendings ?? List.filled(columns.length, Order.asc);
  }

  void limit(int count) {
    _limit = count;
  }

  void offset(int count) {
    _offset = count;
  }

  @override
  String build() {
    final query = StringBuffer();

    query.write('SELECT ${_columns.join(',')}');
    query.write(' FROM $table');

    if (_joins.isNotEmpty) {
      query.write(' ${_joins.join(' ')}');
    }

    if (_condition.isNotEmpty) {
      query.write(' WHERE ${_getWhereString()}');
    }

    if (_groupBy.isNotEmpty) {
      query.write(' GROUP BY ${_groupBy.join(',')}');
    }

    if (_having.isNotEmpty) {
      query.write(' HAVING $_having');
    }

    if (_orderBy.isNotEmpty) {
      final orderByClauses = <String>[];
      for (var i = 0; i < _orderBy.length; i++) {
        final column = _orderBy[i];
        final ascending = _orderByConditions[i].toQueryString;
        orderByClauses.add('$column $ascending');
      }
      query.write(' ORDER BY ${orderByClauses.join(', ')}');
    }

    if (_limit != -1) {
      query.write(' LIMIT $_limit');
    }

    if (_offset != -1) {
      query.write(' OFFSET $_offset');
    }

    return query.toString();
  }
}
