import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

import 'app.dart';
import 'auth_app.dart';

void main() {
  late DoxTestClient client;

  setUpAll(() async {
    Env().env = <String, String>{};
    client = await startApp(GraphQLConfig(schema: publicSchema));
  });

  tearDownAll(() async {
    await client.close();
  });

  test('without the auth middleware, fields are public', () async {
    TestResponse res = await client.post(
      '/graphql',
      body: <String, Object?>{'query': '{ hello }'},
      headers: acceptJson,
    );
    expect(res.json, <String, Object?>{
      'data': <String, Object?>{'hello': 'w'},
    });
  });

  test('guard: true without the auth middleware fails at start', () {
    expect(
      () => GraphQLAuth.checkSchema(loginSchema(), const <Object>[]),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('field Query.secret has guard: true'),
        ),
      ),
    );
    GraphQLAuth.checkSchema(loginSchema(), const <Object>[
      FakeLoginMiddleware(),
    ]);
  });

  test('a start check that throws stops the start', () async {
    GraphQLSchema<DoxGraphQLContext> schema = GraphQLSchema<DoxGraphQLContext>(
      query: publicSchema.query,
      startChecks: <void Function()>[_failCheck],
    );
    await expectLater(
      startApp(GraphQLConfig(schema: schema)),
      throwsA(isA<StateError>()),
    );
  });
}

void _failCheck() => throw StateError('bad ability');
