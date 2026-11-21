---
name: dox-graphql-guide
description: Use when you add or change a GraphQL API in a Dox (Dart) app with dox_graphql, dox_graphql_builder and dox_graphql_orm. Covers dox add graphql, GraphQLConfig and its limits, @GraphQLType on models and plain classes, the operation annotations @GraphQLAll, @GraphQLPaginate, @GraphQLFind, @GraphQLCreate, @GraphQLUpdate and @GraphQLDelete, @GraphQLQuery, @GraphQLMutation and @GraphQLResolveField resolvers, login rules with guard:, policy checks with can: and filter:, owner:, error codes, and how to test a query.
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

The command does not add `dox_auth`. The config that it writes is `GraphQLConfig(schema: graphqlSchema)`, with no middleware. `guard:`, `can:`, `filter:` and `owner:` need the auth middleware (see Config).

After each change to an annotation, a model or a DTO, run the builder and start the app again:

```bash
dart run build_runner build
```

## 2. Config

The installed config cannot read the user. Each field is public until it has `guard: true` (see Auth). To let Dox read the user:

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

Put `@GraphQLType()` on a model, and on each model that it has a relation to. Then add one annotation for each operation. An operation with no annotation does not exist.

```dart
import 'package:dox_auth/dox_auth.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

@DoxModel()
@GraphQLType(filter: Ability.view)
@GraphQLAll(can: Ability.viewAny)
@GraphQLPaginate(can: Ability.viewAny)
@GraphQLFind(can: Ability.view)
@GraphQLCreate(dto: PostInput, can: Ability.create, guard: true, owner: 'userId')
@GraphQLUpdate(dto: PostInput, can: Ability.update, guard: true)
@GraphQLDelete(can: Ability.delete, guard: true)
class Post extends PostGenerator {
  @Column()
  String? title;

  @Column()
  int? userId;

  @BelongsTo(User)
  User? user;
}
```

The `id`, the columns and the relations become fields.

| Annotation | GraphQL field | Notes |
|---|---|---|
| `@GraphQLType()` | The `Post` type | No query and no mutation. Options: `name:`, `description:`, `guard:`, `filter:`. |
| `@GraphQLAll()` | `posts(limit, offset)` | `limit` has a default of 20. A `limit` above 100 is an error. |
| `@GraphQLPaginate()` | `posts(first, page)` | Gives `data` and `paginatorInfo`. The name is `postsPaginate` if the model also has `@GraphQLAll()`. |
| `@GraphQLFind()` | `post(id)` | `null` if the id is not found. The `id` is an `ID`, for example `"1"`. |
| `@GraphQLCreate(dto:)` | `createPost(input)` | The client can set only the DTO fields. Option: `owner:`. |
| `@GraphQLUpdate(dto:)` | `updatePost(id, input)` | Changes and checks only the sent fields. `null` if the id is not found. |
| `@GraphQLDelete()` | `deletePost(id)` | Gives `true`, or `false` if the id is not found. |

Each operation annotation has `name:`, `description:`, `can:` and `guard:`.

- No `guard:` means public. `guard: true` needs a login (see section 5).
- No `can:` means no policy check. `can:` asks an ability of the policy (see section 5).
- `@GraphQLUpdate` and `@GraphQLDelete` without `can:` let each caller change or delete each row. The builder gives a warning when one of them has no `can:` and no `guard:`.
- A model with only `@GraphQLType()` is available only through relations and your own resolvers.
- `paginatorInfo` has `count`, `currentPage`, `firstItem`, `lastItem`, `hasMorePages`, `lastPage`, `perPage` and `total`. `first` has a default of 20 and a maximum of 100. A `first` or a `page` below 1 is an error.
- `owner: 'userId'` makes create set that column to the id of the logged-in user. Thus, create needs a login. The column must not be a DTO field. Update never changes it.
- A field is nullable in the schema when an error can hit it, so an error nulls only that field. Each root field (`Query` and `Mutation`, of a model or your own) is nullable. Each relation is nullable. Another field (a plain class field, a getter, a `@GraphQLResolveField`) is nullable when it has `guard: true`, or gives a type with `guard: true`. List items stay non-null.
- A column or relation in `hidden` of the model is not a field. `hidden` uses the snake_case name of the column or relation, for example `password_hash`, not the Dart field name. If `visibleFields` of the model is not empty, only those names are fields. To hide a different field, put `@GraphQLIgnore()` above its `@Column()`.
- `@GraphQLField()` on a getter makes a computed field.
- Dox loads a relation for all parents of the request in one query. A relation that is already loaded runs no query.
- The build fails if an operation annotation is on a plain class, or on a model with no `@GraphQLType()`.

## 4. Resolvers

Write a resolver when the fields of the model annotations are not sufficient. Put the annotations on methods of a class in `lib/`. The builder finds the class.

