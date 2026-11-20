import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

import 'app.dart';

/// The defaults when `APP_ENV` is not `development`.
void main() {
  late DoxTestClient client;

  setUpAll(() async {
    Env().env = <String, String>{'APP_ENV': 'production'};
    client = await startApp(GraphQLConfig(schema: schema));
  });

  tearDownAll(() async {
    await client.close();
  });

  test('the path is /graphql', () async {
    TestResponse res = await client.post(
      '/graphql',
      body: <String, Object?>{'query': '{ hello }'},
    );
    res.expectStatus(200);
  });

  test('introspection is off', () async {
    TestResponse res = await client.post(
      '/graphql',
      body: <String, Object?>{'query': '{ __schema { types { name } } }'},
      headers: acceptNew,
    );
    res.expectStatus(400);
    expect(res.json['errors'][0]['message'], contains('introspection'));
  });

  test('the text of an internal error is hidden', () async {
    TestResponse res = await client.post(
      '/graphql',
      body: <String, Object?>{'query': '{ boom }'},
    );
    expect(res.json['errors'][0]['message'], 'Internal server error');
  });

  test('GraphiQL is off', () async {
    TestResponse res = await client.get('/graphql', headers: acceptHtml);
    res.expectStatus(400);
    expect(res.body, isNot(contains('graphiql')));
  });
}
