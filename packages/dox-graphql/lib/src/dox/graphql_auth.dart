import 'dart:async';

import 'package:dox_core/dox_core.dart';

import '../errors.dart';
import '../executor.dart';
import '../schema.dart';
import '../types.dart';
import 'graphql_context.dart';

/// The login check of each GraphQL field.
///
/// Which fields need a logged-in user:
///
/// 1. A field that gives a type with `auth: true` (like
///    `@GraphQLType(auth: true)`). This also covers relations and custom
///    resolvers that give the type.
/// 2. Else, a field with `auth:` set uses it.
/// 3. Else, a field that gives a type with `auth: false` is public.
/// 4. Else, a root field (of `Query` or `Mutation`) and a field that
///    gives an object, interface or union use the default: a login when
///    `GraphQLConfig.middleware` has an [IAuthMiddleware], else public.
/// 5. Else (a scalar or enum field of a type) the field is public.
///
/// An interface or union field is also checked on the object type it
/// picks for its value: a type with `auth: true` needs a login there too.
///
/// A field that fails the check gets the error "Unauthenticated" with
/// `extensions: {code: UNAUTHENTICATED}`. Its resolver does not run.
class GraphQLAuth implements FieldGuard {
  GraphQLAuth(this._schema, {required this.loginByDefault});

  /// The error code of a field that needs a login.
  static const String unauthenticated = 'UNAUTHENTICATED';

  /// The error code of a write that a policy denies.
  static const String forbiddenCode = 'FORBIDDEN';

  final GraphQLSchema<DoxGraphQLContext> _schema;

  /// True when fields need a login by default.
  final bool loginByDefault;

  /// The error of a write that a policy denies: "Forbidden" with
  /// `extensions: {code: FORBIDDEN}`.
  static GraphQLError forbidden() => GraphQLError(
    'Forbidden',
    extensions: <String, Object?>{'code': forbiddenCode},
  );

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
  /// `auth: true` but [middleware] has no [IAuthMiddleware]: the user
  /// could never be known.
  static void checkSchema(
    GraphQLSchema<Object?> schema,
    List<Object> middleware,
  ) {
    if (logins(middleware).isNotEmpty) return;
    for (NamedType type in schema.typeMap.values) {
      if (type is! ObjectType<Object?, Object?>) continue;
      if (type.auth == true) _noLogin('type ${type.name}');
      for (Field<Object?, Object?> field in type.fields) {
        if (field.auth == true) _noLogin('field ${type.name}.${field.name}');
      }
    }
  }

  static Never _noLogin(String what) {
    throw StateError(
      'The GraphQL $what has auth: true, but GraphQLConfig.middleware has '
      'no auth middleware, so no user is ever logged in. Add the auth '
      'middleware, like `middleware: <Object>[AuthMiddleware()]`. (The '
      'create mutation of a model with `owner:` has auth: true too.)',
    );
  }

  /// The id of the logged-in user, for the `owner:` column [where] (like
  /// `Post.userId`) of a create mutation. The code that
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
    bool? typeAuth = type is ObjectType<Object?, Object?> ? type.auth : null;
    if (typeAuth == true) return true;
    bool? fieldAuth = field.auth;
    if (fieldAuth != null) return fieldAuth;
    if (typeAuth == false) return false;
    bool root =
        identical(parent, _schema.query) || identical(parent, _schema.mutation);
    if (root || type.isComposite) return loginByDefault;
    return false;
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
  /// `auth: true` needs a login, even when the field is public.
  @override
  FutureOr<GraphQLError?> checkType(
    ObjectType<Object?, Object?> type,
    Object? context,
  ) {
    if (type.auth != true || type.name.startsWith('__')) return null;
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