```dart
// lib/app/graphql/post.resolver.dart
class PostResolver {
  PostResolver(this.postService);

  final PostService postService;

  @GraphQLQuery()
  Future<List<Post>> trendingPosts({int limit = 10}) {
    return postService.trending(limit);
  }

  @GraphQLMutation(guard: true)
  Future<Post> importPost(PostInput input) {
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

`@GraphQLResolveField()` adds a field to the type of its first parameter. Use a `DataLoader` so that many parents cause one query:

```dart
@GraphQLResolveField()
Future<Shop?> shop(Product product, DoxGraphQLContext context) {
  DataLoader<int, Shop> shops = context.loader<int, Shop>(
    'shops',
    () => DataLoader<int, Shop>(shopRepository.findByIds),
  );
  return shops.load(product.shopId);
}
```

`findByIds` takes a `List<int>` and returns a `Future<List<Shop?>>` in the same order as the ids.

On a plain Dart class, `@GraphQLType()` makes the public fields the GraphQL fields. A plain class cannot have the operation annotations. Write its queries as resolvers.

## 5. Auth

Each field is public by default. `AuthMiddleware()` in `middleware` only reads the user. It never stops the request.

### Login: `guard:`

| Code | Result |
|---|---|
| `@GraphQLAll(guard: true)` and the other operation annotations | That query or mutation needs a login. |
| `@GraphQLQuery(guard: true)`, `@GraphQLMutation(guard: true)` | That field needs a login. |
| `@GraphQLField(guard: true)`, `@GraphQLResolveField(guard: true)` | That field of a type needs a login. |
| `@GraphQLType(guard: true)` | Each field that gives the type needs a login: its queries, its mutations, the relations to it and your own resolvers. |
| `owner:` on `@GraphQLCreate` | Create needs a login. |

- A guest gets `UNAUTHENTICATED` only for the fields that need a login. The other fields give their data.
- `guard: true` or `owner:` without the auth middleware stops the app at start with a `StateError`.
- The client sends `Authorization: Bearer <token>`.

### Policy: `can:` and `filter:`

`can:` is an ability of the `dox_auth` policy of the model. Use the constants `Ability.viewAny`, `Ability.view`, `Ability.create`, `Ability.update` and `Ability.delete`.

| Code | The policy method gets | Refused |
|---|---|---|
| `@GraphQLAll(can:)`, `@GraphQLPaginate(can:)` | the user | The field is `null` with `FORBIDDEN`. |
| `@GraphQLFind(can:)` | the user and the row | The field is `null` with `FORBIDDEN`. |
| `@GraphQLCreate(can:)` | the user | `FORBIDDEN`. Dox does not read the input. |
| `@GraphQLUpdate(can:)`, `@GraphQLDelete(can:)` | the user and the row | `FORBIDDEN`. Dox writes nothing. |
| `@GraphQLType(filter:)` | the user and each row | No error. Dox hides the row. |

`@GraphQLAll`, `@GraphQLPaginate` and `@GraphQLCreate` give no row to the policy. Use `Ability.viewAny` or `Ability.create` there, not an ability that needs a row, like `Ability.view` or `Ability.update`.

- A refused guest gets `UNAUTHENTICATED`. A refused user gets `FORBIDDEN`.
- Find, update and delete ask a missing id as a new, empty row. Thus, a missing id gets the same answer as a refused row.
- `filter:` hides the refused rows in each field that gives the type. A list leaves the rows out, so it can have fewer rows than `limit`. A single value is `null`.
- This includes the list, the paged list, the find query, the relations, your own `@GraphQLQuery`, `@GraphQLMutation` and `@GraphQLResolveField` results, `@GraphQLField` getters, the fields of plain classes, and the results of create and update.
- With `filter:`, `total` and `lastPage` of `paginatorInfo` also count the hidden rows.
- `filter:` does not decide a write. Update and delete ask only their `can:`.
- `can:` and `filter:` need the auth middleware in the config. Without it, each client is a guest.

This policy lets each user change only their own posts:

```dart
class PostPolicy extends Policy<User, Post> {
  static const String publish = 'publish';

  bool update(User user, Post post) => post.userId == user.id;
  bool delete(User user, Post post) => post.userId == user.id;
  bool canPublish(User user, Post post) => user.editor == true;

  @override
  Map<String, Function> get abilities => <String, Function>{
    Ability.update: update,
    Ability.delete: delete,
    publish: canPublish,
  };
}
```

- Dox reads the keys of `abilities`, not the method names.
- For your own ability, write a constant on the policy, and use it: `can: PostPolicy.publish`.
- Register the policy with `Gate.policy<Post>(PostPolicy());` in the `setup()` of a provider.
- At start, a `can:` or `filter:` with an ability that the policy does not have stops the app. The error lists the available abilities.

Hand-written `@GraphQLQuery`, `@GraphQLMutation`, `@GraphQLResolveField` and getters get the `filter:` of the type, but no `can:` check. To refuse a user with an error there, call `Gate` yourself.

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
- Only `@GraphQLType()` on a model, and then a query for `posts`. Each operation needs its annotation.
- `@GraphQLCreate`, `@GraphQLUpdate` or `@GraphQLDelete` with no `guard:` and no `can:`. The mutation is then public.
- `@GraphQLUpdate` or `@GraphQLDelete` with `guard: true` and no `can:`. Each logged-in user can then change each row.
- A model with private data, for example `User`, without `@GraphQLType(guard: true)`. Relations and resolvers then show it to guests.
- `guard: true` as the only protection of private rows. It is a login check, not a policy check. Add `can:` and `filter:`.
- `filter:` as the protection of update and delete. It hides rows only in results.
- `Ability.view` or `Ability.update` on `@GraphQLAll`, `@GraphQLPaginate` or `@GraphQLCreate`. These get no row. Use `Ability.viewAny` or `Ability.create`.
- `guard:`, `can:`, `filter:` or `owner:` with no auth middleware in `GraphQLConfig.middleware`.
- A policy method that is not in `abilities`. The app then stops at start, because `can:` does not find the ability.
- A policy that is registered after the start, not in the `setup()` of a provider.
- A secret column that is not in `hidden` and has no `@GraphQLIgnore()`.
- The owner column as a DTO field. The client must not send it. Use `owner:`.
- A relation query in a loop in a resolver. Use `context.loader` with a `DataLoader`.
