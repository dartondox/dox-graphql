import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

Map<String, Object?> _fields(Map<String, Object?> res) {
  List<Object?> errors = res['errors'] as List<Object?>;
  Map<String, Object?> error = errors.single as Map<String, Object?>;
  expect(error['message'], 'Validation failed');
  return (error['extensions'] as Map<String, Object?>)['fields']
      as Map<String, Object?>;
}

void main() {
  late DoxTestClient client;

  setUpAll(() async {
    await setUpDatabase();
    client = await startApp(GraphQLConfig(schema: graphqlSchema));
  });

  tearDownAll(() async {
    await client.close();
  });

  tearDown(stopCounting);

  group('relations |', () {
    test('hasOne, in one query', () async {
      startCounting();
      Map<String, Object?> res = await run(
        client,
        '{ users { name profile { bio } } }',
      );
      expect(res['data'], <String, Object?>{
        'users': <Object?>[
          <String, Object?>{
            'name': 'Ada',
            'profile': <String, Object?>{'bio': 'Ada bio'},
          },
          <String, Object?>{'name': 'Bob', 'profile': null},
        ],
      });
      expect(queries, hasLength(2));
    });

    test('manyToMany, in one query', () async {
      startCounting();
      Map<String, Object?> res = await run(
        client,
        '{ posts { title tags { name } } }',
      );
      expect(res['data'], <String, Object?>{
        'posts': <Object?>[
          <String, Object?>{
            'title': 'Hello GraphQL',
            'tags': <Object?>[
              <String, Object?>{'name': 'dart'},
              <String, Object?>{'name': 'graphql'},
            ],
          },
          <String, Object?>{
            'title': 'Second',
            'tags': <Object?>[
              <String, Object?>{'name': 'graphql'},
            ],
          },
          <String, Object?>{'title': 'Third', 'tags': <Object?>[]},
        ],
      });
      expect(queries, hasLength(2));
    });

    test('morphMany, in one query', () async {
      startCounting();
      Map<String, Object?> res = await run(
        client,
        '{ posts { title images { url } } }',
      );
      expect(res['data'], <String, Object?>{
        'posts': <Object?>[
          <String, Object?>{
            'title': 'Hello GraphQL',
            'images': <Object?>[
              <String, Object?>{'url': 'a.png'},
            ],
          },
          <String, Object?>{'title': 'Second', 'images': <Object?>[]},
          <String, Object?>{
            'title': 'Third',
            'images': <Object?>[
              <String, Object?>{'url': 'b.png'},
            ],
          },
        ],
      });
      expect(queries, hasLength(2));
    });
  });

  group('hidden and visibleFields |', () {
    test('a relation in hidden is not in the type', () async {
      Map<String, Object?> res = await run(
        client,
        '{ members { profile { bio } } }',
      );
      expect(res['data'], isNull);
      expect(res['errors'], isNotEmpty);
      res = await run(client, '{ members { secret } }');
      expect(res['errors'], isNotEmpty);
      res = await run(client, '{ member(id: "1") { name email } }');
      expect(res['data'], <String, Object?>{
        'member': <String, Object?>{'name': 'ann', 'email': 'a@x'},
      });
    });

    test('visibleFields keeps only its fields', () async {
      Map<String, Object?> res = await run(client, '{ accounts { id name } }');
      expect(res['data'], <String, Object?>{
        'accounts': <Object?>[
          <String, Object?>{'id': '1', 'name': 'main'},
        ],
      });
      res = await run(client, '{ accounts { email } }');
      expect(res['errors'], isNotEmpty);
      res = await run(client, '{ accounts { secret } }');
      expect(res['errors'], isNotEmpty);
    });
  });

  group('update checks only the sent fields |', () {
    test('a @Unique field that is not sent is not checked', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { updateMember(id: "1", input: {email: "z@x"}) '
        '{ name email } }',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'updateMember': <String, Object?>{'name': 'ann', 'email': 'z@x'},
        },
      });
    });

    test('a sent @Unique field is checked', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { updateMember(id: "1", input: {name: "bob"}) { name } }',
      );
      expect(_fields(res), <String, Object?>{'name': 'The name is taken'});
    });

    test('an old row that breaks a rule can change other fields', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { a: updateMember(id: "3", input: {email: "y@x"}) '
        '{ name email } b: updateMember(id: "4", input: {email: "w@x"}) '
        '{ name email } }',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'a': <String, Object?>{'name': 'ab', 'email': 'y@x'},
          'b': <String, Object?>{'name': null, 'email': 'w@x'},
        },
      });
    });

    test('the old row still gets errors for a sent field', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { updateMember(id: "3", input: {name: "x"}) { name } }',
      );
      expect(_fields(res), <String, Object?>{'name': 'The name is too short'});
    });
  });

  group('soft deletes |', () {
    test('list, find and relations leave out deleted rows', () async {
      startCounting();
      Map<String, Object?> res = await run(
        client,
        '{ articles { title } a: article(id: "2") { title } '
        'users { articles { title } } }',
      );
      expect(res['data'], <String, Object?>{
        'articles': <Object?>[
          <String, Object?>{'title': 'Kept'},
          <String, Object?>{'title': 'Bob'},
        ],
        'a': null,
        'users': <Object?>[
          <String, Object?>{
            'articles': <Object?>[
              <String, Object?>{'title': 'Kept'},
            ],
          },
          <String, Object?>{
            'articles': <Object?>[
              <String, Object?>{'title': 'Bob'},
            ],
          },
        ],
      });
      // articles, the find, users, and one query for all their articles
      expect(queries, hasLength(4));
    });

    test(
      'update gives null and delete gives false for a deleted row',
      () async {
        Map<String, Object?> res = await run(
          client,
          'mutation { u: updateArticle(id: "2", input: {title: "x"}) { id } '
          'd: deleteArticle(id: "2") }',
        );
        expect(res, <String, Object?>{
          'data': <String, Object?>{'u': null, 'd': false},
        });
      },
    );

    test('delete soft deletes a row', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { deleteArticle(id: "3") }',
      );
      expect(res['data'], <String, Object?>{'deleteArticle': true});
      res = await run(client, '{ article(id: "3") { title } }');
      expect(res['data'], <String, Object?>{'article': null});
    });
  });
}
