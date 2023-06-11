# Dart SQL Builder 🚀

`dart_sql_builder` is a powerful and flexible query builder for Dart that simplifies the process of creating complex SQL queries. It is not an ORM, nor is it type-safe, but it provides a more readable and maintainable way to build SQL queries without having to write raw SQL strings.

The package includes support for various query types, including SELECT, INSERT, UPDATE, and DELETE queries. It also provides a convenient API for chaining query components together, making it easy to create complex queries with minimal effort 🛠️.

In addition to the core query-building functionality, `dart_sql_builder` has plans for future enhancements, such as:

- A migration tool to manage database tables 📦
- Support for additional SQL drivers besides PostgreSQL 🔄
- Builders to help create type-safe queries 🔒

The `dart_sql_builder` package comes with a built-in PostgreSQL driver, which can be easily integrated into your Dart projects. Here's an example of how to use the package with the PostgreSQL driver:

```dart
final postgreSQL = PostgreSQL();
final selectQuery = postgreSQL.select;
final insertQuery = postgreSQL.insert;
final updateQuery = postgreSQL.update;
final deleteQuery = postgreSQL.delete;
```

You can run the query with PostgreSQL:

```dart
final postgreSQL = PostgreSQL();

await postgreSQL.open();

final query = postgreSQL.select
  ..select(['name', 'age'])
  ..from('users')
  ..where('age > ?', [30]);

await query.query();
await query.queryMapped();
await query.execute();
```

Or run raw queries:

```dart
final postgreSQL = PostgreSQL();
final query = 'SELECT COUNT(*) FROM users';

await postgreSQL.rawQuery(query);
await query.rawQueryMapped(query);
await query.rawExecute(query);

```

The base `Query` class serves as the foundation for all queries and can be extended to support additional database drivers and custom query types.

In the following sections, you'll find detailed documentation for each of the supported query types: `SelectQuery`, `InsertQuery`, `UpdateQuery`, and `DeleteQuery`. These guides will help you understand how to use the `dart_sql_builder` package effectively and efficiently to build SQL queries for your Dart applications.

Now, dive into the documentation for each query type to learn how to use the `dart_sql_builder` package to its full potential:

