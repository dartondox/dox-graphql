## Unreleased

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
  - `owner:` is on `@GraphQLCreate`. The create sets that column to the
    id of the logged-in user, so it needs a login. Update never changes
    it. `GraphQLAuth.ownerId` reads the id.
  - `@GraphQLType(filter: ability)`: the lists and the relations to the
    model drop the rows that the ability denies. A single relation gives
    null.
- `@GraphQLPaginate` gives `posts(first: Int = 20, page: Int = 1)` with
  the type `PostPaginator { data, paginatorInfo }`. `PaginatorInfo` has
  `count`, `currentPage`, `firstItem`, `lastItem`, `hasMorePages`,
  `lastPage`, `perPage` and `total`. A `first` above 100 is an error.
  When the model also has `@GraphQLAll`, the name is `postsPaginate`.
  With `filter:`, `total` and `lastPage` also count the rows that the
  filter drops, because the count query runs first.
- `guard: true` needs a logged-in user. It is on `@GraphQLType`,
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
  and `filter:`: the policy of the model must have the ability, or
  `Gate.define` must have it. Else the start stops with an error like
  `@GraphQLFind(can: 'veiw') on Post: PostPolicy has no ability 'veiw'.
  Available: viewAny, view, create, update, delete.` This needs the
  dox_auth version with `Gate.policyOf` and `Gate.isDefined`.
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
- Annotations for `dox_graphql_builder`: `@GraphQLType`, `@GraphQLField`,
  `@GraphQLIgnore`, `@GraphQLQuery`, `@GraphQLMutation` and
  `@GraphQLResolveField`.
- The base class of all types is now `GraphQLTypeRef`, so the name
  `GraphQLType` is free for the annotation.
- `graphqlDateTime`: a `DateTime` scalar, sent as ISO 8601 text in UTC. Input with no
  offset is read as UTC.
- `GraphQLDto.validate` runs the rules of a `@Dto` on mutation input. A
  failed check gives one error "Validation failed" with
  `extensions: {code: VALIDATION_FAILED, fields: {name: message}}`.
- `GraphQLDto.validateSent`: checks only the keys the client sent, for an
  update. The stored values of the other keys are not checked.
- `Schema` is now `GraphQLSchema`, so it does not clash with `Schema` of
  dox_core (dox_validation).
