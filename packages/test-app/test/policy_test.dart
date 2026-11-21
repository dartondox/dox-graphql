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

/// The policy of Doc (see DocPolicy) has viewAny, view and create: the
/// reads and the create ask it. Doc 1 is ann's, doc 2 is bob's.
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

  tearDown(stopCounting);

  group('viewAny |', () {
    test('the list asks it before the query', () async {
      Map<String, Object?> res = await run(
        client,
        '{ docs { title } }',
        user: 'ann',
      );
      expect(res['errors'], isNull);
      startCounting();
      res = await run(client, '{ docs { title } }', user: 'blind');
      expect(res['data'], <String, Object?>{'docs': null});
      expect(_codes(res), <Object?>['FORBIDDEN']);
      expect(queries, isEmpty);
      res = await run(client, '{ docs { title } }', user: null);
      expect(_codes(res), <Object?>['UNAUTHENTICATED']);
    });

    test(
      'a relation to Doc is null with FORBIDDEN, the rest is kept',
      () async {
        Map<String, Object?> res = await run(
          client,
          '{ accounts { name docs { title } } }',
          user: 'blind',
        );
        expect(res['data'], <String, Object?>{
          'accounts': <Object?>[
            <String, Object?>{'name': 'main', 'docs': null},
          ],
        });
        expect(_codes(res), <Object?>['FORBIDDEN']);
      },
    );
  });

  group('view on lists and relations |', () {
    test('Bob doc is not visible to ann through any path', () async {
      Map<String, Object?> res = await run(
        client,
        '{ docs { title parent { title } } '
        'accounts { docs { title parent { title } } } }',
        user: 'ann',
      );
      // the list and the relations drop what `view` denies, with no
      // error; the single relation to Bob doc is null
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'docs': <Object?>[
            <String, Object?>{'title': 'Ann doc', 'parent': null},
            <String, Object?>{
              'title': 'Ann note',
              'parent': <String, Object?>{'title': 'Ann doc'},
            },
          ],
          'accounts': <Object?>[
            <String, Object?>{
              'docs': <Object?>[
                <String, Object?>{'title': 'Ann doc', 'parent': null},
              ],
            },
          ],
        },
      });
      expect(res.toString(), isNot(contains('Bob doc')));
    });

    test('a relation with no row is null, with no error', () async {
      // Bob doc has no parent, and `parent` is a `late` field
      Map<String, Object?> res = await run(
        client,
        '{ docs { title parent { title } } }',
        user: 'bob',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'docs': <Object?>[
            <String, Object?>{'title': 'Bob doc', 'parent': null},
          ],
        },
      });
    });

    test('view works through a HasOne relation too', () async {
      // the child of Bob doc is Ann doc: bob may not view it
      Map<String, Object?> res = await run(
        client,
        '{ docs { title child { title } } }',
        user: 'bob',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'docs': <Object?>[
            <String, Object?>{'title': 'Bob doc', 'child': null},
          ],
        },
      });
      res = await run(
        client,
        '{ docs { title child { title } } }',
        user: 'ann',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'docs': <Object?>[
            <String, Object?>{
              'title': 'Ann doc',
              'child': <String, Object?>{'title': 'Ann note'},
            },
            <String, Object?>{'title': 'Ann note', 'child': null},
          ],
        },
      });
    });

    test('a list can give fewer rows than limit', () async {
      Map<String, Object?> res = await run(
        client,
        '{ docs(limit: 2) { title } }',
        user: 'bob',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'docs': <Object?>[
            <String, Object?>{'title': 'Bob doc'},
          ],
        },
      });
    });
  });

  group('view |', () {
    test('find gives the row to its owner', () async {
      Map<String, Object?> res = await run(
        client,
        '{ doc(id: "1") { title } }',
        user: 'ann',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'doc': <String, Object?>{'title': 'Ann doc'},
        },
      });
    });

    test(
      'a denied user gets FORBIDDEN for an existing and a missing id',
      () async {
        for (String id in <String>['2', '999']) {
          Map<String, Object?> res = await run(
            client,
            '{ doc(id: "$id") { title } }',
            user: 'ann',
          );
          expect(res['data'], <String, Object?>{'doc': null}, reason: id);
          expect(_codes(res), <Object?>['FORBIDDEN'], reason: id);
        }
      },
    );

    test('a guest gets UNAUTHENTICATED before the lookup', () async {
      startCounting();
      for (String id in <String>['1', '999']) {
        Map<String, Object?> res = await run(
          client,
          '{ doc(id: "$id") { title } }',
          user: null,
        );
        expect(_codes(res), <Object?>['UNAUTHENTICATED'], reason: id);
      }
      expect(queries, isEmpty);
    });
  });

  group('create |', () {
    Future<int> count() => QueryBuilder.table('docs').count();

    test('a user the policy denies saves no row', () async {
      int before = await count();
      Map<String, Object?> res = await run(
        client,
        'mutation { createDoc(input: {title: "Mine"}) { id } }',
        user: 'intruder',
      );
      expect(res['data'], <String, Object?>{'createDoc': null});
      expect(_codes(res), <Object?>['FORBIDDEN']);
      expect(await count(), before);
    });

    test('an allowed user saves it', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { createDoc(input: {title: "New"}) { title } }',
        user: 'ann',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'createDoc': <String, Object?>{'title': 'New'},
        },
      });
    });
  });

  group('update and delete of a missing id |', () {
    test('a guest gets the same answer, with no lookup', () async {
      startCounting();
      for (String id in <String>['1', '999']) {
        Map<String, Object?> res = await run(
          client,
          'mutation { updateDoc(id: "$id", input: {title: "x"}) { id } }',
          user: null,
        );
        expect(res['data'], <String, Object?>{'updateDoc': null}, reason: id);
        expect(_codes(res), <Object?>['UNAUTHENTICATED'], reason: id);
        res = await run(
          client,
          'mutation { deleteDoc(id: "$id") }',
          user: null,
        );
        expect(res['data'], <String, Object?>{'deleteDoc': null}, reason: id);
        expect(_codes(res), <Object?>['UNAUTHENTICATED'], reason: id);
      }
      expect(queries, isEmpty);
    });

    test('a denied user gets FORBIDDEN for both', () async {
      for (String id in <String>['2', '999']) {
        Map<String, Object?> res = await run(
          client,
          'mutation { updateDoc(id: "$id", input: {title: "x"}) { id } }',
          user: 'ann',
        );
        expect(_codes(res), <Object?>['FORBIDDEN'], reason: id);
        res = await run(
          client,
          'mutation { deleteDoc(id: "$id") }',
          user: 'ann',
        );
        expect(_codes(res), <Object?>['FORBIDDEN'], reason: id);
      }
    });

    test('a policy that allows a blank row gives null and false', () async {
      // PostPolicy allows every user but `intruder`
      Map<String, Object?> res = await run(
        client,
        'mutation { u: updatePost(id: "999", input: {title: "x"}) { id } '
        'd: deletePost(id: "999") }',
        user: 'ann',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{'u': null, 'd': false},
      });
      res = await run(
        client,
        'mutation { deletePost(id: "999") }',
        user: 'intruder',
      );
      expect(_codes(res), <Object?>['FORBIDDEN']);
    });
  });
}
