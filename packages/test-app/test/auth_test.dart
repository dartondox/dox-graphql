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

  group('auth middleware in the config |', () {
    test('a guest gets UNAUTHENTICATED on a default field', () async {
      TestResponse res = await client.post(
        '/graphql',
        body: <String, Object?>{'query': '{ me }'},
        headers: <String, String>{'accept': 'application/json'},
      );
      expect(res.status, 200);
      expect(res.json['data'], <String, Object?>{'me': null});
      expect(res.json['errors'][0]['message'], 'Unauthenticated');
      expect(_codes(res.json as Map<String, Object?>), <Object?>[
        'UNAUTHENTICATED',
      ]);
    });

    test('a logged-in user gets the data', () async {
      Map<String, Object?> res = await run(client, '{ me }', user: 'ann');
      expect(res, <String, Object?>{
        'data': <String, Object?>{'me': 'ann'},
      });
    });

    test('@GraphQLQuery(auth: false) is public', () async {
      Map<String, Object?> res = await run(client, '{ path }', user: null);
      expect(res, <String, Object?>{
        'data': <String, Object?>{'path': '/graphql'},
      });
    });

    test('a bad token does not fail the whole request', () async {
      Map<String, Object?> res = await run(client, '{ path me }', user: 'bad');
      expect(res['data'], <String, Object?>{'path': '/graphql', 'me': null});
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
    });

    test('a mixed request gives partial data', () async {
      Map<String, Object?> res = await run(
        client,
        '{ article(id: "1") { title } member(id: "1") { name } }',
        user: null,
      );
      expect(res['data'], <String, Object?>{
        'article': <String, Object?>{'title': 'Kept'},
        'member': null,
      });
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
    });

    test('@GraphQLType(auth: true) guards the model writes', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { deleteMember(id: "2") }',
        user: null,
      );
      expect(res['data'], <String, Object?>{'deleteMember': null});
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
      res = await run(client, '{ member(id: "2") { name } }');
      expect(res['data'], <String, Object?>{
        'member': <String, Object?>{'name': 'bob'},
      });

      res = await run(client, 'mutation { deleteMember(id: "2") }');
      expect(res, <String, Object?>{
        'data': <String, Object?>{'deleteMember': true},
      });
    });

    test('@GraphQLType(auth: false) model queries are public', () async {
      Map<String, Object?> res = await run(
        client,
        '{ article(id: "1") { title } }',
        user: null,
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'article': <String, Object?>{'title': 'Kept'},
        },
      });
    });

    test('a protected type is protected in a relation too', () async {
      Map<String, Object?> res = await run(
        client,
        '{ post(id: "1") { title user { name } } }',
        user: null,
      );
      expect(res['data'], <String, Object?>{
        'post': <String, Object?>{'title': 'Hello GraphQL', 'user': null},
      });
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
      res = await run(client, '{ post(id: "1") { user { name } } }');
      expect(res['data'], <String, Object?>{
        'post': <String, Object?>{
          'user': <String, Object?>{'name': 'Ada'},
        },
      });
    });

    test('a guest keeps the sibling fields of a refused relation', () async {
      // Comment needs a login by default: only `comments` is null
      Map<String, Object?> res = await run(
        client,
        '{ post(id: "1") { title comments { id } } }',
        user: null,
      );
      expect(res['data'], <String, Object?>{
        'post': <String, Object?>{'title': 'Hello GraphQL', 'comments': null},
      });
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
    });

    test('a guest keeps a public root field next to an auto list', () async {
      Map<String, Object?> res = await run(
        client,
        '{ path users { id } }',
        user: null,
      );
      expect(res['data'], <String, Object?>{'path': '/graphql', 'users': null});
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
    });

    test('a refused root field is null, the other root fields stay', () async {
      // `books` gives a type that needs a login by default
      Map<String, Object?> res = await run(
        client,
        '{ path books { id } }',
        user: null,
      );
      expect(res['data'], <String, Object?>{'path': '/graphql', 'books': null});
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
    });

    test('a request that does not need the user runs no login', () async {
      FakeAuthMiddleware.runs = 0;
      await run(client, '{ path article(id: "1") { title } }');
      expect(FakeAuthMiddleware.runs, 0);
      Map<String, Object?> res = await run(client, '{ me a: me b: me }');
      expect(res['data'], <String, Object?>{
        'me': 'tester',
        'a': 'tester',
        'b': 'tester',
      });
      expect(FakeAuthMiddleware.runs, 1);
    });

    test('the policy guards update and delete', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { updatePost(id: "2", input: {title: "Hacked"}) { id } }',
        user: 'intruder',
      );
      expect(res['data'], <String, Object?>{'updatePost': null});
      expect(res['errors'], <Object?>[
        <String, Object?>{
          'message': 'Forbidden',
          'locations': <Object?>[
            <String, Object?>{'line': 1, 'column': 12},
          ],
          'path': <Object?>['updatePost'],
          'extensions': <String, Object?>{'code': 'FORBIDDEN'},
        },
      ]);
      res = await run(
        client,
        'mutation { deletePost(id: "2") }',
        user: 'intruder',
      );
      expect(res['data'], <String, Object?>{'deletePost': null});
      expect(_codes(res), <Object?>['FORBIDDEN']);
      res = await run(client, '{ post(id: "2") { title } }', user: null);
      expect(res['data'], <String, Object?>{
        'post': <String, Object?>{'title': 'Second'},
      });
    });

    test('owner: a user with no id saves no row', () async {
      // FakeAuth has no id()
      Map<String, Object?> res = await run(
        client,
        'mutation { createNote(input: {title: "x"}) { id } }',
      );
      expect(res['data'], <String, Object?>{'createNote': null});
      expect(
        ((res['errors'] as List<Object?>).single
            as Map<String, Object?>)['message'],
        'The logged-in user has no int id to set as the owner Note.userId.',
      );
      expect(await QueryBuilder.table('notes').count(), 0);
    });
  });
}
