import 'package:dox_core/dox_core.dart';

import '../errors.dart';
import 'graphql_context.dart';

/// Runs the rules of a `@Dto` on the input of a mutation. The code that
/// `dox_graphql_builder` writes calls it.
class GraphQLDto {
  const GraphQLDto._();

  /// The error code in `extensions` of a failed check.
  static const String validationFailed = 'VALIDATION_FAILED';

  /// Checks [input] with [schema] and gives the DTO.
  ///
  /// [input] has the input keys of the DTO, like `user_id`. [names] maps
  /// an input key to its GraphQL field name, like `user_id` to `userId`,
  /// so the errors have the names the client sent. [params] are given to
  /// rules like `@Unique(ignoreParam: 'id')`.
  ///
  /// With [only], the errors of other keys are left out: an update sends
  /// the stored values for the keys the client did not send. When only
  /// such errors are left, all errors are sent: the stored row itself is
  /// not valid.
  ///
  /// A failed check throws one [GraphQLError] "Validation failed" with
  /// `extensions: {code: VALIDATION_FAILED, fields: {name: message}}`.
  static Future<T> validate<T>(
    DtoSchema<T> schema,
    Map<String, Object?> input,
    DoxGraphQLContext context, {
    Map<String, String> names = const <String, String>{},
    Map<String, String> params = const <String, String>{},
    Set<String>? only,
  }) async {
    DtoState state = DtoState(
      root: input,
      resolver: Dox().messages,
      params: params,
      locale: context.request.locale,
    );
    ParseResult<T> result = await schema.run(input, state);
    if (result.success) return result.value as T;
    List<ValidationIssue> issues = result.issues;
    if (only != null) {
      List<ValidationIssue> sent = <ValidationIssue>[
        for (ValidationIssue issue in issues)
          if (issue.path.isNotEmpty && only.contains(issue.path.first)) issue,
      ];
      if (sent.isNotEmpty) issues = sent;
    }
    throw failed(issues, names);
  }

  /// The "Validation failed" error for [issues]. The first key of each
  /// path is renamed with [names].
  static GraphQLError failed(
    List<ValidationIssue> issues,
    Map<String, String> names,
  ) {
    Map<String, String> fields = <String, String>{};
    for (ValidationIssue issue in issues) {
      List<Object> path = issue.path;
      String name = path.isEmpty
          ? '_root'
          : <Object>[
              names[path.first] ?? path.first,
              ...path.skip(1),
            ].join('.');
      fields.putIfAbsent(name, () => issue.message);
    }
    return GraphQLError(
      'Validation failed',
      extensions: <String, Object?>{'code': validationFailed, 'fields': fields},
    );
  }
}
