import 'dart:async';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:source_span/source_span.dart'
    show SourceSpan, SourceSpanException;

import 'errors.dart';
import 'introspection.dart';
import 'limits.dart';
import 'request.dart';
import 'schema.dart';
import 'types.dart';
import 'validation.dart';
import 'values.dart';

/// Parses, validates and runs GraphQL requests on a [Schema].
///
/// ```dart
/// GraphQLExecutor<AppContext> executor = GraphQLExecutor<AppContext>(schema);
/// GraphQLResponse response = await executor.execute(
///   GraphQLRequest('{ hero { name } }'),
///   context: AppContext(),
/// );
/// ```
final class GraphQLExecutor<C> {
  /// [introspection] turns `__schema` and `__type` on or off. [rules] are
  /// extra validation rules, run after the spec rules.
  ///
  /// [maxDepth] limits how deep a query can nest: selection sets (with
  /// fragments) and the `{`, `(` and `[` of the text. Very deep queries
  /// can use up the stack, so keep it well below 300.
  /// [maxQueryLength] limits the query text, in characters.
  ///
  /// [maxFields] limits the fields a query selects, with fragments
  /// expanded, before it runs. [maxNodes] limits the work while it runs:
  /// every resolved field and list item counts. Past it, the request stops
  /// with one error. This catches long lists that the field count cannot
  /// see.
  ///
  /// By default, an error that a resolver throws and that is not a
  /// [GraphQLError] is sent as "Internal server error", so no internal
  /// text leaks. [showInternalErrors] sends the real message (for
  /// development). The real error is always in
  /// [GraphQLError.originalError].
  GraphQLExecutor(
    this.schema, {
    this.introspection = true,
    List<ValidationRule> rules = const <ValidationRule>[],
    this.maxDepth = 64,
    this.maxQueryLength = 1000000,
    this.maxFields = 20000,
    this.maxNodes = 100000,
    this.maxErrors = 100,
    this.showInternalErrors = false,
  }) : rules = <ValidationRule>[
         if (!introspection) const NoIntrospectionRule(),
         ...rules,
       ];

  final Schema<C> schema;
  final bool introspection;
  final List<ValidationRule> rules;
  final int maxDepth;
  final int maxQueryLength;
  final int maxFields;
  final int maxNodes;

  /// Validation stops after this many errors.
  final int maxErrors;
  final bool showInternalErrors;

  /// Runs one request. It never throws: errors are in the response.
  Future<GraphQLResponse> execute(
    GraphQLRequest request, {
    required C context,
  }) async {
    String query = request.query;
    if (query.length > maxQueryLength) {
      return GraphQLResponse.failed(<GraphQLError>[
        GraphQLError(
          'The query is too long: the limit is $maxQueryLength characters.',
        ),
      ]);
    }
    if (QueryLimits.textNesting(query) > maxDepth) return _tooDeep();

    DocumentNode document;
    List<GraphQLError> errors;
    try {
      document = parseString(query);
      errors = validate(document);
    } on SourceSpanException catch (e) {
      SourceSpan? span = e.span;
      return GraphQLResponse.failed(<GraphQLError>[
        GraphQLError(
          'Syntax Error: ${e.message}',
          locations: <SourceLocation>[
            if (span != null)
              SourceLocation(span.start.line + 1, span.start.column + 1),
          ],
        ),
      ]);
    } on StackOverflowError {
      return _tooDeep();
    } catch (e, st) {
      // A custom rule that throws, or a bug: never throw.
      return _internalError(e, st);
    }
    if (errors.isNotEmpty) return GraphQLResponse.failed(errors);

    try {
      return await _run(document, request, context);
    } on StackOverflowError {
      return _tooDeep();
    } catch (e, st) {
      // A bug in the engine, or a bad custom scalar: never throw.
      return _internalError(e, st);
    }
  }

