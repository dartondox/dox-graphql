// This file imports dox_core and dox_graphql together. dox_core exports a
// `Query` annotation for OpenAPI, so the GraphQL one is `GraphQLQuery`.
import 'package:dox_core/dox_core.dart';
import 'package:dox_graphql/dox_graphql.dart';

class MathResolver {
  /// The sum of each row.
  @GraphQLQuery()
  List<int> rowSums(List<List<int>> rows) {
    return <int>[
      for (List<int> row in rows) row.fold(0, (int a, int b) => a + b),
    ];
  }

  /// The path of the request.
  @GraphQLQuery()
  String path(DoxGraphQLContext context) {
    DoxRequest request = context.request;
    return request.uri.path;
  }
}
