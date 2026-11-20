---
name: dox-graphql-guide
description: Use when you add or change a GraphQL API in a Dox (Dart) app with dox_graphql, dox_graphql_builder and dox_graphql_orm. Covers dox add graphql, GraphQLConfig and its limits, @GraphQLType on models and plain classes, the automatic list, find, create, update and delete fields, @GraphQLQuery, @GraphQLMutation and @ResolveField resolvers, login rules with auth:, owner:, policies, error codes, and how to test a query.
---

# dox_graphql guide

`dox_graphql` serves a GraphQL API at one URL (`/graphql`). You put annotations on your models and resolver classes. `dox_graphql_builder` writes the schema to `lib/generated/schema.g.dart`. `dox_graphql_orm` reads and writes the models.

Full docs: https://dartondox.dev/latest/packages/graphql/. Do not invent annotations or fields.

For routes, providers, DTOs and app layout, see the `dox-core-guide` skill. For models and relations, see `dox-orm-guide`. For login and policies, see `dox-auth-guide`.

The examples use the package name `my_app`. Use the `name:` of the app's `pubspec.yaml`.

## 1. Install

```bash
dox add graphql            # runs graphql:install
dox add graphql --no-orm   # for an app without models
```

The command does these things. It never overwrites a file. Do not make these files by hand. Edit the config.

- Adds `dox_core`, `dox_graphql` and `dox_graphql_orm` (not with `--no-orm`).
- Adds the dev dependencies `dox_graphql_builder`, `dox_builder` and `build_runner`.
- Writes `lib/config/graphql.dart` and `lib/providers/graphql_provider.dart`.
- Runs `build_runner`.

The command does not add `dox_auth`. The config that it writes is `GraphQLConfig(schema: graphqlSchema)`, with no middleware. Thus, the API is public until you add the auth middleware (see Config).

After each change to an annotation, a model or a DTO, run the builder and start the app again:

```bash
dart run build_runner build
```

## 2. Config

The installed config has no login. To make clients log in:

1. If the app has no login, run `dox add auth`.
2. Add the `dox_auth` import to `lib/config/graphql.dart`.
3. Add `middleware: <Object>[AuthMiddleware()]`.

`lib/config/graphql.dart`:

```dart
import 'package:dox_auth/dox_auth.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:my_app/generated/schema.g.dart';

GraphQLConfig graphqlConfig = GraphQLConfig(
  schema: graphqlSchema,
  middleware: <Object>[AuthMiddleware()],
);
```

| Setting | Default | Function |
|---|---|---|
| `path` | `/graphql` | The URL of the API. |
| `middleware` | none | Route middleware, for example `AuthMiddleware()`. |
| `autoResolvers` | `true` | `false` removes the automatic fields of all models. |
| `graphiql` | on in development | The GraphiQL page at `path`, for a browser. |
| `introspection` | on in development | The `__schema` and `__type` queries. |
| `showInternalErrors` | on in development | Sends the real error text to the client. |
| `maxDepth` | `64` | The maximum depth of a query. |
| `maxQueryLength` | `1000000` | The maximum number of characters in a query. |
| `maxFields` | `20000` | The maximum number of fields in one query. |
| `maxNodes` | `100000` | The maximum number of values in one request. |
| `maxRootFields` | `50` | The maximum number of top-level fields in one request. Each alias counts. |
| `maxRelationRows` | `50000` | The maximum number of rows that one relation loads for all parents together. |
| `maxErrors` | `100` | The maximum number of errors in one response. |

"On in development" means on when `APP_ENV` is `development`. Do not set these three to `true` in production. Set lower `max` values for a public API.

## 3. Models

Put `@GraphQLType()` on a model, and on each model that it has a relation to:

```dart
@DoxModel()
@GraphQLType(dto: CreatePostDto, policy: PostPolicy, owner: 'userId')
class Post extends PostGenerator {
  @Column()
  String? title;

  @Column()
  int? userId;

  @BelongsTo(User)
  User? user;
}
```

The `id`, the columns and the relations become fields. The model gets these automatic fields:

