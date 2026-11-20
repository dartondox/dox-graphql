# dox_graphql

GraphQL for the Dox framework. You put annotations on your models and
resolver classes. The builder writes the schema. The package serves it over HTTP
at `/graphql`, with GraphiQL in development.

The engine is pure Dart. It follows the GraphQL spec and has validation,
introspection and a `DataLoader`.

## Install

```bash
dox add graphql
```

This adds the packages, writes the config and the provider, and runs the
builder. Use `dox add graphql --no-orm` for an app without models.

## Example

```dart
@GraphQLType(dto: CreatePostDto, policy: PostPolicy)
class Post extends PostGenerator {}

class PostResolver {
  @GraphQLQuery(auth: false)
  Future<List<Post>> latestPosts() => Post().orderBy('id', 'desc').limit(10).get();
}
```

```dart
GraphQLConfig graphqlConfig = GraphQLConfig(
  schema: graphqlSchema,
  middleware: <Object>[AuthMiddleware()],
);
```

- With `AuthMiddleware()` in `middleware`, queries, mutations and
  relations need a login by default. `auth: false` makes one public.
- Without it, everything is public. `auth: true` then stops the app at
  start.
- `createPost` comes from `dto:`. `updatePost` and `deletePost` exist only
  with `policy:`.
- `owner: 'userId'` makes `createPost` set `userId` to the logged-in
  user. Create then needs a login.
- When the policy has a `viewAny`, `view` or `create` method, the list
  query, the find query and `createPost` ask it too. A relation to
  `Post` asks `viewAny`. A denied user gets `FORBIDDEN`, and a guest
  gets `UNAUTHENTICATED`.
- In a resolver, read the user with `await info.context.user<User>()`.
- A query can have at most 50 top-level fields (`maxRootFields`). Aliases
  count.

### Auth middleware

- If you use a subclass of `AuthMiddleware` in `middleware`, override
  `asOptional()` to give your subclass. The `asOptional()` of dox_auth
  gives a plain `AuthMiddleware`, so your changes do not run.
- The login runs lazily, when a field needs the user. The other
  middleware in `middleware` runs before it, with no user.

Read the full docs: https://dartondox.dev/latest/packages/graphql/
