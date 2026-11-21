## Unreleased

- A query with many fields is faster and uses less memory. The engine
  now makes a `Future` only for a value that waits, like the value of an
  async resolver. Before, each field made some `Future` objects, and
  they stayed in memory until the request was done. In a test with 256
  requests at the same time, a list of 20 rows went from 2,400 to 25,000
  requests each second. The peak memory went from 260 MB to 45 MB.
- The results of a query do not change. When more than one field fails,
  the sequence of the items in `errors` can be different.
- A request that stops at `maxNodes` does not leave errors with no
  handler. Before, a list of `Future` items that failed could do this.
- A request that goes above `maxNodes` always gives the "too much data"
  error. Before, a non-null field that failed could hide it.
- With a very high `maxDepth`, a stack overflow in a deep query gives the
  "nested too deep" error, not a field error.

## 0.0.1

- One annotation for each operation of a model. A model shows what it
  gives in its annotations:
  - `@GraphQLAll` (the list query), `@GraphQLPaginate` (the paged list
    query), `@GraphQLFind`, `@GraphQLCreate(dto:)`, `@GraphQLUpdate(dto:)`
    and `@GraphQLDelete`. Each takes `name:`, `description:`, `can:` and
    `guard:`.
  - A model with no operation annotation has no query and no mutation.
  - `can:` is an ability, like `Ability.view` of dox_auth. The resolver
    asks `Gate.allows` with it. All, Paginate and Create ask it on the
    model type. Find, Update and Delete ask it on the row. A missing id
    is asked as a blank row. A denied guest gets `UNAUTHENTICATED`, and
    a denied user gets `FORBIDDEN`. With no `can:`, the resolver asks
    nothing.
    Any error of the policy on the blank row of a missing id is a deny,
    so a missing id gets the same answer as a denied id.
  - `owner:` is on `@GraphQLCreate`. The create sets that column to the
    id of the logged-in user, so it needs a login. Update never changes
    it. `GraphQLAuth.ownerId` reads the id.
  - `@GraphQL(filter: ability)`: the lists and the relations to the
    model drop the rows that the ability denies. A single relation gives
    null. It hides denied rows everywhere the type appears: the lists,
    `@GraphQLFind`, relations, the rows that create and update give back,
    `@GraphQLField` getters, fields of plain classes, and the results of
    `@GraphQLQuery`, `@GraphQLMutation` and `@GraphQLResolveField`. A
    denied row is null, like a missing id, and a list drops it. The
    filter does not stop update and delete: they ask only their `can:`.
    A row that `filter:` hides can still be updated or deleted when the
    operation has no `can:`. The result of a create is not filtered: the
    client gets back the row it sent.
    An interface or union field that picks the type is not filtered.
  - A type with `guard: true` also guards its `<Model>Paginator` and its
    `@GraphQLDelete` (a Boolean field), so a guest gets
    `UNAUTHENTICATED` before any query runs.
- `@GraphQLPaginate` gives `posts(first: Int = 20, page: Int = 1)` with
  the type `PostPaginator { data, paginatorInfo }`. `PaginatorInfo` has
  `count`, `currentPage`, `firstItem`, `lastItem`, `hasMorePages`,
  `lastPage`, `perPage` and `total`. A `first` above 100 is an error.
  When the model also has `@GraphQLAll`, the name is `postsPaginate`.
  With `filter:`, `total`, `lastPage`, `firstItem` and `lastItem` also
  count the rows that the filter drops, because the queries run first.
  `count` is the number of rows in `data`.
- `guard: true` needs a logged-in user. It is on `@GraphQL`,
  `@GraphQLField`, `@GraphQLQuery`, `@GraphQLMutation`,
  `@GraphQLResolveField`, the operation annotations, `Field` and
  `ObjectType`. The default is public, also with the auth middleware in
  `GraphQLConfig.middleware`. A type with `guard: true` needs a login on
  every field that gives it, also when an interface or union field
  picks it. A field that needs a login fails with `UNAUTHENTICATED`,
  and its resolver does not run. Introspection stays public.
- The auth middleware in `GraphQLConfig.middleware` reads the user. It
  runs only when a field needs the user. A `guard: true` with no auth
  middleware stops the start with a `StateError`.
- When the app starts, `GraphQLProvider.boot()` runs the
  `GraphQLSchema.startChecks`. The generated schema checks each `can:`
  and `filter:`. When the model has a policy, the policy must have the
  ability. A `Gate.define` counts only for a model with no policy. Else the start stops with an error like
  `@GraphQLFind(can: 'veiw') on Post: PostPolicy has no ability 'veiw'.
  Available: viewAny, view, create, update, delete.` This needs the
  dox_auth version with `Gate.policyOf` and `Gate.isDefined`.
- `@GraphQLType` is now `@GraphQL`, with the same options: `name`,
  `description`, `guard` and `filter`.
