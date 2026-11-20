import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

void main() {
  late DoxTestClient client;

  setUpAll(() async {
    await setUpDatabase();
    client = await startApp(
      GraphQLConfig(schema: graphqlSchema, autoResolvers: false),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  test(
    'autoResolvers: false leaves out the model queries and writes',
    () async {
      Map<String, Object?> res = await run(client, '{ posts { title } }');
      expect(res['errors'], isNotEmpty);
      res = await run(client, 'mutation { deletePost(id: "1") }');
      expect(res['errors'], isNotEmpty);
    },
  );

  test('the custom resolvers and the model types stay', () async {
    Map<String, Object?> res = await run(
      client,
      '{ postsWithUsers { title user { name posts { title } } } }',
    );
    expect(res['errors'], isNull);
    res = await run(
      client,
      'mutation { createBook(input: {title: "Long", authorId: 1}) { id } }',
    );
    expect(res['errors'], isNull);
  });

  test('with no auth middleware, fields are public by default', () async {
    Map<String, Object?> res = await run(client, '{ me path }', user: null);
    expect(res, <String, Object?>{
      'data': <String, Object?>{'me': null, 'path': '/graphql'},
    });
  });
}
