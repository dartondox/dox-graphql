## Unreleased

- A policy that lists `viewAny`, `view` or `create` now guards the
  reads and the create. The list query asks `viewAny` before the query.
  The find query asks `view` on the row. The list query and the
  relations drop the rows that `view` denies (a single relation becomes
  null), so a list can have fewer rows than `limit`. A relation to the model asks
  `viewAny`, and gives null with `FORBIDDEN` when denied. `createPost`
  asks `create` before it saves. The generated code asks
  `Gate.hasAbility` of dox_auth at run time, so the ability keys of
  `abilities` count, not the method names. A policy that does not list
  them keeps the old behavior. Hand-written resolvers do not run these
  checks.
- A denied guest gets `UNAUTHENTICATED`, and a denied user gets
  `FORBIDDEN`. When the user type of the policy is not nullable, a guest
  is stopped before the row lookup.
- Find, update and delete check a missing id as a blank row. A user that
  the policy denies gets the same error for an id that exists and for
  an id that does not exist.
- List relations (`HasMany`, `ManyToMany`, `HasManyThrough`,
  `MorphMany`) load with `GraphQLOrm.many`, with a row limit.
- `@GraphQLType(owner: 'userId')`: `createPost` sets the owner column to
  the id of the logged-in user, and needs a login. The build fails when
  the owner is not an int or String column of the model, is a field of
  the DTO, or has no `dto:`.
- An app with no GraphQL class yet still gets `lib/generated/schema.g.dart`.
  The schema has one placeholder query, so the app starts. It goes away
  with the first real query.
- Writes the `auth:` of `@GraphQLType`, `@GraphQLQuery`,
  `@GraphQLMutation`, `@GraphQLField` and `@ResolveField` into the
  generated types and fields.
- `updatePost` and `deletePost` are made only with
  `@GraphQLType(policy: PostPolicy)`. They ask the policy (through `Gate`
  of dox_auth) before they write.
- First version: builds `lib/generated/schema.g.dart` with
  `graphqlSchema` from `@GraphQLType`, `@GraphQLField`, `@GraphQLIgnore`,
  `@GraphQLQuery`, `@GraphQLMutation` and `@ResolveField`.
  - Plain Dart classes become object types; their public fields, also
    the fields of superclasses, become fields.
  - Resolver classes get their constructor parameters from the Dox
    container.
  - Method parameters become arguments (nested lists too), a `@Dto` parameter becomes an
    input type, and its rules run first.
  - A type that GraphQL can not show stops the build with an error that
    names the class and the member.
- Models of dox_orm: `@GraphQLType()` on a `@DoxModel` makes `id` (an
  `ID`), the `@Column` fields and the relations into fields. Columns and
  relations in `hidden` are left out. With `visibleFields`, only those
  fields are in the type. Relations load in batches with dox_graphql_orm.
  - A list and a find query (`posts(limit:, offset:)`, `post(id:)`).
    `@GraphQLType(queries: false)` turns them off.
  - `@GraphQLType(dto: CreatePostDto)` adds `createPost`; with
    `policy:` also `updatePost` and `deletePost`. Only the DTO fields can be set, and the DTO rules
    run first. Update checks and sets only the fields the client sent.