  GraphQLResponse _internalError(Object e, StackTrace st) {
    return GraphQLResponse.failed(<GraphQLError>[
      GraphQLError(
        showInternalErrors ? e.toString() : 'Internal server error',
        originalError: e,
        stackTrace: st,
      ),
    ]);
  }

  GraphQLResponse _tooDeep() => GraphQLResponse.failed(<GraphQLError>[
    GraphQLError('The query is nested too deep: the limit is $maxDepth.'),
  ]);

  Future<GraphQLResponse> _run(
    DocumentNode document,
    GraphQLRequest request,
    C context,
  ) async {
    OperationDefinitionNode operation;
    try {
      operation = _operation(document, request.operationName);
    } on GraphQLError catch (e) {
      return GraphQLResponse.failed(<GraphQLError>[e]);
    }

    (Map<String, Object?>, List<GraphQLError>) coerced = Values.variableValues(
      schema,
      operation,
      request.variables,
    );
    if (coerced.$2.isNotEmpty) return GraphQLResponse.failed(coerced.$2);

    return _Execution(
      schema,
      operation,
      <String, FragmentDefinitionNode>{
        for (DefinitionNode d in document.definitions)
          if (d is FragmentDefinitionNode) d.name.value: d,
      },
      coerced.$1,
      context,
      showInternalErrors,
      maxNodes,
    ).run();
  }

  /// Checks a document: the spec rules, the depth with fragments, then
  /// [rules]. A document that uses up the stack throws a
  /// [StackOverflowError]; [execute] turns that into an error.
  List<GraphQLError> validate(DocumentNode document) {
    List<GraphQLError> errors = DocumentValidator(
      schema,
      document,
      maxErrors,
    ).validate();
    if (errors.isNotEmpty) return errors;
    if (QueryLimits.selectionDepth(document) > maxDepth) {
      return _tooDeep().errors;
    }
    if (QueryLimits.fieldCount(document, maxFields) > maxFields) {
      return <GraphQLError>[
        GraphQLError(
          'The query selects too many fields: the limit is $maxFields.',
        ),
      ];
    }
    if (rules.isEmpty) return errors;
    ValidationContext context = ValidationContext(schema, document);
    for (ValidationRule rule in rules) {
      errors.addAll(rule.validate(context));
    }
    if (errors.length > maxErrors) {
      errors
        ..length = maxErrors
        ..add(DocumentValidator.tooManyErrors());
    }
    return errors;
  }

  OperationDefinitionNode _operation(DocumentNode document, String? name) {
    List<OperationDefinitionNode> operations = <OperationDefinitionNode>[
      for (DefinitionNode d in document.definitions)
        if (d is OperationDefinitionNode) d,
    ];
    if (name == null) {
      if (operations.length == 1) return operations.single;
      throw GraphQLError(
        operations.isEmpty
            ? 'Must provide an operation.'
            : 'Must provide operation name if query contains multiple '
                  'operations.',
      );
    }
    for (OperationDefinitionNode op in operations) {
      if (op.name?.value == name) return op;
    }
    throw GraphQLError('Unknown operation named "$name".');
  }
}

/// Thrown up the tree after a non-null field failed. The error is already
/// in the list; the nearest nullable parent becomes null.
final class _NullBubble {
  const _NullBubble();
}

/// Thrown when the execution passes `maxNodes`. It stops the request.
final class _TooMuchWork {
  const _TooMuchWork();
}

/// A field that is not in the schema: left out of the result.
final class _Skip {
  const _Skip();
}

const _Skip _skip = _Skip();

/// The state of one execution.
final class _Execution {
  _Execution(
    this.schema,
    this.operation,
    this.fragments,
    this.variables,
    this.context,
    this.showInternalErrors,
    this.maxNodes,
  ) : variableValues = InputValues(variables);

  final Schema<Object?> schema;
  final OperationDefinitionNode operation;
  final Map<String, FragmentDefinitionNode> fragments;
  final Map<String, Object?> variables;
  final InputValues variableValues;
  final Object? context;
  final bool showInternalErrors;
  final int maxNodes;
  int _nodes = 0;

