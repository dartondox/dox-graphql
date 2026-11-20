import 'package:dox_core/dox_core.dart';

import '../executor.dart';
import '../schema.dart';
import 'auto_field.dart';
import 'graphql_auth.dart';
import 'graphql_config.dart';
import 'graphql_context.dart';
import 'graphql_http.dart';

/// Adds the GraphQL endpoint to a Dox app.
///
/// It builds one [GraphQLExecutor] per isolate when the app starts, puts
/// it in the Dox container, and adds the `GET` and `POST` routes at
/// `GraphQLConfig.path`.
///
/// ```dart
/// class AppGraphQLProvider extends GraphQLProvider {
///   AppGraphQLProvider() : super(graphqlConfig);
/// }
/// ```
class GraphQLProvider extends DoxProvider {
  GraphQLProvider(this.config);

  final GraphQLConfig config;

  late GraphQLHttpHandler _handler;

  @override
  void setup() {
    bool dev = Dox().config.isDevelopment;
    GraphQLSchema<DoxGraphQLContext> schema = config.autoResolvers
        ? config.schema
        : AutoField.leaveOut(config.schema);
    GraphQLAuth.checkSchema(schema, config.middleware);
    GraphQLExecutor<DoxGraphQLContext> executor =
        GraphQLExecutor<DoxGraphQLContext>(
          schema,
          introspection: config.introspection ?? dev,
          showInternalErrors: config.showInternalErrors ?? dev,
          rules: config.rules,
          maxDepth: config.maxDepth,
          maxQueryLength: config.maxQueryLength,
          maxFields: config.maxFields,
          maxNodes: config.maxNodes,
          maxErrors: config.maxErrors,
          guard: GraphQLAuth(
            schema,
            loginByDefault: GraphQLAuth.hasAuth(config.middleware),
          ),
        );
    Dox().ioc.instance<GraphQLExecutor<DoxGraphQLContext>>(executor);
    _handler = GraphQLHttpHandler(
      executor,
      graphiql: config.graphiql ?? dev,
      path: config.path,
    );
  }

  /// The routes are added here, after the `setup()` of every provider, so
  /// the global middleware that other packages add is known.
  ///
  /// The auth middleware runs in its optional form: a guest or a bad
  /// token is not stopped here. Each field checks the login instead (see
  /// [GraphQLAuth]).
  @override
  void boot() {
    Route.middleware(<dynamic>[
      ...Dox().allGlobalMiddleware,
      ...GraphQLAuth.optional(config.middleware),
    ], _addRoutes);
  }

  void _addRoutes() {
    Route.match(<String>['GET', 'POST'], config.path, _handler.handle);
  }
}
