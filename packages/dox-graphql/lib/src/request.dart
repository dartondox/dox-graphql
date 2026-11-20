import 'errors.dart';

/// One GraphQL request: the query text, the operation to run, the
/// variables and the extensions.
final class GraphQLRequest {
  const GraphQLRequest(
    this.query, {
    this.operationName,
    this.variables = const <String, Object?>{},
    this.extensions = const <String, Object?>{},
  });

  /// Reads a request from its JSON body: `query`, `operationName`,
  /// `variables` and `extensions`. Throws a [GraphQLError] when a part has
  /// the wrong type.
  factory GraphQLRequest.fromJson(Map<String, Object?> json) {
    Object? query = json['query'];
    Object? operationName = json['operationName'];
    Object? variables = json['variables'];
    Object? extensions = json['extensions'];
    if (query == null) throw GraphQLError('The request has no "query".');
    if (query is! String) {
      throw GraphQLError('The "query" must be a string.');
    }
    if (operationName != null && operationName is! String) {
      throw GraphQLError('The "operationName" must be a string.');
    }
    if (variables != null && variables is! Map<String, Object?>) {
      throw GraphQLError('The "variables" must be an object.');
    }
    if (extensions != null && extensions is! Map<String, Object?>) {
      throw GraphQLError('The "extensions" must be an object.');
    }
    return GraphQLRequest(
      query,
      operationName: operationName as String?,
      variables: (variables as Map<String, Object?>?) ?? <String, Object?>{},
      extensions: (extensions as Map<String, Object?>?) ?? <String, Object?>{},
    );
  }

  final String query;
  final String? operationName;

  /// The variables as JSON values.
  final Map<String, Object?> variables;

  /// Extra data from the client, as JSON values. The engine does not read
  /// it; it is there for your own code.
  final Map<String, Object?> extensions;
}

/// The result of a request.
///
/// [data] is missing ([hasData] false) when the request failed before
/// execution: a parse, validation or variable error. It is null when a
/// non-null error reached the root.
final class GraphQLResponse {
  const GraphQLResponse({
    this.data,
    this.hasData = true,
    this.errors = const <GraphQLError>[],
  });

  /// A response with only errors and no data.
  const GraphQLResponse.failed(this.errors) : data = null, hasData = false;

  /// The response data as JSON values.
  final Map<String, Object?>? data;
  final bool hasData;
  final List<GraphQLError> errors;

  Map<String, Object?> toJson() => <String, Object?>{
    if (errors.isNotEmpty)
      'errors': <Map<String, Object?>>[
        for (GraphQLError e in errors) e.toJson(),
      ],
    if (hasData) 'data': data,
  };
}
