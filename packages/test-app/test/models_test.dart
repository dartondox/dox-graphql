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
  Map<String, Object?> ext = error['extensions'] as Map<String, Object?>;
  expect(ext['code'], 'VALIDATION_FAILED');
  return ext['fields'] as Map<String, Object?>;
}

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

  group('reads |', () {
    test('the quick start query, with no N+1', () async {
      startCounting();
      Map<String, Object?> res = await run(
        client,
        '{ posts(limit: 10) { title user { name } comments { body } } }',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'posts': <Object?>[
            <String, Object?>{
              'title': 'Hello GraphQL',
              'user': <String, Object?>{'name': 'Ada'},
              'comments': <Object?>[
                <String, Object?>{'body': 'Nice post'},
                <String, Object?>{'body': 'Thanks'},
              ],
            },
            <String, Object?>{
              'title': 'Second',
              'user': <String, Object?>{'name': 'Bob'},
              'comments': <Object?>[],
            },
            <String, Object?>{
              'title': 'Third',
              'user': <String, Object?>{'name': 'Ada'},
              'comments': <Object?>[
                <String, Object?>{'body': 'Ok'},
              ],
            },
          ],
        },
      });
      // the posts, then one query for all users and one for all comments
      expect(queries, hasLength(3));
    });

    test('nested relations: one query per relation and level', () async {
      startCounting();
      Map<String, Object?> res = await run(
        client,
        '{ users { name posts { title comments { body post { title } } } } }',
      );
      expect(res['errors'], isNull);
      expect(queries, hasLength(4));
    });

    test('a preloaded relation runs no query', () async {
      startCounting();
      Map<String, Object?> res = await run(
        client,
        '{ postsWithUsers { title user { name } } }',
      );
      expect(
        (res['data'] as Map<String, Object?>)['postsWithUsers'],
        hasLength(3),
      );
      // the posts and the preload of the users, nothing more
      expect(queries, hasLength(2));
    });

    test('id is an ID, and find takes it as text', () async {
      Map<String, Object?> res = await run(
        client,
        '{ post(id: "2") { id title status excerpt userId } }',
      );
      expect(res['data'], <String, Object?>{
        'post': <String, Object?>{
          'id': '2',
          'title': 'Second',
          'status': 'draft',
          'excerpt': 'Hi',
          'userId': 2,
        },
      });
    });

    test('find gives null for a missing or bad id', () async {
      Map<String, Object?> res = await run(
        client,
        '{ a: post(id: "999") { id } b: post(id: "abc") { id } }',
      );
      expect(res['data'], <String, Object?>{'a': null, 'b': null});
    });

    test('limit and offset', () async {
      Map<String, Object?> res = await run(
        client,
        '{ posts(limit: 1, offset: 1) { title } }',
      );
      expect(res['data'], <String, Object?>{
        'posts': <Object?>[
          <String, Object?>{'title': 'Second'},
        ],
      });
    });

    test('a limit above 100 is an error', () async {
      Map<String, Object?> res = await run(
        client,
        '{ posts(limit: 101) { title } }',
      );
      expect(res['data'], <String, Object?>{'posts': null});
      expect(
        ((res['errors'] as List<Object?>).single
            as Map<String, Object?>)['message'],
        '"limit" can be at most 100.',
      );
    });

    test('hidden and @GraphQLIgnore fields are not in the type', () async {
      Map<String, Object?> res = await run(client, '{ users { password } }');
      expect(res['errors'], isNotEmpty);
      res = await run(client, '{ posts { internalNote } }');
      expect(res['errors'], isNotEmpty);
    });

    test('queries: false gives no root query, the relation stays', () async {
      Map<String, Object?> res = await run(client, '{ comments { body } }');
      expect(res['errors'], isNotEmpty);
      res = await run(client, '{ comment(id: "1") { body } }');
      expect(res['errors'], isNotEmpty);
      res = await run(client, '{ post(id: "1") { comments { body } } }');
      expect(res['errors'], isNull);
    });
  });

  group('writes with dto: |', () {
    test('create checks the DTO first', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { createPost(input: {title: "No"}) { id } }',
      );
      expect(res['data'], <String, Object?>{'createPost': null});
      expect(_fields(res), <String, Object?>{
        'title': 'The title is too short',
      });
      res = await run(client, 'mutation { createPost(input: {}) { id } }');
      expect(_fields(res).keys, <String>['title']);
    });

    test('only DTO fields can be set', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { createPost(input: {title: "Hack", userId: 1}) { id } }',
      );
      expect(res['data'], isNull);
      expect(res['errors'], isNotEmpty);
    });

    test('create, update and delete', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { createPost(input: {title: "New post", body: "Body", '
        'status: published}) { id title body status userId } }',
      );
      Map<String, Object?> created =
          (res['data'] as Map<String, Object?>)['createPost']
              as Map<String, Object?>;
      expect(created['title'], 'New post');
      expect(created['status'], 'published');
      expect(created['userId'], null);
      String id = created['id'] as String;

      // only the sent fields are checked and set
      res = await run(
        client,
        r'mutation U($id: ID!) { updatePost(id: $id, input: {body: "New"}) '
        '{ title body status } }',
        variables: <String, Object?>{'id': id},
      );
      expect(res['data'], <String, Object?>{
        'updatePost': <String, Object?>{
          'title': 'New post',
          'body': 'New',
          'status': 'published',
        },
      });

      res = await run(
        client,
        r'mutation U($id: ID!) { updatePost(id: $id, input: {title: "x"}) '
        '{ title } }',
        variables: <String, Object?>{'id': id},
      );
      expect(_fields(res), <String, Object?>{
        'title': 'The title is too short',
      });

      res = await run(
        client,
        r'mutation D($id: ID!) { deletePost(id: $id) }',
        variables: <String, Object?>{'id': id},
      );
      expect(res['data'], <String, Object?>{'deletePost': true});
      res = await run(
        client,
        r'mutation D($id: ID!) { deletePost(id: $id) }',
        variables: <String, Object?>{'id': id},
      );
      expect(res['data'], <String, Object?>{'deletePost': false});
    });

    test('update of a missing id gives null', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { updatePost(id: "999", input: {body: "x"}) { id } }',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{'updatePost': null},
      });
    });

    test('a model without dto: has no mutations', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { createUser(input: {}) { id } }',
      );
      expect(res['errors'], isNotEmpty);
    });
  });
}
