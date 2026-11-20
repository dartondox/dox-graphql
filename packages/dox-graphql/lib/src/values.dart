import 'dart:convert';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:meta/meta.dart';

import 'errors.dart';
import 'schema.dart';
import 'types.dart';

/// The result of a coercion that failed.
final class _Invalid {
  const _Invalid();
}

/// An input JSON value that does not fit its type.
final class _CoerceError {
  _CoerceError(this.message, this.at);

  final String message;
  final String at;
}

/// Turns literals and JSON input into the values that resolvers get.
///
/// The values are loose on purpose: GraphQL input values are JSON-like.
/// Resolvers read them through the typed [InputValues] getters.
@internal
final class Values {
  const Values._();

  /// Returned by [fromLiteral] when the literal does not fit the type.
  static const Object invalid = _Invalid();

  /// The type that a type node in the query names, or null when a named
  /// type is not in the schema.
  static GraphQLTypeRef? typeFromAst(
    GraphQLSchema<Object?> schema,
    TypeNode node,
  ) {
    GraphQLTypeRef? inner = switch (node) {
      NamedTypeNode() => schema.type(node.name.value),
      ListTypeNode() => switch (typeFromAst(schema, node.type)) {
        GraphQLTypeRef t => ListType(t),
        null => null,
      },
      _ => null,
    };
    if (inner == null) return null;
    return node.isNonNull ? NonNullType(inner) : inner;
  }

  /// Coerces a literal. [variables] are the coerced variables, or null in
  /// a const place. Returns [invalid] when the literal does not fit.
  static Object? fromLiteral(
    GraphQLTypeRef type,
    ValueNode node,
    Map<String, Object?>? variables,
  ) {
    if (node is VariableNode) {
      String name = node.name.value;
      if (variables == null || !variables.containsKey(name)) return invalid;
      Object? value = variables[name];
      if (value == null && type is NonNullType) return invalid;
      return value;
    }
    switch (type) {
      case NonNullType():
        if (node is NullValueNode) return invalid;
        return fromLiteral(type.ofType, node, variables);
      case _ when node is NullValueNode:
        return null;
      case ListType():
        GraphQLTypeRef itemType = type.ofType;
        if (node is! ListValueNode) {
          Object? item = fromLiteral(itemType, node, variables);
          return identical(item, invalid) ? invalid : <Object?>[item];
        }
        List<Object?> out = <Object?>[];
        for (ValueNode itemNode in node.values) {
          if (_isMissingVariable(itemNode, variables)) {
            // A missing variable in a list is null.
            if (itemType is NonNullType) return invalid;
            out.add(null);
            continue;
          }
          Object? item = fromLiteral(itemType, itemNode, variables);
          if (identical(item, invalid)) return invalid;
          out.add(item);
        }
        return out;
      case InputObjectType():
        if (node is! ObjectValueNode) return invalid;
        Map<String, ValueNode> given = <String, ValueNode>{};
        for (ObjectFieldNode f in node.fields) {
          if (type.field(f.name.value) == null) return invalid;
          given[f.name.value] = f.value;
        }
        Map<String, Object?> out = <String, Object?>{};
        for (InputField field in type.fields) {
          ValueNode? fieldNode = given[field.name];
          if (fieldNode == null || _isMissingVariable(fieldNode, variables)) {
            ValueNode? def = field.defaultLiteral;
            if (def != null) {
              out[field.name] = fromLiteral(field.type, def, null);
            } else if (field.type is NonNullType) {
              return invalid;
            }
            continue;
          }
          Object? value = fromLiteral(field.type, fieldNode, variables);
          if (identical(value, invalid)) return invalid;
          out[field.name] = value;
        }
        return InputValues(out);
      case EnumType<Object?>():
        try {
          return type.parseLiteral(node);
        } on Object {
          return invalid;
        }
      case ScalarType<Object>():
        try {
          return type.parseLiteral(node);
        } on Object {
          return invalid;
        }
      default:
        return invalid;
    }
  }

  static bool _isMissingVariable(
    ValueNode node,
    Map<String, Object?>? variables,
  ) {
    return node is VariableNode &&
        (variables == null || !variables.containsKey(node.name.value));
  }