| Field | Condition | Notes |
|---|---|---|
| `posts(limit, offset)` | always | `limit` has a default of 20. A `limit` above 100 is an error. |
| `post(id)` | always | `null` if the id is not found. The `id` is an `ID`, for example `"1"`. |
| `createPost(input)` | `dto:` | The client can set only the DTO fields. |
| `updatePost(id, input)` | `dto:` and `policy:` | Changes and checks only the sent fields. `null` if the id is not found. |
| `deletePost(id)` | `dto:` and `policy:` | Gives `true`, or `false` if the id is not found. |

- `auth: true` is only a login check. To control which rows a user can read, give the model a `policy:` with `viewAny` and `view` (see section 5). Put secret columns in `hidden`.
- `queries: false` removes the list and find queries. The type stays for relations and resolvers.
- `owner: 'userId'` makes create set that column to the id of the logged-in user. It needs `dto:`. The column must not be a DTO field. Update never changes it.
- A column or relation in `hidden` of the model is not a field. `hidden` uses the snake_case name of the column or relation, for example `password_hash`, not the Dart field name. If `visibleFields` of the model is not empty, only those names are fields. To hide a different field, put `@GraphQLIgnore()` above its `@Column()`.
- `@GraphQLField()` on a getter makes a computed field.
- Dox loads a relation for all parents of the request in one query. A relation that is already loaded runs no query.

## 4. Resolvers

Write a resolver when the automatic fields are not sufficient. Put the annotations on methods of a class in `lib/`. The builder finds the class.

```dart
// lib/app/graphql/post.resolver.dart
class PostResolver {
  PostResolver(this.postService);

  final PostService postService;

  @GraphQLQuery(auth: false)
  Future<List<Post>> trendingPosts({int limit = 10}) {
    return postService.trending(limit);
  }

  @GraphQLMutation()
  Future<Post> importPost(CreatePostDto input) {
    return postService.import(input);
  }

  @GraphQLQuery()
  Future<User?> me(DoxGraphQLContext context) {
    return context.user<User>();
  }
}
```

- Dox gets the constructor values from the container (`info.context.make<T>()`). Put `@Inject()` on each class that the constructor takes.
- The method name is the field name. The return type is the field type.
- The parameters are the arguments. A parameter with a default value is optional.
- A `@Dto` parameter is the input. Dox applies its rules before the method runs.
- A `DoxGraphQLContext` parameter is not an argument. It gives `request`, `user<T>()`, `auth()`, `make<T>()` and `loader(...)`.
- Name the annotation `@GraphQLQuery`. `Query` of `dox_core` is for OpenAPI.

`@ResolveField()` adds a field to the type of its first parameter. Use a `DataLoader` so that many parents cause one query:

```dart
@ResolveField()
Future<Shop?> shop(Product product, DoxGraphQLContext context) {
  DataLoader<int, Shop> shops = context.loader<int, Shop>(
    'shops',
    () => DataLoader<int, Shop>(shopRepository.findByIds),
  );
  return shops.load(product.shopId);
}
```

`findByIds` takes a `List<int>` and returns a `Future<List<Shop?>>` in the same order as the ids.

On a plain Dart class, `@GraphQLType()` makes the public fields the GraphQL fields. A plain class gets no automatic queries.

## 5. Auth

The default comes from the config:

- With `AuthMiddleware()` in `middleware`: each query, mutation and relation needs a login.
- Without it: all fields are public.

Change the rule with `auth:`:

| Code | Result |
|---|---|
| `@GraphQLQuery(auth: false)`, `@GraphQLMutation(auth: false)` | That field is public. |
| `@GraphQLType(auth: false)` | The type is public: its list and find queries, its automatic mutations, and the relations that give it. With `dto:` and no `owner:`, a guest can create rows. |
| `@GraphQLType(auth: true)` | Each field that gives the type needs a login, also in a public query. |
| `@GraphQLField(auth: true)`, `@ResolveField(auth: true)` | That field of a type needs a login. |
| `owner:` | Create always needs a login, also with `auth: false`. |

