## Unreleased

- First version: builds `lib/generated/schema.g.dart` with
  `graphqlSchema` from `@GraphQLType`, `@GraphQLField`, `@GraphQLIgnore`,
  `@Query`, `@Mutation` and `@ResolveField`.
  - Plain Dart classes become object types; their public fields become
    fields.
  - Resolver classes get their constructor parameters from the Dox
    container.
  - Method parameters become arguments, a `@Dto` parameter becomes an
    input type, and its rules run first.
  - A type that GraphQL can not show stops the build with an error that
    names the class and the member.
