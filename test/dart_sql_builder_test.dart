// ignore_for_file: invalid_use_of_protected_member

import 'package:collection/collection.dart';
import 'package:dart_sql_builder/dart_sql_builder.dart';
import 'package:dart_sql_builder/src/drivers/utils.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('PostgreSQL connection string', () {
    test('Parsing connection string with all parameters', () {
      final connectionString = 'postgresql://user:password@localhost:5432/mydb'
          '?timeoutInSeconds=60'
          '&queryTimeoutInSeconds=120'
          '&timeZone=America/New_York'
          '&ssl=true'
          '&unixSocket=false'
          '&allowClearTextPassword=true'
          '&replicationMode=logical';

      final connection = parsePsqlConnectionString(connectionString);

      expect(connection.host, 'localhost');
      expect(connection.port, 5432);
      expect(connection.databaseName, 'mydb');
      expect(connection.username, 'user');
      expect(connection.password, 'password');
      expect(connection.timeoutInSeconds, 60);
      expect(connection.queryTimeoutInSeconds, 120);
      expect(connection.timeZone, 'America/New_York');
      expect(connection.useSSL, isTrue);
      expect(connection.isUnixSocket, isFalse);
      expect(connection.allowClearTextPassword, isTrue);
      expect(connection.replicationMode, ReplicationMode.logical);
    });

    test('Parsing connection string with only required parameters', () {
      final connectionString = 'postgresql://localhost:5432/mydb';

      final connection = parsePsqlConnectionString(connectionString);

      expect(connection.host, 'localhost');
      expect(connection.port, 5432);
      expect(connection.databaseName, 'mydb');
      expect(connection.username, isNull);
      expect(connection.password, isNull);
      expect(connection.timeoutInSeconds, 30);
      expect(connection.queryTimeoutInSeconds, 30);
      expect(connection.timeZone, 'UTC');
      expect(connection.useSSL, isFalse);
      expect(connection.isUnixSocket, isFalse);
      expect(connection.allowClearTextPassword, isFalse);
      expect(connection.replicationMode, ReplicationMode.none);
    });
  });

  group('Select query', () {
    late SelectQuery query;

    setUp(() {
      query = SelectQuery();
    });

    test('Select all columns', () {
      query
        ..selectAll()
        ..from('users');
      expect(query.build(), 'SELECT * FROM users');
    });

    test('Select specific columns', () {
      query
        ..select(['name', 'age'])
        ..from('users');

      final sql = query.build();

      expect(sql, 'SELECT name,age FROM users');
    });

    test('Select with empty columns', () {
      expect(
          () => query
            ..select([])
            ..from('users'),
          throwsA(TypeMatcher<SelectQueryError>()));
    });

    test('Select distinct', () {
      query
        ..selectDistinct(['name', 'email'])
        ..from('users');
      expect(query.build(), 'SELECT DISTINCT name,email FROM users');
    });

    test('Select distinct with empty columns', () {
      expect(
          () => query
            ..selectDistinct([])
            ..from('users'),
          throwsA(TypeMatcher<SelectQueryError>()));
    });

    test('SELECT query with WHERE condition', () {
      query
        ..select(['name', 'age'])
        ..from('users')
        ..where('age > ?', [18]);

      final sql = query.build();

      expect(sql, 'SELECT name,age FROM users WHERE age > @1');
    });

    test('Multiple WHERE conditions with AND operator', () {
      query
        ..selectAll()
        ..from('users')
        ..where('age > ?', [21])
        ..and()
        ..where('country = ?', ['USA']);
      expect(
          query.build(), 'SELECT * FROM users WHERE age > @1 AND country = @2');
    });

    test('Multiple Where conditions with OR operator', () {
      query
        ..selectAll()
        ..from('users')
        ..where('age < ?', [18])
        ..or()
        ..where('age > ?', [60]);
      expect(query.build(), 'SELECT * FROM users WHERE age < @1 OR age > @2');
    });

    test('Join', () {
      query
        ..selectAll()
        ..from('users')
        ..join('orders', 'users.id = orders.user_id');
      expect(query.build(),
          'SELECT * FROM users INNER JOIN orders ON users.id = orders.user_id');
    });

    test('Join multiple', () {
      query
        ..select(['u.name', 'o.*', 'c.*'])
        ..from('users u')
        ..join('orders o', 'u.id = o.user_id')
        ..join('cart c', 'u.id = c.card_id', JoinType.right);
      expect(query.build(),
          'SELECT u.name,o.*,c.* FROM users u INNER JOIN orders o ON u.id = o.user_id RIGHT JOIN cart c ON u.id = c.card_id');
    });

    test('Group By', () {
      query
        ..select(['country', 'COUNT(*)'])
        ..from('users')
        ..groupBy(['country']);
      expect(
          query.build(), 'SELECT country,COUNT(*) FROM users GROUP BY country');
    });

    test('Group By with empty columns', () {
      expect(
          () => query
            ..select(['country', 'COUNT(*)'])
            ..from('users')
            ..groupBy([]),
          throwsA(TypeMatcher<SelectQueryError>()));
    });

    test('Having', () {
      query
        ..select(['country', 'COUNT(*)'])
        ..from('users')
        ..groupBy(['country'])
        ..having('COUNT(*) > ?', [10]);
      expect(query.build(),
          'SELECT country,COUNT(*) FROM users GROUP BY country HAVING COUNT(*) > @1');
    });

    test('Order By', () {
      query
        ..selectAll()
        ..from('users')
        ..orderBy(['name', 'age'], [Order.asc, Order.desc]);
      expect(query.build(), 'SELECT * FROM users ORDER BY name ASC, age DESC');
    });

    test('Order By with empty columns', () {
      expect(
          () => query
            ..selectAll()
            ..from('users')
            ..orderBy([], [Order.asc, Order.desc]),
          throwsA(TypeMatcher<SelectQueryError>()));
    });

    test('Limit and Offset', () {
      query
        ..selectAll()
        ..from('users')
        ..limit(10)
        ..offset(5);
      expect(query.build(), 'SELECT * FROM users LIMIT 10 OFFSET 5');
    });

    test('Complex query', () {
      query
        ..select(['users.name', 'orders.order_number'])
        ..from('users')
        ..join('orders', 'users.id = orders.user_id', JoinType.left)
        ..where('users.age > ?', [21])
        ..and()
        ..where('users.country = ?', ['USA'])
        ..groupBy(['users.name'])
        ..having('COUNT(orders.id) > ?', [1])
        ..orderBy(['users.name'], [Order.asc])
        ..limit(10)
        ..offset(5);
      expect(
          query.build(),
          'SELECT users.name,orders.order_number FROM users LEFT JOIN orders ON users.id = orders.user_id '
          'WHERE users.age > @1 AND users.country = @2 GROUP BY users.name HAVING COUNT(orders.id) > @3 '
          'ORDER BY users.name ASC LIMIT 10 OFFSET 5');
    });
  });

  group('Select query with PostgreSQL connection', () {
    final postgreSQL = PostgresSQL.connectionString(psqlConnectionString);

    late SelectQuery query;

    setUpAll(() async {
      await postgreSQL.open();
      await createUsers(postgreSQL);
      await createOrderTable(postgreSQL);
      await createCardTable(postgreSQL);
    });

    setUp(() {
      query = postgreSQL.select;
    });

    tearDownAll(() async {
      await dropUsers(postgreSQL);
      await dropOrder(postgreSQL);
      await dropCard(postgreSQL);
    });

    test('Select all columns', () async {
      final q = query
        ..selectAll()
        ..from('users');

      final res = await postgreSQL.query(q);
      expect(5, res.length);
      expect('User 5', res.last[1]);
    });

    test('Select all columns with queryMapped', () async {
      final q = query
        ..selectAll()
        ..from('users');

      final res = await postgreSQL.queryMapped(q);
      expect(5, res.length);
      expect('User 5', res.last["users"]?["name"]);
    });

    test('Select specific columns', () async {
      final q = query
        ..select(['age'])
        ..from('users');

      final res = await postgreSQL.query(q);
      expect(5, res.length);
      expect(22, res.last.first);
    });

    test('Select distinct', () async {
      final q = query
        ..selectDistinct(['age'])
        ..from('users');

      final res = await postgreSQL.query(q);

      expect(4, res.length);
      expect(1, res.where((e) => e.first == 25).length);
    });

    test('SELECT query with WHERE condition', () async {
      final q = query
        ..select(['name', 'age'])
        ..from('users')
        ..where('age > ?', [30]);

      final res = await postgreSQL.query(q);

      expect(1, res.length);
      expect('User 4', res.first[0]);
    });

    test('Multiple WHERE conditions with AND operator', () async {
      final q = query
        ..selectAll()
        ..from('users')
        ..where('age > ?', [25])
        ..and()
        ..where('country = ?', ['USA']);

      final res = await postgreSQL.query(q);

      expect(1, res.length);
      expect('User 4', res.first[1]);
      expect('USA', res.first[4]);
    });

    test('Multiple Where conditions with OR operator', () async {
      final q = query
        ..selectAll()
        ..from('users')
        ..where('(age > ?', [20])
        ..and()
        ..where('age < ?)', [30])
        ..or()
        ..where('country = ?', ['USA']);

      final res = await postgreSQL.query(q);

      expect(4, res.length);
      expect('USA', res.firstWhereOrNull((e) => e[4] == 'USA')?[4]);
    });

    test('Join', () async {
      final q = query
        ..selectAll()
        ..from('users')
        ..join('orders', 'users.id = orders.user_id');

      final res = await postgreSQL.queryMapped(q);

      expect(4, res.length);
      expect(
          true, res.any((e) => e['users']?['id'] == e['orders']?['user_id']));
    });

    test('Join multiple', () async {
      final q = query
        ..select(['u.id', 'u.name', 'o.*', 'c.*'])
        ..from('users u')
        ..join('orders o', 'u.id = o.user_id')
        ..join('cards c', 'u.id = c.user_id')
        ..where('age >= ?', [30]);

      final res = await postgreSQL.queryMapped(q);

      expect(1, res.length);
      expect(
          true, res.any((e) => e['users']?['id'] == e['orders']?['user_id']));
      expect(true, res.any((e) => e['users']?['id'] == e['cards']?['user_id']));
    });

    test('Group By', () async {
      final q = query
        ..select(['country', 'COUNT(*)'])
        ..from('users')
        ..groupBy(['country']);

      final res = await postgreSQL.queryMapped(q);

      for (final r in res) {
        switch (r['users']?['country'] as String) {
          case 'USA':
            expect(2, r['']?['count']);
            break;
          case 'Canada':
            expect(2, r['']?['count']);
            break;
          case 'Mexico':
            expect(1, r['']?['count']);
            break;
        }
      }
    });

    test('Having', () async {
      final q = query
        ..select(['country', 'COUNT(*)'])
        ..from('users')
        ..groupBy(['country'])
        ..having('COUNT(*) > ?', [1]);

      final res = await postgreSQL.queryMapped(q);

      for (final r in res) {
        expect(r['']?['count'], greaterThan(1));
      }
    });

    test('Order By', () async {
      final q = query
        ..selectAll()
        ..from('users')
        ..orderBy(['age'], [Order.desc]);

      final res = await postgreSQL.queryMapped(q);

      expect(
          true,
          isSorted(
              res.map((e) => e['users']!['age'] as int).toList(), Order.desc));
    });

    test('Limit and Offset', () async {
      final q = query
        ..selectAll()
        ..from('users')
        ..limit(2)
        ..offset(2);

      final res = await postgreSQL.query(q);

      expect(res.length, lessThanOrEqualTo(2));
      for (final r in res) {
        expect(r[0], greaterThan(2));
      }
    });

    test('Complex query', () async {
      final q = query
        ..select(['users.name', 'orders.product'])
        ..from('users')
        ..join('orders', 'users.id = orders.user_id', JoinType.left)
        ..where('users.age > ?', [21])
        ..and()
        ..where('users.country = ?', ['USA'])
        ..groupBy(['users.name', 'orders.product'])
        ..orderBy(['users.name'], [Order.desc])
        ..limit(10);

      final res = await postgreSQL.queryMapped(q);

      expect(res.length, lessThanOrEqualTo(10));
      expect(
          true,
          isSorted(
              res
                  .map((e) => int.parse(e['users']!['name'].split(' ')[1]))
                  .toList(),
              Order.desc));
    });
  });

  group('InsertQuery', () {
    late InsertQuery query;

    setUp(() {
      query = InsertQuery();
    });

    test('Insert a single row', () {
      query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30});

      expect(query.build(), 'INSERT INTO users (name, age) VALUES (@1, @2)');
    });

    test('Insert multiple rows', () {
      query
        ..into('users')
        ..insertAll([
          {'name': 'John Doe', 'age': 30},
          {'name': 'Jane Doe', 'age': 25}
        ]);

      expect(query.build(),
          'INSERT INTO users (name, age) VALUES (@1, @2), (@3, @4)');
    });

    test('Insert with onConflict doNothing', () {
      query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30})
        ..onConflictDoNothing(['age']);

      expect(query.build(),
          'INSERT INTO users (name, age) VALUES (@1, @2) ON CONFLICT (age) DO NOTHING');
    });

    test('Insert with onConflict doUpdate', () {
      query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30})
        ..onConflictDoUpdate(['age'], {'age': 31});

      expect(query.build(),
          'INSERT INTO users (name, age) VALUES (@1, @2) ON CONFLICT (age) DO UPDATE SET age = @3');
    });

    test('Insert with returning', () {
      query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30})
        ..returning(['id']);

      expect(query.build(),
          'INSERT INTO users (name, age) VALUES (@1, @2) RETURNING id');
    });

    test('Insert with returning all', () {
      query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30})
        ..returnAll();

      expect(query.build(),
          'INSERT INTO users (name, age) VALUES (@1, @2) RETURNING *');
    });

    test('Insert without specifying a table should throw error', () {
      expect(
          () => query
            ..insert({'name': 'John Doe', 'age': 30})
            ..build(),
          throwsA(TypeMatcher<
              InsertQueryError>())); // You might want to define QueryError in your codebase.
    });

    test(
        'Insert with onConflict doUpdate without updateValues should throw error',
        () {
      query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30});

      expect(
          () => query.onConflict(ConflictAction.doUpdate, ['age']),
          throwsA(TypeMatcher<
              InsertQueryError>())); // You might want to define QueryError in your codebase.
    });
  });

  group('InsertQuery with PostgreSQL connections', () {
    final postgreSQL = PostgresSQL.connectionString(psqlConnectionString);
    late InsertQueryPostgres query;

    setUpAll(() async {
      await postgreSQL.open();
    });

    setUp(() async {
      query = postgreSQL.insert;
      await createUsersTable(postgreSQL);
    });

    tearDownAll(() async {
      await postgreSQL.close();
    });

    tearDown(() async {
      await dropUsers(postgreSQL);
    });

    test('Insert a single row', () async {
      final q = query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30});

      await q.execute();

      final q2 = postgreSQL.select
        ..from('users')
        ..select(['name', 'age']);
      final res = await q2.query();

      expect(res.length, 1);
      expect(res.first[0], "John Doe");
    });

    test('Insert multiple rows', () async {
      final q = query
        ..into('users')
        ..insertAll([
          {'name': 'John Doe', 'age': 30},
          {'name': 'Jane Doe', 'age': 25}
        ]);

      await q.execute();

      final q2 = postgreSQL.select
        ..from('users')
        ..select(['name', 'age']);
      final res = await q2.query();

      expect(res.length, 2);
      expect(res.first[0], "John Doe");
      expect(res.last[0], "Jane Doe");
    });

    test('Insert with onConflict doNothing', () async {
      await (postgreSQL.insert
            ..into('users')
            ..insert({'name': 'John Doe', 'age': 30, 'unq': 'test'}))
          .execute();
      final q = query
        ..into('users')
        ..insert({'name': 'Jane Doe', 'age': 23, 'unq': 'test'})
        ..onConflictDoNothing(['unq']);

      await q.execute();

      final res = await (postgreSQL.select
            ..from('users')
            ..select(['name', 'age']))
          .query();

      expect("John Doe", res.first[0]);
      expect(30, res.first[1]);
    });

    test('Insert with onConflict doUpdate', () async {
      await (postgreSQL.insert
            ..into('users')
            ..insert({'name': 'John Doe', 'age': 30, 'unq': 'test'}))
          .execute();
      final q = query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30, 'unq': 'test'})
        ..onConflictDoUpdate(['unq'], {'age': 31});

      await q.execute();

      final res = await (postgreSQL.select
            ..from('users')
            ..select(['name', 'age']))
          .query();

      expect("John Doe", res.first[0]);
      expect(31, res.first[1]);
    });

    test('Insert with returning', () async {
      final q = query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30})
        ..returning(['id']);

      final res = await q.query();

      expect(res.first[0], 1);
    });

    test('Insert with returning all', () async {
      final q = query
        ..into('users')
        ..insert({'name': 'John Doe', 'age': 30})
        ..returnAll();

      final res = await q.query();

      expect(res.first[0], 1);
      expect(res.first[1], 'John Doe');
      expect(res.first[2], 30);
    });
  });

  group('UpdateQuery', () {
    late UpdateQuery query;

    setUp(() {
      query = UpdateQuery();
    });

    test('Update with single set column', () {
      query
        ..update('users')
        ..setSingle('name', 'John Doe')
        ..where('id = ?', [1]);

      expect(query.build(), "UPDATE users SET name = @1 WHERE id = @2");
      expect(query.values, ['John Doe', 1]);
    });

    test('Update with multiple set columns', () {
      query
        ..update('users')
        ..set({'name': 'John Doe', 'age': 30})
        ..where('id = ?', [1]);

      expect(
          query.build(), "UPDATE users SET name = @1, age = @2 WHERE id = @3");
      expect(query.values, ['John Doe', 30, 1]);
    });

    test('Update with WHERE and AND', () {
      query
        ..update('users')
        ..set({'name': 'John Doe'})
        ..where('age >= ?', [18])
        ..and()
        ..where('country = ?', ['US']);

      expect(query.build(),
          "UPDATE users SET name = @1 WHERE age >= @2 AND country = @3");
      expect(query.values, ['John Doe', 18, 'US']);
    });

    test('Update with WHERE and OR', () {
      query
        ..update('users')
        ..set({'name': 'John Doe'})
        ..where('country = ?', ['US'])
        ..or()
        ..where('country = ?', ['CA']);

      expect(query.build(),
          "UPDATE users SET name = @1 WHERE country = @2 OR country = @3");
      expect(query.values, ['John Doe', 'US', 'CA']);
    });

    test('Update with RETURNING clause', () {
      query
        ..update('users')
        ..set({'name': 'John Doe'})
        ..where('id = ?', [1])
        ..returning(['name', 'age']);

      expect(query.build(),
          "UPDATE users SET name = @1 WHERE id = @2 RETURNING name, age");
      expect(query.values, ['John Doe', 1]);
    });

    test('Update without table should throw exception', () {
      expect(() {
        query
          ..set({'name': 'John Doe'})
          ..where('id = ?', [1])
          ..build();
      }, throwsA(TypeMatcher<UpdateQueryError>()));
    });

    test('Update without columns should throw exception', () {
      expect(() {
        query
          ..update('users')
          ..where('id = ?', [1])
          ..build();
      }, throwsA(TypeMatcher<UpdateQueryError>()));
    });

    test('Update without table should throw exception', () {
      expect(() {
        query
          ..set({'name': 'John Doe'})
          ..where('id = ?', [1])
          ..build();
      }, throwsA(TypeMatcher<UpdateQueryError>()));
    });

    test('Update without columns should throw exception', () {
      expect(() {
        query
          ..update('users')
          ..where('id = ?', [1])
          ..build();
      }, throwsA(TypeMatcher<UpdateQueryError>()));
    });

    test('Update with empty set should throw exception', () {
      expect(() {
        query
          ..update('users')
          ..set({})
          ..where('id = ?', [1])
          ..build();
      }, throwsA(TypeMatcher<UpdateQueryError>()));
    });

    test('Update with empty returning columns should throw exception', () {
      expect(() {
        query
          ..update('users')
          ..set({'name': 'John Doe'})
          ..returning([])
          ..build();
      }, throwsA(TypeMatcher<QueryError>()));
    });

    test('Update with empty table name should throw exception', () {
      expect(() {
        query
          ..update('')
          ..set({'name': 'John Doe'})
          ..where('id = ?', [1])
          ..build();
      }, throwsA(TypeMatcher<UpdateQueryError>()));
    });

    test('Update with empty column name should throw exception', () {
      expect(() {
        query
          ..update('users')
          ..setSingle('', 'John Doe')
          ..where('id = ?', [1])
          ..build();
      }, throwsA(TypeMatcher<UpdateQueryError>()));
    });
  });

  group('UpdateQuery with PostgreSQL connections', () {
    final postgreSQL = PostgresSQL.connectionString(psqlConnectionString);
    late UpdateQueryPostgres query;

    setUpAll(() async {
      await postgreSQL.open();
    });

    setUp(() async {
      query = postgreSQL.update;
      await createUsersTable(postgreSQL);
    });

    tearDownAll(() async {
      await postgreSQL.close();
    });

    tearDown(() async {
      await dropUsers(postgreSQL);
    });

    Future<PostgreSQLResult> queryUser([List<String> select = const ['name']]) {
      return (postgreSQL.select
            ..select(select)
            ..from('users')
            ..where('id = ?', [1]))
          .query();
    }

    Future<void> createUser() async {
      await (postgreSQL.insert
            ..into('users')
            ..insert({'name': 'Jane Doe', 'age': 22}))
          .execute();
      final user = await queryUser(['id', 'name', 'age']);
      expect(user.first.first, 1);
      expect(user.first[1], 'Jane Doe');
      expect(user.first[2], 22);
    }

    Future<void> createUsers() async {
      List<Map<String, dynamic>> users = List.generate(20, (index) {
        return {
          'name': 'User $index',
          'age': 20 + index,
          'email': 'user$index@example.com',
          'country': countries[index % 5],
          'unq': 'unique$index'
        };
      });

      await (postgreSQL.insert
            ..into('users')
            ..insertAll(users))
          .execute();

      final res1 = await (postgreSQL.select
            ..select(['COUNT(*)'])
            ..from('users'))
          .query();
      expect(res1.first.first, 20);
    }

    test('Update with single set column', () async {
      await createUser();
      final q = query
        ..update('users')
        ..setSingle('name', 'John Doe')
        ..where('id = ?', [1]);

      await q.execute();
      final res = await queryUser();

      expect(res.first[0], 'John Doe');
    });

    test('Update with multiple set columns', () async {
      await createUser();
      final q = query
        ..update('users')
        ..set({'name': 'John Doe', 'age': 30})
        ..where('id = ?', [1]);

      await q.execute();
      final res = await queryUser(['name', 'age']);

      expect(res.first[0], 'John Doe');
      expect(res.first[1], 30);
    });

    test('Update with WHERE and AND', () async {
      await createUsers();
      final q = query
        ..update('users')
        ..set({'name': 'John Doe'})
        ..where('age >= ?', [30])
        ..and()
        ..where('country = ?', ['USA']);

      await q.execute();
      final res = await (postgreSQL.select
            ..select(['name', 'age', 'country'])
            ..from('users')
            ..where('age >= ?', [30])
            ..and()
            ..where('country = ?', ['USA']))
          .query();

      expect(res.any((e) => e.first == 'John Doe'), true);
    });

    test('Update with WHERE and OR', () async {
      await createUsers();
      final q = query
        ..update('users')
        ..set({'name': 'John Doe'})
        ..where('country = ?', ['US'])
        ..or()
        ..where('country = ?', ['Canada']);

      await q.execute();
      final res = await (postgreSQL.select
            ..select(['name', 'country'])
            ..from('users')
            ..where('country = ?', ['US'])
            ..or()
            ..where('country = ?', ['Canada']))
          .query();

      expect(res.any((e) => e.first == 'John Doe'), true);
    });

    test('Update with RETURNING clause', () async {
      await createUser();
      final q = query
        ..update('users')
        ..set({'name': 'John Doe'})
        ..where('id = ?', [1])
        ..returning(['name', 'age']);

      final res1 = await q.query();
      expect(res1.first, ['John Doe', 22]);

      final res2 = await queryUser();
      expect(res2.first.first, 'John Doe');
    });
  });

  group('DeleteQuery', () {
    late DeleteQuery query;

    setUp(() {
      query = DeleteQuery();
    });

    test('Delete all rows', () {
      query.deleteFrom('users');
      expect(query.build(), 'DELETE FROM users');
    });

    test('Delete with WHERE clause', () {
      query
        ..deleteFrom('users')
        ..where('age > 30');
      expect(query.build(), 'DELETE FROM users WHERE age > 30');
    });

    test('Delete with LIMIT', () {
      query
        ..deleteFrom('users')
        ..where('age > 30')
        ..limit(5);
      expect(query.build(), 'DELETE FROM users WHERE age > 30 LIMIT 5');
    });

    test('Delete with ORDER BY', () {
      query
        ..deleteFrom('users')
        ..orderBy('age', order: Order.desc);
      expect(query.build(), 'DELETE FROM users ORDER BY age DESC');
    });

    test('Delete with CASCADE', () {
      query
        ..deleteFrom('users')
        ..cascadeDelete();
      expect(query.build(), 'DELETE FROM users CASCADE');
    });

    test('Delete with RETURNING', () {
      query
        ..deleteFrom('users')
        ..where('age > 30')
        ..returning(['id', 'name']);
      expect(
          query.build(), 'DELETE FROM users WHERE age > 30 RETURNING id, name');
    });

    test('Throw exception if table is not set', () {
      expect(() => query.build(), throwsA(isA<DeleteQueryError>()));
    });
  });

  group('DeleteQuery with PostgreSQL connections', () {
    final postgreSQL = PostgresSQL.connectionString(psqlConnectionString);

    setUpAll(() async {
      await postgreSQL.open();
    });

    setUp(() async {
      await createUsersTable(postgreSQL);
    });

    tearDownAll(() async {
      await postgreSQL.close();
    });

    tearDown(() async {
      await dropUsers(postgreSQL);
    });

    Future<void> createUsers() async {
      List<Map<String, dynamic>> users = List.generate(20, (index) {
        return {
          'name': 'User $index',
          'age': 20 + index,
          'email': 'user$index@example.com',
          'country': countries[index % 5],
          'unq': 'unique$index'
        };
      });

      await (postgreSQL.insert
            ..into('users')
            ..insertAll(users))
          .execute();

      final res1 = await (postgreSQL.select
            ..select(['COUNT(*)'])
            ..from('users'))
          .query();
      expect(res1.first.first, 20);
    }

    test('Delete all rows', () async {
      await createUsers();
      await (postgreSQL.delete..deleteFrom('users')).execute();

      final res = await (postgreSQL.select
            ..select(['COUNT(*)'])
            ..from('users'))
          .query();
      expect(res.first.first, 0);
    });

    test('Delete with WHERE clause', () async {
      await createUsers();
      await (postgreSQL.delete
            ..deleteFrom('users')
            ..where('age >= 30'))
          .execute();

      final res = await (postgreSQL.select
            ..select(['COUNT(*)'])
            ..from('users'))
          .query();
      expect(res.first.first, 10);
    });

    test('Delete with RETURNING', () async {
      await createUsers();
      final res = await (postgreSQL.delete
            ..deleteFrom('users')
            ..where('age >= 30')
            ..returning(['id', 'name']))
          .query();

      expect(res.first.first, 11);
      expect(res.last.first, 20);
    });
  });
}

bool isSorted(List<int> numbers, Order order) {
  for (int i = 0; i < numbers.length - 1; i++) {
    if (order == Order.asc && numbers[i] > numbers[i + 1]) {
      return false;
    }
    if (order == Order.desc && numbers[i] < numbers[i + 1]) {
      return false;
    }
  }
  return true;
}