  /// The sub fields of each object type and field node list. All items of
  /// a list share one node list, so their fields are collected once.
  /// Variables are fixed for the request, so `@skip` and `@include` give
  /// the same result every time.
  final Map<NamedType, Map<List<FieldNode>, Map<String, List<FieldNode>>>>
  _subFields =
      Map<
        NamedType,
        Map<List<FieldNode>, Map<String, List<FieldNode>>>
      >.identity();
  final List<GraphQLError> errors = <GraphQLError>[];

  Future<GraphQLResponse> run() async {
    ObjectType<Object?, Object?> root = schema.rootType(operation.type)!;
    Map<String, Object?>? data;
    try {
      Map<String, List<FieldNode>> fields;
      try {
        fields = _collect(
          root,
          operation.selectionSet,
          <String, List<FieldNode>>{},
          <String>{},
        );
      } on GraphQLError catch (e) {
        // A bad @skip or @include argument, like an explicit null variable.
        return GraphQLResponse.failed(<GraphQLError>[e]);
      }
      data = operation.type == OperationType.mutation
          ? await _serialFields(root, fields)
          : await _fields(root, null, fields, null);
    } on _NullBubble {
      data = null;
    } on _TooMuchWork {
      return GraphQLResponse(
        errors: <GraphQLError>[
          GraphQLError(
            'The query returns too much data: the limit is $maxNodes fields '
            'and list items.',
          ),
        ],
      );
    }
    return GraphQLResponse(data: data, errors: errors);
  }

  /// Counts resolved fields and list items. Past [maxNodes], it stops the
  /// whole request.
  void _spend(int nodes) {
    _nodes += nodes;
    if (_nodes > maxNodes) throw const _TooMuchWork();
  }

  /// Collects the fields of a selection set by response name, with
  /// fragments, `@skip` and `@include`. Each walked selection counts
  /// toward [maxNodes].
  Map<String, List<FieldNode>> _collect(
    ObjectType<Object?, Object?> type,
    SelectionSetNode set,
    Map<String, List<FieldNode>> out,
    Set<String> visitedFragments,
  ) {
    _spend(set.selections.length);
    for (SelectionNode s in set.selections) {
      switch (s) {
        case FieldNode():
          if (!_included(s.directives)) continue;
          (out[(s.alias ?? s.name).value] ??= <FieldNode>[]).add(s);
        case InlineFragmentNode():
          if (!_included(s.directives)) continue;
          NamedTypeNode? on = s.typeCondition?.on;
          if (on != null && !_applies(on.name.value, type)) continue;
          _collect(type, s.selectionSet, out, visitedFragments);
        case FragmentSpreadNode():
          if (!_included(s.directives)) continue;
          String name = s.name.value;
          if (!visitedFragments.add(name)) continue;
          FragmentDefinitionNode? f = fragments[name];
          if (f == null || !_applies(f.typeCondition.on.name.value, type)) {
            continue;
          }
          _collect(type, f.selectionSet, out, visitedFragments);
        default:
          break;
      }
    }
    return out;
  }

  bool _applies(String typeName, ObjectType<Object?, Object?> type) {
    NamedType? t = schema.type(typeName);
    if (t == null) return false;
    if (identical(t, type)) return true;
    return t.isAbstract &&
        schema
            .possibleTypes(t)
            .any((ObjectType<Object?, Object?> p) => identical(p, type));
  }

  bool _included(List<DirectiveNode> directives) {
    for (DirectiveNode d in directives) {
      String name = d.name.value;
      if (name == 'skip') {
        InputValues args = Values.argumentValues(
          Introspection.skip.args,
          d.arguments,
          variables,
        );
        if (args.get<bool>('if') == true) return false;
      } else if (name == 'include') {
        InputValues args = Values.argumentValues(
          Introspection.include.args,
          d.arguments,
          variables,
        );
        if (args.get<bool>('if') == false) return false;
      }
    }
    return true;
  }

