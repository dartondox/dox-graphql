import 'package:dox_auth/dox_auth.dart' show Gate;
import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/container.g.dart';
import 'package:dox_graphql_test_app/generated/dtos.g.dart';
import 'package:dox_graphql_test_app/app/models/article/article.model.dart';
import 'package:dox_graphql_test_app/app/models/member/member.model.dart';
import 'package:dox_graphql_test_app/app/models/note/note.model.dart';
import 'package:dox_graphql_test_app/app/models/post/post.model.dart';
import 'package:dox_graphql_test_app/app/policies/note_policy.dart';
import 'package:dox_graphql_test_app/app/policies/policies.dart';

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

/// A 401, like `UnAuthorizedException` of dox_auth.
class FakeUnauthorized extends IHttpException {
  FakeUnauthorized() {
    code = 401;
    errorCode = 'unauthorized';
    message = 'Authentication failed';
  }
}

/// Logs in the user named in the `x-user` header. The name `bad` is a bad
/// token. Like the real auth middleware, it stops a guest with a 401
/// unless it is optional.
class FakeAuthMiddleware implements IAuthMiddleware {
  const FakeAuthMiddleware({this.optional = false});

  final bool optional;

  @override
  IAuthMiddleware asOptional() => const FakeAuthMiddleware(optional: true);

  /// How many times a login ran.
  static int runs = 0;

  @override
  IDoxRequest handle(IDoxRequest req) {
    runs++;
    String? name = req.header('x-user');
    if (name != null && name != 'bad') {
      req.auth = FakeAuth(name);
      return req;
    }
    if (optional) return req;
    throw FakeUnauthorized();
  }
}

/// Starts the app with the generated schema.
Future<DoxTestClient> startApp(GraphQLConfig config) {
  Env().env = <String, String>{};
  Gate.policy<Post>(PostPolicy());
  Gate.policy<Member>(MemberPolicy());
  Gate.policy<Article>(ArticlePolicy());
  Gate.policy<Note>(NotePolicy());
  return DoxTestClient.start(
    AppConfig(
      appKey: 'graphql-test-key-0123456789abcd!',
      providers: <DoxProvider>[GraphQLProvider(config)],
      container: registerContainer,
      dtos: dtos,
    ),
  );
}

/// Runs [query] as [user] and gives the JSON answer. A null [user] is a
/// guest.
Future<Map<String, Object?>> run(
  DoxTestClient client,
  String query, {
  Map<String, Object?>? variables,
  Map<String, String> headers = const <String, String>{},
  String? user = 'tester',
}) async {
  TestResponse res = await client.post(
    '/graphql',
    body: <String, Object?>{'query': query, 'variables': ?variables},
    headers: <String, String>{
      'accept': 'application/json',
      'x-user': ?user,
      ...headers,
    },
  );
  return res.json as Map<String, Object?>;
}
