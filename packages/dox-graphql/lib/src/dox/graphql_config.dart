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
///   middleware: <Object>[AuthMiddleware(optional: true)],
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
    this.autoResolvers = true,
    this.rules = const <ValidationRule>[],
    this.maxDepth = GraphQLExecutor.defaultMaxDepth,
    this.maxQueryLength = GraphQLExecutor.defaultMaxQueryLength,
    this.maxFields = GraphQLExecutor.defaultMaxFields,
    this.maxNodes = GraphQLExecutor.defaultMaxNodes,
    this.maxErrors = GraphQLExecutor.defaultMaxErrors,
  });

  final GraphQLSchema<DoxGraphQLContext> schema;

  /// The URL path of the endpoint. Default `/graphql`.
  final String path;

  /// Middleware of the route, after the global middleware of the app. It
  /// takes the same kinds as a Dox route: middleware objects and
  /// functions.
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

  /// The list, find, create, update and delete fields that
  /// `dox_graphql_builder` makes for models. False leaves them out, so
  /// the app has only its own `@Query` and `@Mutation` resolvers. The
  /// model types stay, for relations and resolvers.
  final bool autoResolvers;

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

  /// See `GraphQLExecutor.maxErrors`.
  final int maxErrors;
}