  /// Runs fields side by side.
  Future<Map<String, Object?>> _fields(
    ObjectType<Object?, Object?> type,
    Object? source,
    Map<String, List<FieldNode>> fields,
    ResponsePath? path,
  ) async {
    List<String> keys = fields.keys.toList();
    List<Object?> values = await Future.wait(<Future<Object?>>[
      for (String key in keys)
        _field(type, source, fields[key]!, _path(path, key)),
    ]);
    Map<String, Object?> out = <String, Object?>{};
    for (int i = 0; i < keys.length; i++) {
      if (!identical(values[i], _skip)) out[keys[i]] = values[i];
    }
    return out;
  }

  /// Runs mutation root fields one after another.
  Future<Map<String, Object?>> _serialFields(
    ObjectType<Object?, Object?> type,
    Map<String, List<FieldNode>> fields,
  ) async {
    Map<String, Object?> out = <String, Object?>{};
    for (MapEntry<String, List<FieldNode>> e in fields.entries) {
      Object? value = await _field(type, null, e.value, _path(null, e.key));
      if (!identical(value, _skip)) out[e.key] = value;
    }
    return out;
  }

  static ResponsePath _path(ResponsePath? parent, String key) =>
      parent == null ? ResponsePath(null, PathKey(key)) : parent.key(key);

  Future<Object?> _field(
    ObjectType<Object?, Object?> type,
    Object? source,
    List<FieldNode> nodes,
    ResponsePath path,
  ) async {
    String name = nodes.first.name.value;
    Field<Object?, Object?>? def = schema.field(type, name);
    if (def == null) return _skip;
    _spend(1);
    try {
      InputValues args = Values.argumentValues(
        def.args,
        nodes.first.arguments,
        variables,
      );
      ResolveInfo<Object?> info = ResolveInfo<Object?>(
        context: context,
        args: args,
        fieldName: name,
        fieldNodes: nodes,
        parentType: type,
        returnType: def.type,
        schema: schema,
        operation: operation,
        fragments: fragments,
        variables: variableValues,
        responsePath: path,
      );
      Object? result = await def.resolveFor(source, info);
      return await _complete(def.type, type, nodes, path, result);
    } on _TooMuchWork {
      rethrow;
    } on _NullBubble {
      if (def.type is NonNullType) rethrow;
      return null;
    } catch (e, st) {
      return _fail(e, st, def.type, nodes, path);
    }
  }

  /// Records a field error. A non-null place throws up to its parent.
  Object? _fail(
    Object error,
    StackTrace stackTrace,
    GraphQLType type,
    List<FieldNode> nodes,
    ResponsePath path,
  ) {
    List<SourceLocation> locations = GraphQLError.locationsOf(nodes);
    errors.add(
      error is GraphQLError
          ? error.locate(locations, path.toList())
          : GraphQLError(
              showInternalErrors ? error.toString() : 'Internal server error',
              locations: locations,
              path: path.toList(),
              originalError: error,
              stackTrace: stackTrace,
            ),
    );
    if (type is NonNullType) throw const _NullBubble();
    return null;
  }

