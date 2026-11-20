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
- In a resolver, read the user with `await info.context.user<User>()`.

Read the full docs: https://dartondox.dev/latest/packages/graphql/
