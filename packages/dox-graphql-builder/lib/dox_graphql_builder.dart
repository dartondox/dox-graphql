/// The build_runner builder of dox_graphql: it writes
/// `lib/generated/schema.g.dart` from the annotations of the app.
library;

import 'package:build/build.dart';

import 'src/schema_builder.dart';

export 'src/schema_builder.dart';

/// Writes `lib/generated/schema.g.dart` with `graphqlSchema`.
Builder graphqlSchemaBuilder(BuilderOptions options) {
  return const GraphQLSchemaBuilder();
}
