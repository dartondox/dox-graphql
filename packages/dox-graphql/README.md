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
@DoxModel(table: 'posts')
@GraphQL(filter: Ability.view)
@GraphQLAll(can: Ability.viewAny)
@GraphQLPaginate(can: Ability.viewAny)
@GraphQLFind(can: Ability.view)
@GraphQLCreate(dto: PostInput, can: Ability.create, guard: true, owner: 'userId')
@GraphQLUpdate(dto: PostInput, can: Ability.update, guard: true)
@GraphQLDelete(can: Ability.delete, guard: true)
class Post extends PostGenerator {}

class PostResolver {
  @GraphQLQuery()
  Future<List<Post>> latestPosts() => Post().orderBy('id', 'desc').limit(10).get();
}
```

```dart
GraphQLConfig graphqlConfig = GraphQLConfig(
  schema: graphqlSchema,
  middleware: <Object>[AuthMiddleware()],
);
```

### Annotations of a model

Each annotation makes one field. A model with no operation annotation
has no query and no mutation.

| Annotation | GraphQL field |
|---|---|
| `@GraphQL()` | The `Post` type. |
| `@GraphQLAll()` | `posts(limit, offset)` |
| `@GraphQLPaginate()` | `posts(first, page)`, or `postsPaginate(first, page)` if the model also has `@GraphQLAll()` |
| `@GraphQLFind()` | `post(id)` |
| `@GraphQLCreate(dto:)` | `createPost(input)` |
| `@GraphQLUpdate(dto:)` | `updatePost(id, input)` |
| `@GraphQLDelete()` | `deletePost(id)` |

- `name:` and `description:` change the name and the text of a field.
- `@GraphQLPaginate` gives `data` and `paginatorInfo`. `paginatorInfo`
  has `count`, `currentPage`, `firstItem`, `lastItem`, `hasMorePages`,
  `lastPage`, `perPage` and `total`.
- A `limit` or a `first` above 100 is an error.
- `owner: 'userId'` on `@GraphQLCreate` sets `userId` to the id of the
  logged-in user. Thus, the create needs a login. The column must not be
  a field of the DTO. Update never changes it.

### Login

- Each field is public by default.
- `guard: true` on an annotation makes its field need a login. A guest
  gets `UNAUTHENTICATED`, and the resolver does not run.
- `@GraphQL(guard: true)` makes each field that gives the type need
  a login: the queries, the mutations, the relations and your own
  resolvers.
- `guard: true` needs `AuthMiddleware()` in `middleware`. Without it, the
  app stops at start.

### Policies

- `can:` is an ability of the policy of the model, like `Ability.view`
  of dox_auth. The field asks `Gate.allows` before it gives or writes
  data. A denied guest gets `UNAUTHENTICATED`, and a denied user gets
  `FORBIDDEN`.
- With no `can:`, the field does not ask the policy.
- `@GraphQLAll`, `@GraphQLPaginate` and `@GraphQLCreate` ask the ability
  with the user only. `@GraphQLFind`, `@GraphQLUpdate` and
  `@GraphQLDelete` ask it with the user and the row.
  Thus, use `viewAny` on All and Paginate and `create` on Create, not
  an ability that needs a row, like `view` or `update`.
- `@GraphQL(filter: Ability.view)` hides the rows that the ability
  denies, with no error, in each field that gives the type:
  - The list, the paged list and the list relations leave the rows out.
    Thus, a list can have fewer rows than `limit`.
  - A single relation and `post(id)` give null.
  - Your own `@GraphQLQuery`, `@GraphQLMutation`, `@GraphQLResolveField`,
    `@GraphQLField` getters and the fields of plain classes: a single
    value is null, and a list leaves the rows out.
  - The result of `updatePost` is null for a hidden row. The result of
    `createPost` is not filtered: the client gets back the row it sent.
  - `total` and `lastPage` of `paginatorInfo` also count the hidden rows.
  - The filter does not decide a write. Update and delete ask only
    their `can:`.
  - A row that `filter:` hides can still be updated or deleted when the
    operation has no `can:`.
- The builder gives a warning when `@GraphQLUpdate` or `@GraphQLDelete`
  has no `can:` and no `guard:`.
- For your own ability, write a constant on the policy, like
  `static const String publish = 'publish';`. Then use
  `can: PostPolicy.publish`.
- Register each policy in the `setup()` of a provider, with
  `Gate.policy<Post>(PostPolicy());`. At start, the app makes sure that
  the policy has each ability of `can:` and `filter:`. If one is
  missing, the app stops with an error that lists the available
  abilities.
- Find, update and delete ask a missing id as a new, empty `Post`. A
  user that the policy denies gets the same error for an id that exists
  and an id that does not exist. If your `view`, `update` or `delete`
  allows an empty row (for example `!post.isPrivate`), a client can see
  which ids exist. Deny an empty row if this is a problem.
- `can:` works only in the fields that the builder makes. Your own
  resolvers get the filter of the type, but no `can:` check. Call
  `Gate.allows(user, Ability.view, post)` yourself there.

### Other rules

- A schema field is nullable when an error can hit it. Then an error
  nulls only that field, and the parent (or `data`) keeps its other
  fields. The rule:
  - Each root field (`Query` and `Mutation`, of a model or your own) is
    nullable, with any type.
  - Each relation is nullable. It can fail on a login, the row cap or a
    database error.
  - Another field (a plain class field, a getter, a
    `@GraphQLResolveField`) is nullable when it has `guard: true`, or
    gives a type with `guard: true`.
  - List items stay non-null: `filter:` leaves a row out.
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