  Future<Object?> _complete(
    GraphQLType type,
    ObjectType<Object?, Object?> parent,
    List<FieldNode> nodes,
    ResponsePath path,
    Object? result,
  ) async {
    if (result is Future<Object?>) result = await result;
    if (type is NonNullType) {
      Object? value = await _complete(type.ofType, parent, nodes, path, result);
      if (value == null) {
        throw GraphQLError(
          'Cannot return null for non-nullable field '
          '${parent.name}.${nodes.first.name.value}.',
        );
      }
      return value;
    }
    if (result == null) return null;
    switch (type) {
      case ListType():
        if (result is! Iterable<Object?>) {
          throw GraphQLError(
            'Expected Iterable, but did not find one for field '
            '${parent.name}.${nodes.first.name.value}.',
          );
        }
        List<Object?> items = result.toList();
        _spend(items.length);
        return Future.wait(<Future<Object?>>[
          for (int i = 0; i < items.length; i++)
            _item(type.ofType, parent, nodes, path.index(i), items[i]),
        ]);
      case ScalarType<Object>():
        return type.serialize(result);
      case EnumType<Object?>():
        return type.serialize(result);
      case ObjectType<Object?, Object?>():
        return _object(type, nodes, path, result);
      case InterfaceType() || UnionType():
        ObjectType<Object?, Object?> runtime = _resolveType(
          type as NamedType,
          parent,
          nodes,
          result,
        );
        return _object(runtime, nodes, path, result);
      case NonNullType():
        throw StateError('Unreachable: non-null is handled above.');
      case InputObjectType():
        throw StateError('Input type ${type.name} as an output type.');
    }
  }

  Future<Object?> _item(
    GraphQLType type,
    ObjectType<Object?, Object?> parent,
    List<FieldNode> nodes,
    ResponsePath path,
    Object? item,
  ) async {
    try {
      return await _complete(type, parent, nodes, path, item);
    } on _TooMuchWork {
      rethrow;
    } on _NullBubble {
      if (type is NonNullType) rethrow;
      return null;
    } catch (e, st) {
      return _fail(e, st, type, nodes, path);
    }
  }

  Future<Map<String, Object?>> _object(
    ObjectType<Object?, Object?> type,
    List<FieldNode> nodes,
    ResponsePath path,
    Object result,
  ) {
    if (type.hasIsTypeOf && !type.isTypeOf(result)) {
      throw GraphQLError(
        'Expected value of type "${type.name}" but got: $result.',
      );
    }
    Map<List<FieldNode>, Map<String, List<FieldNode>>> forType =
        _subFields[type] ??=
            Map<List<FieldNode>, Map<String, List<FieldNode>>>.identity();
    Map<String, List<FieldNode>>? fields = forType[nodes];
    if (fields == null) {
      fields = <String, List<FieldNode>>{};
      Set<String> visited = <String>{};
      for (FieldNode n in nodes) {
        SelectionSetNode? set = n.selectionSet;
        if (set != null) _collect(type, set, fields, visited);
      }
      forType[nodes] = fields;
    }
    return _fields(type, result, fields, path);
  }

  ObjectType<Object?, Object?> _resolveType(
    NamedType abstractType,
    ObjectType<Object?, Object?> parent,
    List<FieldNode> nodes,
    Object value,
  ) {
    TypeResolver? resolver = switch (abstractType) {
      InterfaceType() => abstractType.resolveType,
      UnionType() => abstractType.resolveType,
      _ => null,
    };
    ObjectType<Object?, Object?>? runtime;
    if (resolver != null) {
      runtime = resolver(value);
    } else if (value is Map<String, Object?> && value['__typename'] is String) {
      NamedType? t = schema.type(value['__typename'] as String);
      if (t is ObjectType<Object?, Object?>) runtime = t;
    } else {
      for (ObjectType<Object?, Object?> t in schema.possibleTypes(
        abstractType,
      )) {
        if (t.isTypeOf(value)) {
          runtime = t;
          break;
        }
      }
    }
    if (runtime == null) {
      throw GraphQLError(
        'Abstract type "${abstractType.name}" must resolve to an Object type '
        'at runtime for field "${parent.name}.${nodes.first.name.value}". '
        'Either the "${abstractType.name}" type should provide a '
        '"resolveType" function or each possible type should provide an '
        '"isTypeOf" function.',
      );
    }
    ObjectType<Object?, Object?> found = runtime;
    if (!schema
        .possibleTypes(abstractType)
        .any((ObjectType<Object?, Object?> t) => identical(t, found))) {
      throw GraphQLError(
        'Runtime Object type "${found.name}" is not a possible type for '
        '"${abstractType.name}".',
      );
    }
    return found;
  }
}
