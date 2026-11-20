# dox_graphql

GraphQL for the Dox framework.

| Package | What it is |
| --- | --- |
| [dox_graphql](packages/dox-graphql) | The GraphQL engine: schema, validation, execution, introspection, DataLoader. The annotations and the Dox provider. |
| [dox_graphql_builder](packages/dox-graphql-builder) | The `build_runner` builder: it makes `graphqlSchema` from the annotations. |

`packages/test-app` is a small Dox app that runs the generated code end to
end. It is not published.

This is a Dart pub workspace. Run `dart pub get` at the root, then
`dart test` in a package folder.

Each package is released on its own, with a tag `<package>-v<version>`,
like `dox_graphql-v0.0.1`.
