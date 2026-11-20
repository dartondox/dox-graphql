import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';

/// A service the resolvers get from the Dox container.
class Greeter {
  String greet(String name) => 'hello $name';
}

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

/// Keeps the errors the app reports.
class RecordingHandler extends ExceptionHandler {
  const RecordingHandler();

  static final List<Object> reported = <Object>[];

  @override
  void report(Object error, StackTrace stackTrace) => reported.add(error);
}

/// The keys of each batch of the `name` loader.
final List<List<int>> batches = <List<int>>[];

Future<List<String?>> loadNames(List<int> ids) async {
  batches.add(ids);
  return <String?>[for (int id in ids) 'user$id'];
}

DataLoader<int, String> _names(ResolveInfo<DoxGraphQLContext> info) {
  return info.context.loader<int, String>(
    'names',
    () => DataLoader<int, String>(loadNames),
  );
}

final GraphQLSchema<DoxGraphQLContext> schema =
    GraphQLSchema<DoxGraphQLContext>(
      query: ObjectType<Object?, DoxGraphQLContext>(
        'Query',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          Field<Object?, DoxGraphQLContext>(
            'hello',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                'world',
          ),
          Field<Object?, DoxGraphQLContext>(
            'echo',
            graphqlString,
            args: <Argument>[Argument('text', graphqlString)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                info.args.get<String>('text'),
          ),
          Field<Object?, DoxGraphQLContext>(
            'me',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                info.context.user<String>(),
          ),
          Field<Object?, DoxGraphQLContext>(
            'path',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                info.context.request.uri.path,
          ),
          Field<Object?, DoxGraphQLContext>(
            'greet',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                info.context.make<Greeter>().greet('ann'),
          ),
          Field<Object?, DoxGraphQLContext>(
            'name',
            graphqlString,
            args: <Argument>[Argument('id', graphqlInt.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _names(info).load(info.args.get<int>('id')!),
          ),
          Field<Object?, DoxGraphQLContext>(
            'boom',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                throw StateError('db.internal password=secret'),
          ),
        ],
      ),
      mutation: ObjectType<Object?, DoxGraphQLContext>(
        'Mutation',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          Field<Object?, DoxGraphQLContext>(
            'double',
            graphqlInt,
            args: <Argument>[Argument('n', graphqlInt.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                info.args.get<int>('n')! * 2,
          ),
        ],
      ),
    );

void registerTestContainer(IocContainer c) {
  c.singleton<Greeter>((IocContainer c) => Greeter());
}

/// Starts a Dox app with the GraphQL provider of [config]. Set the env
/// (`Env().env`) before, for the defaults that depend on `APP_ENV`.
Future<DoxTestClient> startApp(GraphQLConfig config) {
  return DoxTestClient.start(
    AppConfig(
      appKey: 'graphql-test-key-0123456789abcd!',
      providers: <DoxProvider>[GraphQLProvider(config)],
      container: registerTestContainer,
      exceptionHandler: const RecordingHandler(),
    ),
  );
}

const Map<String, String> acceptNew = <String, String>{
  'accept': 'application/graphql-response+json, application/json;q=0.9',
};

const Map<String, String> acceptJson = <String, String>{
  'accept': 'application/json',
};

const Map<String, String> acceptHtml = <String, String>{
  'accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
};
