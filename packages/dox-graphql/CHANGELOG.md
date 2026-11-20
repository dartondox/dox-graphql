## Unreleased

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
- `Schema` is now `GraphQLSchema`, so it does not clash with `Schema` of
  dox_core (dox_validation).
