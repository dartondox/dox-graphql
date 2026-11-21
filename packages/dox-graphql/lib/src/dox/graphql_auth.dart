import 'dart:async';

import 'package:dox_core/dox_core.dart';

import '../errors.dart';
import '../executor.dart';
import '../schema.dart';
import '../types.dart';
import 'graphql_context.dart';

/// The login check of each GraphQL field.
///
/// A field needs a logged-in user when it has `guard: true`, or when it
/// gives a type with `guard: true` (like `@GraphQLType(guard: true)`).
/// The type also covers relations and custom resolvers that give it,
/// and an interface or union field that picks it for its value. Every
/// other field is public.
///
/// A field that fails the check gets the error "Unauthenticated" with
/// `extensions: {code: UNAUTHENTICATED}`. Its resolver does not run.
class GraphQLAuth implements FieldGuard {
  GraphQLAuth(this._schema);

  /// The error code of a field that needs a login.
  static const String unauthenticated = 'UNAUTHENTICATED';

  /// The error code of a read or write that a policy denies.
  static const String forbiddenCode = 'FORBIDDEN';

  final GraphQLSchema<DoxGraphQLContext> _schema;

  /// The error of a read or write that a policy denies: "Forbidden" with
  /// `extensions: {code: FORBIDDEN}`.
  static GraphQLError forbidden() => GraphQLError(
    'Forbidden',
    extensions: <String, Object?>{'code': forbiddenCode},
  );

  /// The error of a field that needs a login: "Unauthenticated" with
  /// `extensions: {code: UNAUTHENTICATED}`.
  static GraphQLError unauthenticatedError() => _error();

  /// The [IAuthMiddleware]s of [middleware], in their optional form.
  static List<IAuthMiddleware> logins(List<Object> middleware) {
    return <IAuthMiddleware>[
      for (Object m in middleware)
        if (m is IAuthMiddleware) m.asOptional(),
    ];
  }

  /// [middleware] without the [IAuthMiddleware]s. They do not run on the
  /// route: the context runs them when a field needs the user.
  static List<Object> withoutLogins(List<Object> middleware) {
    return <Object>[
      for (Object m in middleware)
        if (m is! IAuthMiddleware) m,
    ];
  }

  /// Throws a [StateError] when a field or type of [schema] has
  /// `guard: true` but [middleware] has no [IAuthMiddleware]: the user
  /// could never be known.
  static void checkSchema(
    GraphQLSchema<Object?> schema,
    List<Object> middleware,
  ) {
    if (logins(middleware).isNotEmpty) return;
    for (NamedType type in schema.typeMap.values) {
      if (type is! ObjectType<Object?, Object?>) continue;
      if (type.guard) _noLogin('type ${type.name}');
      for (Field<Object?, Object?> field in type.fields) {
        if (field.guard) _noLogin('field ${type.name}.${field.name}');
      }
    }
  }

  static Never _noLogin(String what) {
    throw StateError(
      'The GraphQL $what has guard: true, but GraphQLConfig.middleware has '
      'no auth middleware, so no user is ever logged in. Add the auth '
      'middleware, like `middleware: <Object>[AuthMiddleware()]`. (A '
      '@GraphQLCreate with `owner:` has guard: true too.)',
    );
  }

  /// The id of the logged-in user, for the `owner:` column [where] (like
  /// `Post.userId`) of a `@GraphQLCreate`. The code that
  /// `dox_graphql_builder` writes calls it.
  ///
  /// A guest gets "Unauthenticated". A user with no id, or an id that is
  /// not a [T], gets an error too: a row is never saved with a null or
  /// wrong owner.
  static Future<T> ownerId<T extends Object>(
    DoxGraphQLContext context,
    String where,
  ) async {
    IAuth? auth = await context.auth();
    if (auth == null) throw _error();
    Object? id = auth.id();
    if (id is T) return id;
    throw GraphQLError(
      'The logged-in user has no $T id to set as the owner $where.',
    );
  }

  /// True when [field] of [parent] needs a logged-in user.
  bool needsLogin(
    ObjectType<Object?, Object?> parent,
    Field<Object?, Object?> field,
  ) {
    // introspection (`__schema`, `__type`, `__typename` and the fields of
    // `__Schema`, `__Type`, ...) is always public: it shows no data
    if (field.name.startsWith('__') || parent.name.startsWith('__')) {
      return false;
    }
    NamedType type = _named(field.type);
    if (type is ObjectType<Object?, Object?> && type.guard) return true;
    return field.guard;
  }

  /// The root fields and the fields that give an object, interface or
  /// union (relations): how many are public and how many need a login.
  (int public, int login) count() {
    int public = 0;
    int login = 0;
    for (NamedType type in _schema.typeMap.values) {
      if (type is! ObjectType<Object?, Object?>) continue;
      if (type.name.startsWith('__')) continue;
      bool root =
          identical(type, _schema.query) || identical(type, _schema.mutation);
      for (Field<Object?, Object?> field in type.fields) {
        if (!root && !_named(field.type).isComposite) continue;
        if (needsLogin(type, field)) {
          login++;
        } else {
          public++;
        }
      }
    }
    return (public, login);
  }

  static NamedType _named(GraphQLTypeRef type) {
    GraphQLTypeRef t = type;
    while (true) {
      switch (t) {
        case NonNullType():
          t = t.ofType;
        case ListType():
          t = t.ofType;
        case NamedType():
          return t;
      }
    }
  }

  @override
  FutureOr<GraphQLError?> check(
    ObjectType<Object?, Object?> parent,
    Field<Object?, Object?> field,
    Object? context,
  ) {
    if (!needsLogin(parent, field)) return null;
    if (context is! DoxGraphQLContext) return _error();
    return _checkUser(context);
  }

  /// A value of an interface or union field whose object type has
  /// `guard: true` needs a login, even when the field is public.
  @override
  FutureOr<GraphQLError?> checkType(
    ObjectType<Object?, Object?> type,
    Object? context,
  ) {
    if (!type.guard || type.name.startsWith('__')) return null;
    if (context is! DoxGraphQLContext) return _error();
    return _checkUser(context);
  }

  static Future<GraphQLError?> _checkUser(DoxGraphQLContext context) async {
    return await context.auth() == null ? _error() : null;
  }

  static GraphQLError _error() => GraphQLError(
    'Unauthenticated',
    extensions: <String, Object?>{'code': unauthenticated},
  );
}