- A type with `auth: true` is stronger than a field with `auth: false`.
- A public query does not make its relations public. With `trendingPosts` public, `user` in a post still needs a login.
- `auth: true` or `owner:` without the auth middleware stops the app at start with a `StateError`.
- The auth middleware never stops the request. A guest gets an error only for the fields that need a login. The other fields give their data.
- The client sends `Authorization: Bearer <token>`.

The automatic fields ask a `dox_auth` policy, when the policy lists the ability in `abilities`:

| Ability | Guards |
|---|---|
| `viewAny` | The list query and each relation to the model. Refused: the field is `null` with `FORBIDDEN`. |
| `view` | The find query. In lists and relations, Dox removes the rows that `view` refuses, so a list can have fewer rows than `limit`. |
| `create` | The create mutation. |
| `update`, `delete` | The update and delete mutations. |

Dox reads the keys of `abilities`, not the method names. A guest gets `UNAUTHENTICATED` before Dox reads the database. A missing id gets the same answer as a refused row.

Hand-written `@GraphQLQuery`, `@ResolveField` and getters that return models do not run these checks. Call `Gate` yourself there.

This policy lets each user change only their own posts:

```dart
class PostPolicy extends Policy<User, Post> {
  bool update(User user, Post post) => post.userId == user.id;
  bool delete(User user, Post post) => post.userId == user.id;

  @override
  Map<String, Function> get abilities => <String, Function>{
    'update': update,
    'delete': delete,
  };
}
```

Register it with `Gate.policy<Post>(PostPolicy());` in the `setup()` of a provider. Dox loads the row and asks the policy before it writes.

## 6. Errors

Errors are in the `errors` list of the response. Each field can fail alone. Read `extensions.code`:

| Code | Cause |
|---|---|
| `UNAUTHENTICATED` | The field needs a login. The resolver did not run. |
| `FORBIDDEN` | The policy refused. For a mutation, Dox wrote nothing. |
| `VALIDATION_FAILED` | The DTO rules failed. `extensions.fields` has one message for each field. |

To send your own message, throw a `GraphQLError`:

```dart
throw GraphQLError('This post is not published yet');
```

For all other errors, the client gets "Internal server error" in production. The real error goes to the `ExceptionHandler` of the app.

## 7. Test it

```bash
curl -X POST http://localhost:3000/graphql \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer <token>' \
  -d '{"query": "{ posts(limit: 10) { title user { name } } }"}'
```

A `GET` request can run only queries. A mutation with `GET` gets status 405. In development, open `/graphql` in a browser for GraphiQL.

In a Dart test, use `DoxTestClient` from `package:dox_core/testing.dart`:

```dart
TestResponse res = await client.post(
  '/graphql',
  body: <String, Object?>{'query': '{ post(id: "1") { title } }'},
  headers: <String, String>{'accept': 'application/json'},
);
expect(res.status, 200);
expect(res.json['errors'], isNull);
```

A field error has status 200 also. Always check `errors`.

## Common mistakes

- No `build_runner` after a change. The schema is then old, and the new field does not exist.
- `@GraphQLType()` on a model, but not on the models of its relations.
- No auth middleware in `GraphQLConfig.middleware`. The full API is then public, with the automatic create mutations.
- `dto:` without `policy:`: the model then gets only the create mutation.
- `@GraphQLType(auth: false)` on a model with `dto:` and no `owner:`. The create mutation is then public also. To make only reads public, keep the default and write a `@GraphQLQuery(auth: false)`, or use `owner:`.
- A model with private data, for example `User`, without `auth: true`. A public type or an API without the auth middleware then shows it through relations.
- `auth: true` as the only protection of private rows. It is a login check, not a policy check. Add a policy with `viewAny` and `view`.
- A policy method that is not in `abilities`. Dox does not see it, so it does not check it.
- A secret column that is not in `hidden` and has no `@GraphQLIgnore()`.
- The owner column as a DTO field. The client must not send it. Use `owner:`.
- A relation query in a loop in a resolver. Use `context.loader` with a `DataLoader`.
