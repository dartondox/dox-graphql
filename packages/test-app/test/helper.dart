import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/container.g.dart';
import 'package:dox_graphql_test_app/generated/dtos.g.dart';

/// A fake login: the user is the name in the `x-user` header.
class FakeAuth implements IAuth {
  FakeAuth(this.name);

  final String name;

  @override
  Future<void> verifyToken(IDoxRequest req) async {}

  @override
  bool isLoggedIn() => true;

  @override
  T? user<T>() => name is T ? name as T : null;

  @override
  Map<String, dynamic>? toJson() => <String, dynamic>{'name': name};
}

class FakeAuthMiddleware implements IDoxMiddleware {
  const FakeAuthMiddleware();

  @override
  IDoxRequest handle(IDoxRequest req) {
    String? name = req.header('x-user');
    if (name != null) req.auth = FakeAuth(name);
    return req;
  }
}

/// Starts the app with the generated schema.
Future<DoxTestClient> startApp(GraphQLConfig config) {
  Env().env = <String, String>{};
  return DoxTestClient.start(
    AppConfig(
      appKey: 'graphql-test-key-0123456789abcd!',
      providers: <DoxProvider>[GraphQLProvider(config)],
      container: registerContainer,
      dtos: dtos,
    ),
  );
}

/// Runs [query] and gives the JSON answer.
Future<Map<String, Object?>> run(
  DoxTestClient client,
  String query, {
  Map<String, Object?>? variables,
  Map<String, String> headers = const <String, String>{},
}) async {
  TestResponse res = await client.post(
    '/graphql',
    body: <String, Object?>{'query': query, 'variables': ?variables},
    headers: <String, String>{'accept': 'application/json', ...headers},
  );
  return res.json as Map<String, Object?>;
}
