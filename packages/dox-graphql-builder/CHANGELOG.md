## 0.0.1

- Reads the operation annotations of a model: `@GraphQLAll`,
  `@GraphQLPaginate`, `@GraphQLFind`, `@GraphQLCreate`,
  `@GraphQLUpdate` and `@GraphQLDelete`. A model without them has no
  root field. `@GraphQL(queries:, dto:, auth:, policy:, owner:)` is
  gone.
- `can:` writes a `Gate.allows` check into the resolver. Find, update
  and delete check a missing id as a blank row, so a denied user gets
  the same error for an id that exists and for an id that does not
  exist. The generated code does not ask `Gate.hasAbility` any more: a
  check is in the code only when the annotation has `can:`.
- `@GraphQL(filter:)` writes the row filter into the lists and the
  relations to the model. A relation does not ask `viewAny` any more.
  The find writes it too: a denied row gives null. Every other field
  that gives the model also gets it: getters, fields of plain classes,
  custom resolvers and the results of create and update.
- A missing id is checked as a blank row. Any error of the policy on
  the blank row (like a `late` field that is not set, or a parse of an
  empty value) now denies. Before, the request got an internal error,
  so a missing id gave another answer than a denied id.
- The build fails when a field gives a model with `filter:` as
  `List<M?>` or a nested list like `List<List<M>>`: those rows can not be
  filtered. `M`, `M?`, `List<M>` and `List<M>?` work.
- A build warning for `@GraphQLUpdate` or `@GraphQLDelete` with no
  `can:` and no `guard:` (on it or on the type): anyone can call it.
- Reads `@GraphQL` (was `@GraphQLType`).
- A type with `guard: true` writes `guard: true` on its paginator type
  and on its delete mutation.
- `@GraphQLPaginate` writes a `<Model>Paginator` type and adds the
  shared `PaginatorInfo` type of dox_graphql_orm.
- The schema gets a start check that lists each `can:` and `filter:`
  with its model. The app does not start when an ability is not in the
  policy of the model and not in `Gate.define`.
- `owner:` is on `@GraphQLCreate`. The build fails when the owner is not
  an int or String column of the model, or is a field of the create or
  the update DTO.
- The build fails when an operation annotation is on a plain class or
  on a model with no `@GraphQL`.
- Writes `guard:` (was `auth:`) of the annotations into the generated
  types and fields. `@ResolveField` is now `@GraphQLResolveField`.
- A schema with types but no query gets the placeholder query. Before,
  the build failed.

- Fix: a schema field is nullable when an error can hit it. Before, a
  refused field made the whole parent (or all of `data`) null. Now only
  that field is null. List items stay non-null: a refused row is
  dropped. The rule:
  - Each root field (`Query` and `Mutation`, automatic or your own) is
    nullable, with any type.
  - Each relation is nullable.
  - Another field (a plain class field, a getter, a
    `@GraphQLResolveField`) is nullable when it has `guard: true`, or
    gives a type with `guard: true`.
- List relations (`HasMany`, `ManyToMany`, `HasManyThrough`,
  `MorphMany`) load with `GraphQLOrm.many`, with a row limit.
- An app with no query yet still gets `lib/generated/schema.g.dart`.
  The schema has one placeholder query, so the app starts. It goes away
  with the first real query.
- First version: builds `lib/generated/schema.g.dart` with
  `graphqlSchema` from `@GraphQL`, `@GraphQLField`, `@GraphQLIgnore`,
  `@GraphQLQuery`, `@GraphQLMutation` and `@GraphQLResolveField`.
  - Plain Dart classes become object types; their public fields, also
    the fields of superclasses, become fields.
  - Resolver classes get their constructor parameters from the Dox
    container.
  - Method parameters become arguments (nested lists too), a `@Dto` parameter becomes an
    input type, and its rules run first.
  - A type that GraphQL can not show stops the build with an error that
    names the class and the member.
- Models of dox_orm: `@GraphQL()` on a `@DoxModel` makes `id` (an
  `ID`), the `@Column` fields and the relations into fields. Columns and
  relations in `hidden` are left out. With `visibleFields`, only those
  fields are in the type. Relations load in batches with dox_graphql_orm.
  - The operation annotations make the root fields: `@GraphQLAll`
    (`posts(limit:, offset:)`), `@GraphQLPaginate`, `@GraphQLFind`
    (`post(id:)`), `@GraphQLCreate(dto:)`, `@GraphQLUpdate(dto:)` and
    `@GraphQLDelete`. Only the DTO fields can be set, and the DTO rules
    run first. Update checks and sets only the fields the client sent.
