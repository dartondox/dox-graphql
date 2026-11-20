import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
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
      expect(res['data'], isNull);
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
  });
}
