# dox_graphql_orm

The [dox_orm](https://pub.dev/packages/dox_orm) part of
[dox_graphql](https://pub.dev/packages/dox_graphql). The code that
`dox_graphql_builder` writes for `@GraphQLType()` models uses it:

- the list and find queries of `@GraphQLAll` and `@GraphQLFind`, like
  `posts(limit: 10)` and `post(id: "1")`,
- relations loaded in batches, one query per relation (no N+1). A list
  relation reads a maximum of `GraphQLConfig.maxRelationRows` (50,000)
  rows in one batch. More rows give an error,
- the paged list query of `@GraphQLPaginate`, like
  `posts(first: 10, page: 2)`,
- the create, update and delete mutations of `@GraphQLCreate`,
  `@GraphQLUpdate` and `@GraphQLDelete`.

Add it to an app that has `@GraphQLType()` on its models:

```yaml
dependencies:
  dox_graphql: any
  dox_graphql_orm: any
```

Read the docs: https://dartondox.dev/latest/packages/graphql/
