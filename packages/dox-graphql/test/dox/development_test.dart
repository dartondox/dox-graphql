import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

import 'app.dart';

/// The defaults when `APP_ENV` is `development`.
void main() {
  late DoxTestClient client;

  setUpAll(() async {
    Env().env = <String, String>{'APP_ENV': 'development'};
    client = await startApp(GraphQLConfig(schema: schema));
  });

  tearDownAll(() async {
    await client.close();
  });

  test('introspection is on', () async {
    TestResponse res = await client.post(
      '/graphql',
      body: <String, Object?>{'query': '{ __schema { queryType { name } } }'},
    );
    res.expectStatus(200);
    expect(res.json['data']['__schema']['queryType']['name'], 'Query');
  });

  test('the text of an internal error is shown', () async {
    TestResponse res = await client.post(
      '/graphql',
      body: <String, Object?>{'query': '{ boom }'},
    );
    expect(res.json['errors'][0]['message'], contains('password=secret'));
  });

  test('GraphiQL is on', () async {
    TestResponse res = await client.get('/graphql', headers: acceptHtml);
    res.expectStatus(200);
    expect(res.body, contains('GraphiQL.createFetcher'));
  });
}
