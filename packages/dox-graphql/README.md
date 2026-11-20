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
- The policy can also guard the reads and the create. GraphQL uses only
  methods with these exact names:
  - `viewAny(user)`: the list query and each relation to `Post` ask it
    first. When denied, the field is null with `FORBIDDEN`.
  - `view(user, post)`: the find query asks it on the row. The list query
    and the relations drop the rows that it denies, with no error. A
    single relation becomes null. Thus a list can have fewer rows than
    `limit`.
  - `create(user)`: `createPost` asks it before it saves.
  - A denied guest gets `UNAUTHENTICATED`, a denied user `FORBIDDEN`. A
    method with a different name is not used, also when `abilities`
    lists it.
- Find, update and delete check a missing id as a new, empty `Post`. A
  user that the policy denies gets the same error for an id that exists
  and an id that does not exist. If your `view`, `update` or `delete`
  allows an empty row (for example `!post.isPrivate`), a client can see
  which ids exist. Deny an empty row if this is a problem.
- In a resolver, read the user with `await info.context.user<User>()`.
- A query can have at most 50 top-level fields (`maxRootFields`). Aliases
  count.
- A list relation, like `posts { comments }`, reads at most 50,000 rows
  for all posts of the request (`maxRelationRows`). More rows give an
  error. Change it in `GraphQLConfig`.

### Auth middleware

- If you use a subclass of `AuthMiddleware` in `middleware`, override
  `asOptional()` to give your subclass. The `asOptional()` of dox_auth
  gives a plain `AuthMiddleware`, so your changes do not run.
- The login runs lazily, when a field needs the user. The other
  middleware in `middleware` runs before it, with no user.

Read the full docs: https://dartondox.dev/latest/packages/graphql/
