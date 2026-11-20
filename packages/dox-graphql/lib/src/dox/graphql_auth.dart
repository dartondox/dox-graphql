import 'package:dox_core/dox_core.dart';

import '../errors.dart';
import '../executor.dart';
import '../schema.dart';
import '../types.dart';
import 'graphql_context.dart';

// TODO: use dox_core IAuthMiddleware. This is a copy until dox_core has
// it; then delete this class and import it from dox_core.
/// A middleware that logs a user in, like `AuthMiddleware` of dox_auth.
abstract class IAuthMiddleware implements IDoxMiddleware {
  /// Same guards, but lets guests through: a good login sets
  /// `req.auth`, no login goes on with `req.auth` null.
  IAuthMiddleware asOptional();
}

/// The login check of each GraphQL field.
///
/// A field needs a logged-in user when its `auth` is true. When it is
/// null, a root field (of `Query` or `Mutation`) needs a login only when
/// `GraphQLConfig.middleware` has an [IAuthMiddleware]. A field of
/// another type is public unless its `auth` is true, so a public root
/// field can give its whole object.
///
/// A field that fails the check gets the error "Unauthenticated" with
/// `extensions: {code: UNAUTHENTICATED}`. Its resolver does not run.
class GraphQLAuth implements FieldGuard {
  GraphQLAuth(this._schema, {required this.loginByDefault});

  /// The error code of a field that needs a login.
  static const String unauthenticated = 'UNAUTHENTICATED';

  final GraphQLSchema<DoxGraphQLContext> _schema;

  /// True when root fields need a login by default.
  final bool loginByDefault;

  /// True when [middleware] has an [IAuthMiddleware].
  static bool hasAuth(List<Object> middleware) {
    for (Object m in middleware) {
      if (m is IAuthMiddleware) return true;
    }
    return false;
  }

  /// [middleware] with each [IAuthMiddleware] made optional, so a guest
  /// or a bad token still gets to the fields. Each field checks the login.
  static List<Object> optional(List<Object> middleware) {
    return <Object>[
      for (Object m in middleware)
        if (m is IAuthMiddleware) m.asOptional() else m,
    ];
  }

  /// Throws a [StateError] when a field of [schema] has `auth: true` but
  /// [middleware] has no [IAuthMiddleware]: the user could never be known.
  static void checkSchema(
    GraphQLSchema<Object?> schema,
    List<Object> middleware,
  ) {
    if (hasAuth(middleware)) return;
    for (NamedType type in schema.typeMap.values) {
      if (type is! ObjectType<Object?, Object?>) continue;
      for (Field<Object?, Object?> field in type.fields) {
        if (field.auth != true) continue;
        throw StateError(
          'The GraphQL field ${type.name}.${field.name} has auth: true, but '
          'GraphQLConfig.middleware has no auth middleware, so no user is '
          'ever logged in. Add the auth middleware, like '
          '`middleware: <Object>[AuthMiddleware()]`.',
        );
      }
    }
  }

  @override
  GraphQLError? check(
    ObjectType<Object?, Object?> parent,
    Field<Object?, Object?> field,
    Object? context,
  ) {
    if (field.name.startsWith('__')) return null;
    bool root =
        identical(parent, _schema.query) || identical(parent, _schema.mutation);
    bool needed = field.auth ?? (root && loginByDefault);
    if (!needed) return null;
    if (context is DoxGraphQLContext && context.auth != null) return null;
    return GraphQLError(
      'Unauthenticated',
      extensions: <String, Object?>{'code': unauthenticated},
    );
  }
}
