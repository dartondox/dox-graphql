/// The dox_orm part of dox_graphql: list, find, relations in batches and
/// writes for `@GraphQL()` models. The code that dox_graphql_builder
/// writes uses it.
library;

export 'src/graphql_orm.dart';

// the result of `GraphQLOrm.paginate`, for the generated paginator types
export 'package:dox_orm/dox_orm.dart' show Pagination;
