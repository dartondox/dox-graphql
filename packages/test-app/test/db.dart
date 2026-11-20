import 'package:dox_orm/dox_orm.dart';

/// The SQL of every query since [startCounting].
final List<String> queries = <String>[];

void _count(QueryEvent e) => queries.add(e.sql);

/// Opens an in-memory SQLite database with the tables and rows of the
/// tests.
Future<void> setUpDatabase() async {
  SqlQueryBuilder.initializeWithDatabaseConfig(
    DatabaseConfig(
      connection: 'sqlite',
      url: '',
      connections: <String, ConnectionConfig>{
        'sqlite': ConnectionConfig(
          driver: Driver.sqlite,
          database: ':memory:',
          debug: false,
        ),
      },
    ),
  );
  await Schema().create('users', (Table table) {
    table.id();
    table.string('name');
    table.string('password');
    table.timestamps();
  });
  await Schema().create('posts', (Table table) {
    table.id();
    table.string('title');
    table.text('body').nullable();
    table.integer('user_id').nullable();
    table.string('status').nullable();
    table.string('internal_note').nullable();
    table.timestamps();
  });
  await Schema().create('comments', (Table table) {
    table.id();
    table.string('body');
    table.integer('post_id');
    table.timestamps();
  });
  await Schema().create('profiles', (Table table) {
    table.id();
    table.string('bio');
    table.integer('user_id').nullable();
    table.integer('member_id').nullable();
    table.timestamps();
  });
  await Schema().create('members', (Table table) {
    table.id();
    table.string('name').nullable();
    table.string('email').nullable();
    table.string('secret').nullable();
    table.timestamps();
  });
  await Schema().create('accounts', (Table table) {
    table.id();
    table.string('name');
    table.string('email');
    table.string('secret');
    table.timestamps();
  });
  await Schema().create('tags', (Table table) {
    table.id();
    table.string('name');
    table.timestamps();
  });
  await Schema().create('post_tag', (Table table) {
    table.id();
    table.integer('post_id');
    table.integer('tag_id');
  });
  await Schema().create('images', (Table table) {
    table.id();
    table.string('url');
    table.integer('imageable_id');
    table.string('imageable_type');
    table.timestamps();
  });
  await Schema().create('articles', (Table table) {
    table.id();
    table.string('title');
    table.integer('user_id');
    table.softDeletes();
    table.timestamps();
  });
  await Schema().create('notes', (Table table) {
    table.id();
    table.string('title');
    table.integer('user_id');
    table.timestamps();
  });
  await Schema().create('docs', (Table table) {
    table.id();
    table.string('title');
    table.string('owner').nullable();
    table.integer('account_id').nullable();
    table.integer('parent_id').nullable();
    table.timestamps();
  });
  await QueryBuilder.table('docs').insertMany(<Map<String, dynamic>>[
    // the parent of Ann doc is Bob doc, which ann may not view
    <String, dynamic>{
      'title': 'Ann doc',
      'owner': 'ann',
      'account_id': 1,
      'parent_id': 2,
    },
    <String, dynamic>{'title': 'Bob doc', 'owner': 'bob', 'account_id': 1},
    <String, dynamic>{'title': 'Ann note', 'owner': 'ann', 'parent_id': 1},
  ]);
  await QueryBuilder.table('profiles').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{'bio': 'Ada bio', 'user_id': 1},
    <String, dynamic>{'bio': 'Member bio', 'member_id': 1},
  ]);
  await QueryBuilder.table('members').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{'name': 'ann', 'email': 'a@x', 'secret': 's'},
    <String, dynamic>{'name': 'bob', 'email': 'b@x', 'secret': 's'},
    // old rows that break the rules of MemberDto now
    <String, dynamic>{'name': 'ab', 'email': 'c@x', 'secret': 's'},
    <String, dynamic>{'name': null, 'email': 'd@x', 'secret': 's'},
  ]);
  await QueryBuilder.table('accounts')
      .insert(<String, dynamic>{'name': 'main', 'email': 'e@x', 'secret': 's'});
  await QueryBuilder.table('tags').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{'name': 'dart'},
    <String, dynamic>{'name': 'graphql'},
  ]);
  await QueryBuilder.table('post_tag').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{'post_id': 1, 'tag_id': 1},
    <String, dynamic>{'post_id': 1, 'tag_id': 2},
    <String, dynamic>{'post_id': 2, 'tag_id': 2},
  ]);
  await QueryBuilder.table('images').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{
      'url': 'a.png',
      'imageable_id': 1,
      'imageable_type': 'Post',
    },
    <String, dynamic>{
      'url': 'b.png',
      'imageable_id': 3,
      'imageable_type': 'Post',
    },
    <String, dynamic>{
      'url': 'c.png',
      'imageable_id': 1,
      'imageable_type': 'Other',
    },
  ]);
  await QueryBuilder.table('articles').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{'title': 'Kept', 'user_id': 1},
    <String, dynamic>{
      'title': 'Gone',
      'user_id': 1,
      'deleted_at': '2026-01-01T00:00:00.000',
    },
    <String, dynamic>{'title': 'Bob', 'user_id': 2},
  ]);
  await QueryBuilder.table('users').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{'name': 'Ada', 'password': 'secret1'},
    <String, dynamic>{'name': 'Bob', 'password': 'secret2'},
  ]);
  await QueryBuilder.table('posts').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{
      'title': 'Hello GraphQL',
      'body': 'First post',
      'user_id': 1,
      'status': 'published',
      'internal_note': 'x',
    },
    <String, dynamic>{
      'title': 'Second',
      'body': 'Hi',
      'user_id': 2,
      'status': 'draft',
    },
    <String, dynamic>{
      'title': 'Third',
      'body': 'Bye',
      'user_id': 1,
      'status': 'draft',
    },
  ]);
  await QueryBuilder.table('comments').insertMany(<Map<String, dynamic>>[
    <String, dynamic>{'body': 'Nice post', 'post_id': 1},
    <String, dynamic>{'body': 'Thanks', 'post_id': 1},
    <String, dynamic>{'body': 'Ok', 'post_id': 3},
  ]);
}

/// Starts counting the queries.
void startCounting() {
  queries.clear();
  SqlQueryBuilder().listen(_count);
}

/// Stops counting.
void stopCounting() => SqlQueryBuilder().removeListener(_count);
