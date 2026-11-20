import 'package:dox_core/dox_core.dart';
import 'package:dox_graphql/dox_graphql.dart';
// TODO: use dox_core IAuthMiddleware, then drop this import.
import 'package:dox_graphql/src/dox/graphql_auth.dart' show IAuthMiddleware;

import 'app.dart';

/// A 401, like `UnAuthorizedException` of dox_auth.
class FakeUnauthorized extends IHttpException {
  FakeUnauthorized() {
    code = 401;
    errorCode = 'unauthorized';
    message = 'Authentication failed';
  }
}

/// Logs in `Bearer good-<name>`. Like the real auth middleware, it stops
/// a guest with a 401 unless it is optional.
class FakeLoginMiddleware implements IAuthMiddleware {
  const FakeLoginMiddleware({this.optional = false});

  final bool optional;

  @override
  IAuthMiddleware asOptional() => const FakeLoginMiddleware(optional: true);

  @override
  IDoxRequest handle(IDoxRequest req) {
    String token = req.header('authorization') ?? '';
    if (token.startsWith('Bearer good-')) {
      req.auth = FakeAuth(token.substring('Bearer good-'.length));
      return req;
    }
    if (optional) return req;
    throw FakeUnauthorized();
  }
}

/// How many times the `write` mutation ran.
int writes = 0;

final ObjectType<Map<String, Object?>, DoxGraphQLContext> _note =
    ObjectType<Map<String, Object?>, DoxGraphQLContext>(
      'Note',
      fields: () => <Field<Map<String, Object?>, DoxGraphQLContext>>[
        Field<Map<String, Object?>, DoxGraphQLContext>('title', graphqlString),
        Field<Map<String, Object?>, DoxGraphQLContext>(
          'secretBody',
          graphqlString,
          auth: true,
        ),
      ],
    );

final GraphQLSchema<DoxGraphQLContext> authSchema =
    GraphQLSchema<DoxGraphQLContext>(
      query: ObjectType<Object?, DoxGraphQLContext>(
        'Query',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          Field<Object?, DoxGraphQLContext>(
            'open',
            graphqlString,
            auth: false,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => 'hi',
          ),
          Field<Object?, DoxGraphQLContext>(
            'me',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                info.context.user<String>(),
          ),
          Field<Object?, DoxGraphQLContext>(
            'count',
            graphqlInt.nonNull,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => 1,
          ),
          AutoField<Object?, DoxGraphQLContext>(
            'autoOpen',
            graphqlString,
            auth: false,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => 'a',
          ),
          Field<Object?, DoxGraphQLContext>(
            'note',
            _note,
            auth: false,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                <String, Object?>{'title': 't', 'secretBody': 'b'},
          ),
        ],
      ),
      mutation: ObjectType<Object?, DoxGraphQLContext>(
        'Mutation',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          Field<Object?, DoxGraphQLContext>(
            'write',
            graphqlInt,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                ++writes,
          ),
        ],
      ),
    );

/// A root field with no `auth:`.
final GraphQLSchema<DoxGraphQLContext> publicSchema =
    GraphQLSchema<DoxGraphQLContext>(
      query: ObjectType<Object?, DoxGraphQLContext>(
        'Query',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          Field<Object?, DoxGraphQLContext>(
            'hello',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => 'w',
          ),
        ],
      ),
    );

/// A root field with `auth: true`.
GraphQLSchema<DoxGraphQLContext> loginSchema() {
  return GraphQLSchema<DoxGraphQLContext>(
    query: ObjectType<Object?, DoxGraphQLContext>(
      'Query',
      fields: () => <Field<Object?, DoxGraphQLContext>>[
        Field<Object?, DoxGraphQLContext>(
          'secret',
          graphqlString,
          auth: true,
          resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => 's',
        ),
      ],
    ),
  );
}
