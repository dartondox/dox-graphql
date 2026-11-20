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

  test('auth: true without the auth middleware fails at start', () {
    expect(
      () => GraphQLAuth.checkSchema(loginSchema(), const <Object>[]),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('field Query.secret has auth: true'),
        ),
      ),
    );
    GraphQLAuth.checkSchema(loginSchema(), const <Object>[
      FakeLoginMiddleware(),
    ]);
  });
}
