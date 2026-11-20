## Unreleased

- First version: the GraphQL engine, in pure Dart.
  - Type system: the built-in scalars, custom scalars, objects,
    interfaces, unions, enums, input objects, lists, non-null, arguments
    with defaults, and deprecation.
  - `Schema`: query and mutation roots. The schema is checked when it is
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
