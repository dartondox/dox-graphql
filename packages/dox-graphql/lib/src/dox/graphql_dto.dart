import 'dart:collection';

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
  /// the row itself, or an old value that breaks a newer rule. The sent
  /// keys get all their rules and changes (like `@Trim`). Read only the
  /// [sent] fields of the DTO.
  ///
  /// [placeholders] has a value of the right type for each key. It takes
  /// the place of a stored value that fails, so the DTO can be made. It
  /// is never read.
  static Future<T> validateSent<T>(
    DtoSchema<T> schema,
    Map<String, Object?> input,
    DoxGraphQLContext context, {
    required Set<String> sent,
    Map<String, Object?> placeholders = const <String, Object?>{},
    Map<String, String> names = const <String, String>{},
    Map<String, String> params = const <String, String>{},
  }) async {
    // first: which stored values fail
    DtoState first = _state(input, context, params);
    schema.convert(input, first, const <Object>[]);
    Map<String, Object?> data = <String, Object?>{...input};
    for (ValidationIssue issue in first.issues) {
      String key = issue.path.isEmpty ? '' : '${issue.path.first}';
      if (!sent.contains(key) && placeholders.containsKey(key)) {
        data[key] = placeholders[key];
      }
    }
    // then the real check. The errors of the other keys are dropped as
    // they are added, so the DTO is made and every step runs.
    DtoState state = DtoState(
      root: data,
      resolver: Dox().messages,
      params: params,
      locale: context.request.locale,
      issues: _SentIssues(sent),
    );
    ParseResult<T> result = await schema.run(data, state);
    if (result.success) return result.value as T;
    throw failed(result.issues, names);
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

/// A list of issues that drops the issues of keys that were not sent. An
/// issue about the whole input (`_root`) is kept.
class _SentIssues extends ListBase<ValidationIssue> {
  _SentIssues(this.sent);

  final Set<String> sent;
  final List<ValidationIssue> _issues = <ValidationIssue>[];

  bool _keeps(ValidationIssue issue) {
    if (issue.path.isEmpty) return true;
    String key = '${issue.path.first}';
    return key == '_root' || sent.contains(key);
  }

  @override
  void add(ValidationIssue element) {
    if (_keeps(element)) _issues.add(element);
  }

  @override
  void addAll(Iterable<ValidationIssue> iterable) {
    for (ValidationIssue issue in iterable) {
      add(issue);
    }
  }

  @override
  int get length => _issues.length;

  @override
  set length(int value) => _issues.length = value;

  @override
  ValidationIssue operator [](int index) => _issues[index];

  @override
  void operator []=(int index, ValidationIssue value) => _issues[index] = value;
}
