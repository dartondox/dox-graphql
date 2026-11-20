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
  /// A failed check throws one [GraphQLError] "Validation failed" with
  /// `extensions: {code: VALIDATION_FAILED, fields: {name: message}}`.
  static Future<T> validate<T>(
    DtoSchema<T> schema,
    Map<String, Object?> input,
    DoxGraphQLContext context, {
    Map<String, String> names = const <String, String>{},
    Map<String, String> params = const <String, String>{},
  }) async {
    DtoState state = _state(input, context, params);
    ParseResult<T> result = await schema.run(input, state);
    if (result.success) return result.value as T;
    throw failed(result.issues, names);
  }

  /// Like [validate], for an update: only the keys in [sent] are checked.
  ///
  /// [input] has the stored values for the other keys, so the DTO gets a
  /// whole input. Their errors are left out, like a `@Unique` that finds
  /// the row itself, or an old value that breaks a newer rule. Read only
  /// the [sent] fields of the DTO.
  ///
  /// When a stored value has a wrong type, the DTO can not be converted.
  /// It is then made without checks, with the value of [placeholders]
  /// for that key.
  static Future<T> validateSent<T>(
    DtoSchema<T> schema,
    Map<String, Object?> input,
    DoxGraphQLContext context, {
    required Set<String> sent,
    Map<String, Object?> placeholders = const <String, Object?>{},
    Map<String, String> names = const <String, String>{},
    Map<String, String> params = const <String, String>{},
  }) async {
    DtoState state = _state(input, context, params)
      ..keepValues = schema.usesRequiredWhen;
    // the four steps of DtoSchema.run, so the steps after a failed
    // stored value still check the sent values
    T? value = schema.convert(input, state, const <Object>[]);
    _throwSent(state.issues, sent, names);
    if (value == null) {
      Map<String, Object?> data = <String, Object?>{...input};
      for (ValidationIssue issue in state.issues) {
        Object key = issue.path.first;
        if (placeholders.containsKey(key)) data['$key'] = placeholders[key];
      }
      // ponytail: the sent values are used as sent here, without the
      // changes of the DTO (like @Trim). Only a stored value with a wrong
      // type gets here.
      value = schema.fromMap(data);
    }
    T dto = value as T;
    state.issues.clear();
    if (schema.hasChecks) {
      await schema.crossCheck(dto, state, const <Object>[]);
    }
    if (schema.isAsync) await schema.checkAsync(dto, state, const <Object>[]);
    _throwSent(state.issues, sent, names);
    return dto;
  }

  static DtoState _state(
    Map<String, Object?> input,
    DoxGraphQLContext context,
    Map<String, String> params,
  ) {
    return DtoState(
      root: input,
      resolver: Dox().messages,
      params: params,
      locale: context.request.locale,
    );
  }

  /// Throws the errors of the [sent] keys, if there are any.
  static void _throwSent(
    List<ValidationIssue> issues,
    Set<String> sent,
    Map<String, String> names,
  ) {
    List<ValidationIssue> own = <ValidationIssue>[
      for (ValidationIssue issue in issues)
        if (issue.path.isNotEmpty && sent.contains(issue.path.first)) issue,
    ];
    if (own.isNotEmpty) throw failed(own, names);
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
