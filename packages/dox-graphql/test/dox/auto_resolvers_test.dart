import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

import 'app.dart';

final GraphQLSchema<DoxGraphQLContext> autoSchema =
    GraphQLSchema<DoxGraphQLContext>(
      query: ObjectType<Object?, DoxGraphQLContext>(
        'Query',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          AutoField<Object?, DoxGraphQLContext>(
            'auto',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => 'a',
          ),
          Field<Object?, DoxGraphQLContext>(
            'custom',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => 'c',
          ),
        ],
      ),
    );

void main() {
  late DoxTestClient client;

  setUpAll(() async {
    Env().env = <String, String>{};
    client = await startApp(
      GraphQLConfig(schema: autoSchema, autoResolvers: false),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  test('autoResolvers: false leaves the auto fields out', () async {
    TestResponse res = await client.post(
      '/graphql',
      body: <String, Object?>{'query': '{ custom }'},
      headers: acceptJson,
    );
    expect(res.json, <String, Object?>{
      'data': <String, Object?>{'custom': 'c'},
    });
    res = await client.post(
      '/graphql',
      body: <String, Object?>{'query': '{ auto }'},
      headers: acceptJson,
    );
    expect(res.json['errors'][0]['message'], contains('auto'));
  });
}
