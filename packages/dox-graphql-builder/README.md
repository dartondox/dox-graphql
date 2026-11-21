# dox_graphql_builder

The `build_runner` builder of [dox_graphql](https://pub.dev/packages/dox_graphql).
It reads `@GraphQL`, `@GraphQLQuery`, `@GraphQLMutation` and the other annotations of
your app, and writes `lib/generated/schema.g.dart` with `graphqlSchema`.

```yaml
dev_dependencies:
  build_runner: any
  dox_graphql_builder: any
```

```bash
dart run build_runner build
```

```dart
GraphQLConfig graphqlConfig = GraphQLConfig(schema: graphqlSchema);
```

Read the docs: https://dartondox.dev/latest/packages/graphql/