1. [SelectQuery](#selectquery) 📖
2. [InsertQuery](#insertquery) 📝
3. [UpdateQuery](#updatequery) 🔄
4. [DeleteQuery](#deletequery) ❌

# InsertQuery

Add new rows to a table in your database. `InsertQuery` allows you to insert single or multiple rows at once, and even provides conflict handling options for dealing with unique constraints.

## Usage

To use `InsertQuery`, you first need to create an instance of it. You can then chain methods to build the query as needed.

Here's an example of how to build a simple INSERT query:

```dart
final query = InsertQuery()
  ..into('users')
  ..insert({'name': 'John Doe', 'age': 30});
```

This will generate the following SQL query:

```sql
INSERT INTO users (name, age) VALUES ('John Doe', 30);
```

## Methods

### into

The `into` method is used to specify the table you want to insert into.

```dart
query.into('users');
```

### insert

The `insert` method is used to specify the values you want to insert for the columns in the table. You can pass a map of column names and their corresponding values.

```dart
query.insert({'name': 'John Doe', 'age': 30});
```

### insertAll

The `insertAll` method is used to insert multiple rows at once. You can pass a list of maps, where each map contains the column names and their corresponding values.

```dart
query.insertAll([
  {'name': 'John Doe', 'age': 30},
  {'name': 'Jane Doe', 'age': 25}
]);
```

### onConflictDoNothing

The `onConflictDoNothing` method is used to specify that the insert operation should do nothing if there is a conflict with the specified columns.

```dart
query.insert({'name': 'John Doe', 'age': 30, 'unq': 'test'}).onConflictDoNothing(['unq']);
```

### onConflictDoUpdate

The `onConflictDoUpdate` method is used to specify that the insert operation should update the specified columns if there is a conflict with the provided columns.

```dart
query.insert({'name': 'John Doe', 'age': 30, 'unq': 'test'}).onConflictDoUpdate(['unq'], {'age': 31});
```

### returning

The `returning` method is used to specify the columns to return after the insert operation. You can pass an array of strings, where each string represents a column name.

```dart
query.returning(['id']);
```

### returnAll

The `returnAll` method is used to return all columns after the insert operation.

```dart
query.returnAll();
```

## Example

Here's an example of a complex INSERT query using `InsertQuery`:

```dart
final query = InsertQuery()
  ..into('users')
  ..insert({'name': 'John Doe', 'age': 30, 'unq': 'test'})
  ..onConflictDoUpdate(['unq'], {'age': 31})
  ..returnAll();
```

This will generate the following SQL query:

```sql
INSERT INTO users (name, age, unq) VALUES ('John Doe', 30, 'test')
ON CONFLICT (unq) DO UPDATE SET age = 31 RETURNING *;
```

# SelectQuery

Retrieve data from one or more tables in your database. With `SelectQuery`, you can filter, sort, group, and join data, making it easy to fetch exactly what you need.

## Usage

To use `SelectQuery`, you first need to create an instance of it. You can then chain methods to build the query as needed.

Here's an example of how to build a simple SELECT query:

```dart
final query = SelectQuery()
  ..select(['name', 'age'])
  ..from('users')
  ..where('age > ?', [30]);
```

This will generate the following SQL query:

```sql
SELECT name, age FROM users WHERE age > 30;
```

## Methods

### select

The `select` method is used to specify the columns you want to select in the query. You can pass an array of strings, where each string represents a column name.

```dart
query.select(['name', 'age']);
```

### selectAll

The `selectAll` method is used to select all columns in the query.

```dart
query.selectAll();
```

### selectDistinct

The `selectDistinct` method is used to select distinct values for the specified columns.

```dart
query.selectDistinct(['age']);
```

### from

The `from` method is used to specify the table you want to select from.

```dart
query.from('users');
```

### where

The `where` method is used to add a WHERE condition to the query. You can pass a string representing the condition, and an array of values to replace the placeholders in the condition.

```dart
query.where('age > ?', [30]);
```

### and

The `and` method is used to add an AND operator to the query, allowing you to chain multiple WHERE conditions.

```dart
query.where('age > ?', [30]).and().where('country = ?', ['USA']);
```

### or

The `or` method is used to add an OR operator to the query, allowing you to chain multiple WHERE conditions.

```dart
query.where('age > ?', [30]).or().where('country = ?', ['USA']);
```

### join

The `join` method is used to join another table to the query. You can pass the table name, the ON condition, and the type of join (default is INNER JOIN).

```dart
query.join('orders', 'users.id = orders.user_id');
```

### groupBy

The `groupBy` method is used to group the results by one or more columns.

```dart
query.groupBy(['country']);
```

### having

The `having` method is used to add a HAVING condition to the query, used with GROUP BY to filter the results.

```dart
query.having('COUNT(*) > ?', [1]);
```

### orderBy

The `orderBy` method is used to order the results by one or more columns. You can pass an array of column names and an array of `Order` enum values (either `Order.asc` or `Order.desc`) to specify the order for each column.

```dart
query.orderBy(['age'], [Order.desc]);
```

### limit

The `limit` method is used to limit the number of results returned by the query.

```dart
query.limit(10);
```

### offset

The `offset` method is used to specify the starting point of the results returned by the query.

```dart
query.offset(20);
```

## Example

Here's an example of a complex SELECT query using `SelectQuery`:

```dart
final query = SelectQuery()
  ..select(['users.name', 'orders.product'])
  ..from('users')
  ..join('orders', 'users.id = orders.user_id', JoinType.left)
  ..where('users.age > ?', [21])
  ..and()
  ..where('users.country = ?', ['USA'])
  ..groupBy(['users.name', 'orders.product'])
  ..orderBy(['users.name'], [Order.desc])
  ..limit(10);
```

This will generate the following SQL query:

```sql
SELECT users.name, orders.product
FROM users
LEFT JOIN orders ON users.id = orders.user_id
WHERE users.age > 21 AND users.country = 'USA'
GROUP BY users.name, orders.product
ORDER BY users.name DESC
LIMIT 10;
```

# UpdateQuery

Modify existing data in your database. `UpdateQuery` enables you to update specific columns in a table based on a set of conditions, making it easy to apply changes to targeted rows.

## Usage

To use `UpdateQuery`, you first need to create an instance of it. You can then chain methods to build the query as needed.

Here's an example of how to build a simple UPDATE query:

```dart
final query = UpdateQuery()
  ..update('users')
  ..set({'name': 'John Doe', 'age': 31})
  ..where('id = ?', [1]);
```

This will generate the following SQL query:

```sql
UPDATE users SET name = 'John Doe', age = 31 WHERE id = 1;
```

## Methods

### update

The `update` method is used to specify the table you want to update.

```dart
query.update('users');
```

### set

The `set` method is used to specify the values you want to set for the columns in the table. You can pass a map of column names and their corresponding values.

```dart
query.set({'name': 'John Doe', 'age': 31});
```

### where

The `where` method is used to add a WHERE condition to the query. You can pass a string representing the condition, and an array of values to replace the placeholders in the condition.

```dart
query.where('id = ?', [1]);
```

### and

The `and` method is used to add an AND operator to the query, allowing you to chain multiple WHERE conditions.

```dart
query
    ..where('age > ?', [30])
    ..and()
    ..where('country = ?', ['USA']);
```

### or

The `or` method is used to add an OR operator to the query, allowing you to chain multiple WHERE conditions.

```dart
query
    ..where('age > ?', [30])
    ..or()
    ..where('country = ?', ['USA']);
```

### returning

The `returning` method is used to specify the columns to return after the update operation. You can pass an array of strings, where each string represents a column name.

```dart
query.returning(['id']);
```

### returnAll

The `returnAll` method is used to return all columns after the update operation.

```dart
query.returnAll();
```

## Example

Here's an example of a complex UPDATE query using `UpdateQuery`:

```dart
final query = UpdateQuery()
  ..update('users')
  ..set({'name': 'John Doe', 'age': 31})
  ..where('age > ?', [21])
  ..and()
  ..where('country = ?', ['USA'])
  ..returnAll();
```

This will generate the following SQL query:

```sql
UPDATE users SET name = 'John Doe', age = 31 WHERE age > 21 AND country = 'USA' RETURNING *;
```

# DeleteQuery

Remove data from your database. `DeleteQuery` allows you to delete rows from a table based on specific conditions, ensuring that you only remove the data you intend to.

## Usage

To use `DeleteQuery`, you first need to create an instance of it. You can then chain methods to build the query as needed.

Here's an example of how to build a simple DELETE query:

```dart
final query = DeleteQuery()
  ..deleteFrom('users')
  ..where('id = ?', [1]);
```

This will generate the following SQL query:

```sql
DELETE FROM users WHERE id = 1;
```

## Methods

### deleteFrom

The `deleteFrom` method is used to specify the table you want to delete from.

```dart
query.deleteFrom('users');
```

### where

The `where` method is used to add a WHERE condition to the query. You can pass a string representing the condition, and an array of values to replace the placeholders in the condition.

```dart
query.where('id = ?', [1]);
```

### and

The `and` method is used to add an AND operator to the query, allowing you to chain multiple WHERE conditions.

```dart
query.where('age > ?', [30]).and().where('country = ?', ['USA']);
```

### or

The `or` method is used to add an OR operator to the query, allowing you to chain multiple WHERE conditions.

```dart
query.where('age > ?', [30]).or().where('country = ?', ['USA']);
```

### returning

The `returning` method is used to specify the columns to return after the delete operation. You can pass an array of strings, where each string represents a column name.

```dart
query.returning(['id']);
```

### returnAll

The `returnAll` method is used to return all columns after the delete operation.

```dart
query.returnAll();
```

## Example

Here's an example of a complex DELETE query using `DeleteQuery`:

```dart
final query = DeleteQuery()
  ..deleteFrom('users')
  ..where('age > ?', [21])
  ..and()
  ..where('country = ?', ['USA'])
  ..returnAll();
```

This will generate the following SQL query:

```sql
DELETE FROM users WHERE age > 21 AND country = 'USA' RETURNING *;
```

# Wrapping Up 🎁

Contributions from the community to help improve and expand the package's features and capabilities are always welcomed 🤝.

`dart_sql_builder` is released under the MIT license, which means you are free to use, modify, and distribute the code as you see fit. 

Remember, `dart_sql_builder` is made with love ❤️ and we look forward to seeing it grow and evolve with your support.

Happy coding! 🚀