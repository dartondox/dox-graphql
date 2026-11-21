import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:dox_orm/dox_orm.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

/// The `extensions.code` of each error.
List<Object?> _codes(Map<String, Object?> res) => <Object?>[
  for (Object? e in res['errors'] as List<Object?>)
    ((e as Map<String, Object?>)['extensions'] as Map<String, Object?>)['code'],
];

const String _info =
    'paginatorInfo { count currentPage firstItem lastItem hasMorePages '
    'lastPage perPage total }';

/// `@GraphQLPaginate`. Post has `@GraphQLAll` too, so its paged list is
/// `postsPaginate`. Note has only `@GraphQLPaginate`: it is `notes`.
void main() {
  late DoxTestClient client;

  setUpAll(() async {
    await setUpDatabase();
    client = await startApp(
      GraphQLConfig(
        schema: graphqlSchema,
        middleware: <Object>[const FakeAuthMiddleware()],
      ),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  test('the first page', () async {
    Map<String, Object?> res = await run(
      client,
      '{ postsPaginate(first: 2) { data { title } $_info } }',
    );
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'postsPaginate': <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'title': 'Hello GraphQL'},
            <String, Object?>{'title': 'Second'},
          ],
          'paginatorInfo': <String, Object?>{
            'count': 2,
            'currentPage': 1,
            'firstItem': 1,
            'lastItem': 2,
            'hasMorePages': true,
            'lastPage': 2,
            'perPage': 2,
            'total': 3,
          },
        },
      },
    });
  });

  test('the last page', () async {
    Map<String, Object?> res = await run(
      client,
      '{ postsPaginate(first: 2, page: 2) { data { title } $_info } }',
    );
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'postsPaginate': <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'title': 'Third'},
          ],
          'paginatorInfo': <String, Object?>{
            'count': 1,
            'currentPage': 2,
            'firstItem': 3,
            'lastItem': 3,
            'hasMorePages': false,
            'lastPage': 2,
            'perPage': 2,
            'total': 3,
          },
        },
      },
    });
  });

  test('the defaults, on an empty table', () async {
    Map<String, Object?> res = await run(
      client,
      '{ notes { data { id } $_info } }',
      user: null,
    );
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'notes': <String, Object?>{
          'data': <Object?>[],
          'paginatorInfo': <String, Object?>{
            'count': 0,
            'currentPage': 1,
            'firstItem': null,
            'lastItem': null,
            'hasMorePages': false,
            'lastPage': 0,
            'perPage': 20,
            'total': 0,
          },
        },
      },
    });
  });

  test('filter: a hidden row in the middle of a page', () async {
    for (String title in <String>['a', 'hidden', 'c', 'd']) {
      await QueryBuilder.table('notes')
          .insert(<String, dynamic>{'title': title, 'user_id': 1});
    }
    Map<String, Object?> res = await run(
      client,
      '{ notes(first: 3) { data { title } $_info } }',
      user: null,
    );
    // the page has 3 rows before the filter: firstItem and lastItem agree
    // with total and lastPage, count is the rows in data
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'notes': <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'title': 'a'},
            <String, Object?>{'title': 'c'},
          ],
          'paginatorInfo': <String, Object?>{
            'count': 2,
            'currentPage': 1,
            'firstItem': 1,
            'lastItem': 3,
            'hasMorePages': true,
            'lastPage': 2,
            'perPage': 3,
            'total': 4,
          },
        },
      },
    });
    await QueryBuilder.table('notes').delete();
  });

  test('a first above 100, or below 1, is an error', () async {
    for ((String, String) c in <(String, String)>[
      ('first: 101', '"first" can be at most 100.'),
      ('first: 0', '"first" and "page" must be at least 1.'),
      ('page: 0', '"first" and "page" must be at least 1.'),
    ]) {
      Map<String, Object?> res = await run(
        client,
        '{ postsPaginate(${c.$1}) { data { id } } }',
      );
      expect(res['data'], <String, Object?>{'postsPaginate': null});
      expect(
        ((res['errors'] as List<Object?>).single
            as Map<String, Object?>)['message'],
        c.$2,
        reason: c.$1,
      );
    }
  });

  test('both @GraphQLAll and @GraphQLPaginate: posts is the list', () async {
    Map<String, Object?> res = await run(client, '{ posts(limit: 1) { id } }');
    expect(res['data'], <String, Object?>{
      'posts': <Object?>[
        <String, Object?>{'id': '1'},
      ],
    });
  });

  group('can: and filter: |', () {
    test('can: asks viewAny before the query', () async {
      Map<String, Object?> res = await run(
        client,
        '{ docsPaginate { data { id } } }',
        user: 'blind',
      );
      expect(res['data'], <String, Object?>{'docsPaginate': null});
      expect(_codes(res), <Object?>['FORBIDDEN']);
      res = await run(client, '{ docsPaginate { data { id } } }', user: null);
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
    });

    test('filter: drops rows after the count: total counts them', () async {
      Map<String, Object?> res = await run(
        client,
        '{ docsPaginate { data { title } $_info } }',
        user: 'bob',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'docsPaginate': <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'title': 'Bob doc'},
            ],
            'paginatorInfo': <String, Object?>{
              'count': 1,
              'currentPage': 1,
              // the page had 3 rows before the filter
              'firstItem': 1,
              'lastItem': 3,
              'hasMorePages': false,
              'lastPage': 1,
              'perPage': 20,
              'total': 3,
            },
          },
        },
      });
    });
  });
}