  /// Coerces a JSON value from the request. Throws [_CoerceError].
  static Object? _fromJson(GraphQLTypeRef type, Object? value, String at) {
    if (type is NonNullType) {
      if (value == null) {
        throw _CoerceError(
          'Expected non-nullable type "$type" not to be null.',
          at,
        );
      }
      return _fromJson(type.ofType, value, at);
    }
    if (value == null) return null;
    switch (type) {
      case ListType():
        if (value is List<Object?>) {
          return <Object?>[
            for (int i = 0; i < value.length; i++)
              _fromJson(type.ofType, value[i], '$at[$i]'),
          ];
        }
        return <Object?>[_fromJson(type.ofType, value, at)];
      case InputObjectType():
        if (value is! Map<String, Object?>) {
          throw _CoerceError(
            'Expected type "${type.name}" to be an object.',
            at,
          );
        }
        for (String key in value.keys) {
          if (type.field(key) == null) {
            throw _CoerceError(
              'Field "$key" is not defined by type "${type.name}".',
              at,
            );
          }
        }
        Map<String, Object?> out = <String, Object?>{};
        for (InputField field in type.fields) {
          if (!value.containsKey(field.name)) {
            ValueNode? def = field.defaultLiteral;
            if (def != null) {
              out[field.name] = fromLiteral(field.type, def, null);
            } else if (field.type is NonNullType) {
              throw _CoerceError(
                'Field "${field.name}" of required type "${field.type}" was '
                'not provided.',
                at,
              );
            }
            continue;
          }
          out[field.name] = _fromJson(
            field.type,
            value[field.name],
            '$at.${field.name}',
          );
        }
        return InputValues(out);
      case EnumType<Object?>():
        try {
          return type.parseValue(value);
        } on GraphQLError catch (e) {
          throw _CoerceError(e.message, at);
        }
      case ScalarType<Object>():
        try {
          return type.parseValue(value);
        } on GraphQLError catch (e) {
          throw _CoerceError(e.message, at);
        } on Object catch (e) {
          throw _CoerceError('Expected type "${type.name}". $e', at);
        }
      default:
        throw _CoerceError('Expected an input type, found "$type".', at);
    }
  }

  /// Coerces the variables of an operation. Returns the values, or the
  /// errors when a variable does not fit.
  static (Map<String, Object?>, List<GraphQLError>) variableValues(
    GraphQLSchema<Object?> schema,
    OperationDefinitionNode operation,
    Map<String, Object?> inputs,
  ) {
    Map<String, Object?> out = <String, Object?>{};
    List<GraphQLError> errors = <GraphQLError>[];
    for (VariableDefinitionNode def in operation.variableDefinitions) {
      String name = def.variable.name.value;
      GraphQLTypeRef? type = typeFromAst(schema, def.type);
      if (type == null || !type.isInputType) {
        errors.add(
          GraphQLError.at(
            'Variable "\$$name" expected value of type "${printNode(def.type)}" '
            'which cannot be used as an input type.',
            <Node>[def],
          ),
        );
        continue;
      }
      if (!inputs.containsKey(name)) {
        ValueNode? defaultValue = def.defaultValue?.value;
        if (defaultValue != null) {
          out[name] = fromLiteral(type, defaultValue, null);
        } else if (type is NonNullType) {
          errors.add(
            GraphQLError.at(
              'Variable "\$$name" of required type "$type" was not provided.',
              <Node>[def],
            ),
          );
        }
        continue;
      }
      Object? value = inputs[name];
      if (value == null && type is NonNullType) {
        errors.add(
          GraphQLError.at(
            'Variable "\$$name" of non-null type "$type" must not be null.',
            <Node>[def],
          ),
        );
        continue;
      }
      try {
        out[name] = _fromJson(type, value, '');
      } on _CoerceError catch (e) {
        String at = e.at.isEmpty ? '' : ' at "$name${e.at}"';
        errors.add(
          GraphQLError.at(
            'Variable "\$$name" got invalid value ${_json(value)}$at; '
            '${e.message}',
            <Node>[def],
          ),
        );
      }
    }
    return (out, errors);
  }

  static String _json(Object? value) {
    try {
      return jsonEncode(value);
    } on Object {
      return '$value';
    }
  }

  /// Coerces the arguments of a field or directive. Throws a
  /// [GraphQLError] when an argument does not fit.
  static InputValues argumentValues(
    List<Argument> defs,
    List<ArgumentNode> nodes,
    Map<String, Object?> variables,
  ) {
    if (defs.isEmpty) return const InputValues(<String, Object?>{});
    Map<String, Object?> out = <String, Object?>{};
    for (Argument def in defs) {
      ArgumentNode? node;
      for (ArgumentNode n in nodes) {
        if (n.name.value == def.name) node = n;
      }
      ValueNode? valueNode = node?.value;
      bool hasValue = node != null;
      bool isNull = valueNode is NullValueNode;
      if (valueNode is VariableNode) {
        String name = valueNode.name.value;
        hasValue = variables.containsKey(name);
        isNull = hasValue && variables[name] == null;
      }
      ValueNode? defaultLiteral = def.defaultLiteral;
      if (!hasValue && defaultLiteral != null) {
        out[def.name] = fromLiteral(def.type, defaultLiteral, null);
        continue;
      }
      if (def.type is NonNullType && (!hasValue || isNull)) {
        throw GraphQLError.at(
          isNull
              ? 'Argument "${def.name}" of non-null type "${def.type}" must '
                    'not be null.'
              : 'Argument "${def.name}" of required type "${def.type}" was '
                    'not provided.',
          <Node>[?node],
        );
      }
      if (!hasValue || valueNode == null) continue;
      Object? value = fromLiteral(def.type, valueNode, variables);
      if (identical(value, invalid)) {
        throw GraphQLError.at(
          'Argument "${def.name}" has invalid value ${printNode(valueNode)}.',
          <Node>[node ?? valueNode],
        );
      }
      out[def.name] = value;
    }
    return InputValues(out);
  }
}
