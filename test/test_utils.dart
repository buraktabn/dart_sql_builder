import 'package:dart_sql_builder/dart_sql_builder.dart';

const psqlConnectionString =
    'postgresql://postgres:123456@localhost:5432/postgres';

Future<void> createUsersTable(PostgresSQL postgreSQL, {PostgresTx? tx}) async {
  await postgreSQL.rawExecute('''
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          name TEXT,
          age INT,
          email TEXT,
          country TEXT,
          unq TEXT UNIQUE
        )''', tx: tx);
}

Future<void> createUsers(PostgresSQL postgreSQL) async {
  await postgreSQL.tx((connection) async {
    await createUsersTable(postgreSQL, tx: connection);

    await postgreSQL.rawExecute('''
        INSERT INTO users (name, age, email, country)
        VALUES 
          ('User 1', 25, 'user1@example.com', 'USA'),
          ('User 2', 30, 'user2@example.com', 'Canada'),
          ('User 3', 25, 'user3@example.com', 'Mexico'),
          ('User 4', 35, 'user4@example.com', 'USA'),
          ('User 5', 22, 'user5@example.com', 'Canada')''', tx: connection);
  });
}

Future<void> createOrderTable(PostgresSQL postgreSQL) async {
  await postgreSQL.tx((connection) async {
    await postgreSQL.rawExecute('''
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        user_id INT,
        product TEXT,
        quantity INT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )''', tx: connection);

    await postgreSQL.rawExecute('''
      INSERT INTO orders (user_id, product, quantity)
      VALUES 
        (1, 'Product 1', 2),
        (3, 'Product 3', 3),
        (3, 'Product 4', 1),
        (4, 'Product 5', 2)''', tx: connection);
  });
}

Future<void> createCardTable(PostgresSQL postgreSQL) async {
  await postgreSQL.tx((connection) async {
    await postgreSQL.rawExecute('''
      CREATE TABLE IF NOT EXISTS cards (
        id SERIAL PRIMARY KEY,
        user_id INT,
        card_number TEXT,
        expiry_date TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )''', tx: connection);

    await postgreSQL.rawExecute('''
      INSERT INTO cards (user_id, card_number, expiry_date)
      VALUES 
        (1, '1111-2222-3333-4444', '12/25'),
        (2, '5555-6666-7777-8888', '06/23'),
        (3, '9999-0000-1111-2222', '09/24'),
        (4, '3333-4444-5555-6666', '03/23'),
        (5, '7777-8888-9999-0000', '08/25')''', tx: connection);
  });
}

Future<void> dropUsers(PostgresSQL postgreSQL) async {
  await postgreSQL.rawExecute('DROP TABLE IF EXISTS users CASCADE');
}

Future<void> dropOrder(PostgresSQL postgreSQL) async {
  await postgreSQL.rawExecute('DROP TABLE IF EXISTS orders CASCADE');
}

Future<void> dropCard(PostgresSQL postgreSQL) async {
  await postgreSQL.rawExecute('DROP TABLE IF EXISTS cards CASCADE');
}

final List<String> countries = [
  'USA',
  'Canada',
  'Brazil',
  'United Kingdom',
  'France',
  'Germany',
  'Australia',
  'New Zealand',
  'India',
  'China',
  'Japan',
  'South Korea',
  'Russia',
  'South Africa',
  'Nigeria',
  'Mexico',
  'Argentina',
  'Saudi Arabia',
  'Egypt',
  'Singapore'
];
