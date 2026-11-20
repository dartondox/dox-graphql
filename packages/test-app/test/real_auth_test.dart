import 'dart:math';

import 'package:dox_auth/dox_auth.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/app/models/user/user.model.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

/// The real `AuthMiddleware` of dox_auth, with JWT tokens and the users
/// table.
void main() {
  late DoxTestClient client;
  late String token;

  setUpAll(() async {
    await setUpDatabase();
    // a new key for each run: a fixed key in a public repo is public
    String secret = List<String>.generate(
      32,
      (int i) => Random.secure().nextInt(36).toRadixString(36),
    ).join();
    Auth.initialize(
      AuthConfig(
        defaultGuard: 'api',
        guards: <String, AuthGuard>{
          'api': AuthGuard(
            driver: JwtAuthDriver(secret: SecretKey(secret)),
            provider: AuthProvider(model: () => User()),
          ),
        },
      ),
    );
    User ada = (await User().find(1))!;
    token = Auth().login(ada)!;
    client = await startApp(
      GraphQLConfig(
        schema: graphqlSchema,
        middleware: <Object>[AuthMiddleware()],
      ),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  tearDown(stopCounting);

  Future<Map<String, Object?>> send(String query, {String? bearer}) {
    return run(
      client,
      query,
      user: null,
      headers: <String, String>{'authorization': 'Bearer ${bearer ?? ''}'},
    );
  }

  const String query = '{ post(id: "1") { title user { name } } }';

  test('a guest gets UNAUTHENTICATED on the protected field', () async {
    Map<String, Object?> res = await run(client, query, user: null);
    expect(res['data'], <String, Object?>{
      'post': <String, Object?>{'title': 'Hello GraphQL', 'user': null},
    });
    List<Object?> errors = res['errors'] as List<Object?>;
    expect(
      ((errors.single as Map<String, Object?>)['extensions']
          as Map<String, Object?>)['code'],
      'UNAUTHENTICATED',
    );
  });

  test('a valid token gets the data', () async {
    Map<String, Object?> res = await send(query, bearer: token);
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'post': <String, Object?>{
          'title': 'Hello GraphQL',
          'user': <String, Object?>{'name': 'Ada'},
        },
      },
    });
  });

  test('a bad token is a guest, not a failed request', () async {
    Map<String, Object?> res = await send(query, bearer: 'not-a-token');
    expect(res['data'], <String, Object?>{
      'post': <String, Object?>{'title': 'Hello GraphQL', 'user': null},
    });
    expect(res['errors'], hasLength(1));
  });

  test('a public request does no token lookup', () async {
    startCounting();
    Map<String, Object?> res = await send(
      '{ article(id: "1") { title } }',
      bearer: token,
    );
    expect(res['errors'], isNull);
    expect(queries.where((String sql) => sql.contains('users')), isEmpty);
    expect(queries, isNotEmpty);

    queries.clear();
    await send(query, bearer: token);
    expect(queries.where((String sql) => sql.contains('users')), isNotEmpty);
  });
}
