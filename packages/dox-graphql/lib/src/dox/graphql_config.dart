import '../executor.dart';
import '../schema.dart';
import '../validation.dart';
import 'graphql_context.dart';

/// The settings of the GraphQL endpoint. Make it in the `config` folder of
/// the app and give it to `GraphQLProvider`.
///
/// ```dart
/// GraphQLConfig graphqlConfig = GraphQLConfig(
///   schema: schema,
///   middleware: <Object>[AuthMiddleware()],
/// );
/// ```
class GraphQLConfig {
  const GraphQLConfig({
    required this.schema,
    this.path = '/graphql',
    this.middleware = const <Object>[],
    this.introspection,
    this.showInternalErrors,
    this.graphiql,
    this.rules = const <ValidationRule>[],
    this.maxDepth = GraphQLExecutor.defaultMaxDepth,
    this.maxQueryLength = GraphQLExecutor.defaultMaxQueryLength,
    this.maxFields = GraphQLExecutor.defaultMaxFields,
    this.maxNodes = GraphQLExecutor.defaultMaxNodes,
    this.maxRootFields = GraphQLExecutor.defaultMaxRootFields,
    this.maxRelationRows = defaultMaxRelationRows,
    this.maxErrors = GraphQLExecutor.defaultMaxErrors,
  });

  final GraphQLSchema<DoxGraphQLContext> schema;

  /// The URL path of the endpoint. Default `/graphql`.
  final String path;

  /// Middleware of the route, after the global middleware of the app. It
  /// takes the same kinds as a Dox route: middleware objects and
  /// functions.
  ///
  /// The auth middleware (`AuthMiddleware()` of dox_auth) here is how
  /// the user is read. It runs only when a field needs the user (a
  /// `guard: true` or a `can:`). Every field is public unless it has
  /// `guard: true`, so a field with `guard: true` needs it here. The auth
  /// middleware never stops the request: a guest or a bad token goes on
  /// with no user, and each field that needs a login fails with
  /// "Unauthenticated" (code `UNAUTHENTICATED`). The other fields still
  /// give their data.
  final List<Object> middleware;

  /// `__schema` and `__type` queries. Null (default): on when `APP_ENV`
  /// is `development`, else off.
  final bool? introspection;

  /// Send the real text of an error that a resolver throws. Null
  /// (default): on when `APP_ENV` is `development`, else off. Off, the
  /// client gets "Internal server error"; the real error is always
  /// reported to the `ExceptionHandler` of the app.
  final bool? showInternalErrors;

  /// The GraphiQL page at [path], for a browser. Null (default): on when
  /// `APP_ENV` is `development`, else off.
  final bool? graphiql;

  /// Extra validation rules, run after the rules of the spec.
  final List<ValidationRule> rules;

  /// See `GraphQLExecutor.maxDepth`.
  final int maxDepth;

  /// See `GraphQLExecutor.maxQueryLength`.
  final int maxQueryLength;

  /// See `GraphQLExecutor.maxFields`.
  final int maxFields;

  /// See `GraphQLExecutor.maxNodes`.
  final int maxNodes;

  /// See `GraphQLExecutor.maxRootFields`.
  final int maxRootFields;

  /// The default of [maxRelationRows]: 50,000.
  static const int defaultMaxRelationRows = 50000;

  /// The most rows one list relation of a model (like `Post.comments`)
  /// loads in one batch. A batch is all parents of the request at one
  /// level, so `posts(limit: 100) { comments }` reads the comments of 100
  /// posts in one query. The query has `LIMIT maxRelationRows + 1`: more
  /// rows give an error, and the table is never read whole.
  final int maxRelationRows;

  /// See `GraphQLExecutor.maxErrors`.
  final int maxErrors;
}