- `@ResolveField` is now `@GraphQLResolveField`.
- `AutoField` and `GraphQLConfig(autoResolvers:)` are gone. The builder
  makes no field by default, so there is nothing to turn off.

- New: `maxRootFields` in `GraphQLConfig` and `GraphQLExecutor`, 50 by
  default. It is the maximum number of top-level fields in one
  operation, after fragments are expanded. Each alias counts. A query
  with more fields gets an error, and no resolver runs.
- New: `maxRelationRows` in `GraphQLConfig`, 50,000 by default. It is
  the maximum number of rows that one list relation loads for all
  parents at one level. More rows give an error.
- `GraphQLAuth.unauthenticatedError()` gives the `UNAUTHENTICATED` error.
- `dox add graphql` writes a commented
  `// middleware: <Object>[AuthMiddleware()],` line in
  `lib/config/graphql.dart`.
- Adds the `dox-graphql-guide` skill.
- `dox add graphql` (`graphql:install`) sets up an app: the packages,
  `lib/config/graphql.dart`, the provider and build_runner. `--no-orm`
  leaves out dox_graphql_orm. It never overwrites a file.
- The auth middleware is found by `IAuthMiddleware` of dox_core. The
  release needs the dox_core version that ships `IAuthMiddleware`; the
  dox_core floor goes up then.
- The auth middleware runs only when a field needs the user, once per
  request. `DoxGraphQLContext.user<T>()` and `auth()` are now async.
- `GraphQLExecutor(guard:)` takes a `FieldGuard` that checks each field
  before its resolver.
- In development, the app prints how many fields are public and how many
  need a login.
- First version: the GraphQL engine, in pure Dart.
  - Type system: the built-in scalars, custom scalars, objects,
    interfaces, unions, enums, input objects, lists, non-null, arguments
    with defaults, and deprecation.
  - `GraphQLSchema`: query and mutation roots. The schema is checked when it is
    built, and a bad schema throws a `SchemaError` with every problem.
  - Validation of queries with the rules of the spec, plus your own
    `ValidationRule`s.
  - `GraphQLExecutor`: variables, fragments, `@skip` and `@include`,
    aliases, async resolvers, query fields side by side, mutation fields
    one after another, null bubbling, and errors with `locations` and
    `path`.
  - Introspection (`__schema`, `__type`), with a switch to turn it off.
  - A typed context object for every resolver.
  - `DataLoader` to batch and cache loads. With
    `DataLoader.withResults`, one key can fail on its own (`LoadResult`).
  - Safety limits: `maxDepth` (64), `maxQueryLength` (1,000,000
    characters), `maxFields` (20,000 selected fields, with fragments
    expanded, checked before running), `maxNodes` (100,000 resolved fields
    and list items, checked while running), `maxErrors` (at most 100 errors
    kept, in validation and in a request; a request keeps its data), a work budget for validation, and
    `execute` never throws.
  - Errors from resolvers that are not a `GraphQLError` are sent as
    "Internal server error". `showInternalErrors: true` shows the real
    message.
- Dox integration:
  - `GraphQLProvider` adds `GET` and `POST` routes (default `/graphql`)
    and builds one executor per isolate. It is in the Dox container.
  - `GraphQLConfig`: path, route middleware, the engine limits,
    validation rules, `introspection`, `showInternalErrors` and
    `graphiql`. The last three are on in development and off otherwise.
  - GraphQL over HTTP: JSON `POST`, `GET` for queries only (a mutation
    gets 405), `application/graphql-response+json` when the client asks
    for it, and 400 for requests that fail before they run.
  - `DoxGraphQLContext`: the request, the logged-in user, services from
    the container, and DataLoaders that live for one request.
  - Errors that resolvers throw go to the `ExceptionHandler` of the app.
  - A GraphiQL page for the browser, with pinned versions and SRI.
- `GraphQLExecutor.execute(allowMutations: false)` stops a mutation with
  a `MutationNotAllowedError`.
- `GraphQLRequest.extensions`.
- The engine limit defaults are constants:
  `GraphQLExecutor.defaultMaxDepth` and the others.
- Annotations for `dox_graphql_builder`: `@GraphQL`, `@GraphQLField`,
  `@GraphQLIgnore`, `@GraphQLQuery`, `@GraphQLMutation` and
  `@GraphQLResolveField`.
- The base class of all types is `GraphQLTypeRef`.
- `graphqlDateTime`: a `DateTime` scalar, sent as ISO 8601 text in UTC. Input with no
  offset is read as UTC.
- `GraphQLDto.validate` runs the rules of a `@Dto` on mutation input. A
  failed check gives one error "Validation failed" with
  `extensions: {code: VALIDATION_FAILED, fields: {name: message}}`.
- `GraphQLDto.validateSent`: checks only the keys the client sent, for an
  update. The stored values of the other keys are not checked.
- `Schema` is now `GraphQLSchema`, so it does not clash with `Schema` of
  dox_core (dox_validation).
