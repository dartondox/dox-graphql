import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:meta/meta.dart';

import 'errors.dart';
import 'introspection.dart';
import 'schema.dart';
import 'types.dart';
import 'values.dart';

/// An extra check of a query document. It runs after the built-in spec
/// rules, and only when they pass. Use it for limits like max depth.
abstract interface class ValidationRule {
  List<GraphQLError> validate(ValidationContext context);
}

/// What a [ValidationRule] can look at.
final class ValidationContext {
  @internal
  ValidationContext(this.schema, this.document)
    : operations = <OperationDefinitionNode>[
        for (DefinitionNode d in document.definitions)
          if (d is OperationDefinitionNode) d,
      ],
      fragments = <String, FragmentDefinitionNode>{
        for (DefinitionNode d in document.definitions)
          if (d is FragmentDefinitionNode) d.name.value: d,
      };

  final Schema<Object?> schema;
  final DocumentNode document;
  final List<OperationDefinitionNode> operations;
  final Map<String, FragmentDefinitionNode> fragments;
}

/// Rejects `__schema` and `__type`. The executor adds it when
/// introspection is off. `__typename` still works.
final class NoIntrospectionRule implements ValidationRule {
  const NoIntrospectionRule();

  @override
  List<GraphQLError> validate(ValidationContext context) {
    List<GraphQLError> errors = <GraphQLError>[];
    for (DefinitionNode d in context.document.definitions) {
      if (d is OperationDefinitionNode) _walk(d.selectionSet, errors);
      if (d is FragmentDefinitionNode) _walk(d.selectionSet, errors);
    }
    return errors;
  }

  void _walk(SelectionSetNode set, List<GraphQLError> errors) {
    for (SelectionNode s in set.selections) {
      switch (s) {
        case FieldNode():
          String name = s.name.value;
          if (name == '__schema' || name == '__type') {
            errors.add(
              GraphQLError.at(
                'GraphQL introspection has been disabled, but the requested '
                'query contained the field "$name".',
                <Node>[s],
              ),
            );
          }
          SelectionSetNode? sub = s.selectionSet;
          if (sub != null) _walk(sub, errors);
        case InlineFragmentNode():
          _walk(s.selectionSet, errors);
        default:
          break;
      }
    }
  }
}

/// Thrown when validation has found [DocumentValidator.maxErrors] errors.
final class _TooManyErrors {
  const _TooManyErrors();
}

final class _VariableUsage {
  _VariableUsage(this.node, this.type, this.hasDefault);

  final VariableNode node;
  final GraphQLType? type;
  final bool hasDefault;
}

/// What one operation or fragment uses.
final class _DefinitionUses {
  final List<FragmentSpreadNode> spreads = <FragmentSpreadNode>[];
  final List<_VariableUsage> variables = <_VariableUsage>[];
}

/// Runs the validation rules of the spec on a document, in one walk.
@internal
final class DocumentValidator {
  DocumentValidator(this.schema, this.document, this.maxErrors);

  final Schema<Object?> schema;
  final DocumentNode document;

  /// Validation stops after this many errors.
  final int maxErrors;
  final List<GraphQLError> errors = <GraphQLError>[];
  final Map<String, FragmentDefinitionNode> _fragments =
      <String, FragmentDefinitionNode>{};
  final Map<String, _DefinitionUses> _fragmentUses =
      <String, _DefinitionUses>{};
  _DefinitionUses _uses = _DefinitionUses();

  void _error(String message, List<Node> nodes) {
    _report(GraphQLError.at(message, nodes));
  }

  /// Keeps [error]. An error after [maxErrors] errors stops validation.
  void _report(GraphQLError error) {
    if (errors.length >= maxErrors) throw const _TooManyErrors();
    errors.add(error);
  }

  /// The last error when validation stopped early.
  static GraphQLError tooManyErrors() => GraphQLError(
    'Too many validation errors, error limit reached. Validation aborted.',
  );

  List<GraphQLError> validate() {
    try {
      _validate();
    } on _TooManyErrors {
      errors.add(tooManyErrors());
    } on _TooComplex {
      errors.add(GraphQLError('The query is too complex to validate.'));
    }
    return errors;
  }

  void _validate() {
    List<OperationDefinitionNode> operations = <OperationDefinitionNode>[];
    for (DefinitionNode d in document.definitions) {
      switch (d) {
        case OperationDefinitionNode():
          operations.add(d);
        case FragmentDefinitionNode():
          String name = d.name.value;
          if (_fragments.containsKey(name)) {
            _error('There can be only one fragment named "$name".', <Node>[
              _fragments[name]!,
              d,
            ]);
          } else {
            _fragments[name] = d;
          }
        default:
          _error(
            'The "${_definitionName(d)}" definition is not executable.',
            <Node>[d],
          );
      }
    }

    Map<String, OperationDefinitionNode> names =
        <String, OperationDefinitionNode>{};
    for (OperationDefinitionNode op in operations) {
      String? name = op.name?.value;
      if (name == null) {
        if (operations.length > 1) {
          _error(
            'This anonymous operation must be the only defined operation.',
            <Node>[op],
          );
        }
      } else if (names.containsKey(name)) {
        _error('There can be only one operation named "$name".', <Node>[
          names[name]!,
          op,
        ]);
      } else {
        names[name] = op;
      }
    }

    Map<OperationDefinitionNode, _DefinitionUses> opUses =
        Map<OperationDefinitionNode, _DefinitionUses>.identity();
    for (OperationDefinitionNode op in operations) {
      _uses = opUses[op] = _DefinitionUses();
      _operation(op);
    }
    for (FragmentDefinitionNode f in _fragments.values) {
      _uses = _fragmentUses[f.name.value] = _DefinitionUses();
      _fragment(f);
    }

    _checkFragmentUse(opUses);
    _checkFragmentCycles();
    for (OperationDefinitionNode op in operations) {
      _checkVariables(op, opUses[op]!);
    }
    _OverlapChecker(schema, _fragments, _report).checkDocument(document);
  }

  static String _definitionName(DefinitionNode d) => switch (d) {
    TypeDefinitionNode() => d.name.value,
    TypeExtensionNode() => d.name.value,
    DirectiveDefinitionNode() => d.name.value,
    _ => 'schema',
  };

  void _operation(OperationDefinitionNode op) {
    ObjectType<Object?, Object?>? root = schema.rootType(op.type);
    if (root == null) {
      _error('Schema is not configured for ${op.type.name}s.', <Node>[op]);
    }
    Set<String> varNames = <String>{};
    for (VariableDefinitionNode def in op.variableDefinitions) {
      String name = def.variable.name.value;
      if (!varNames.add(name)) {
        _error('There can be only one variable named "\$$name".', <Node>[def]);
      }
      GraphQLType? type = _typeOf(def.type);
      if (type != null && !type.isInputType) {
        _error(
          'Variable "\$$name" cannot be non-input type '
          '"${printNode(def.type)}".',
          <Node>[def.type],
        );
        type = null;
      }
      ValueNode? defaultValue = def.defaultValue?.value;
      if (defaultValue != null && type != null) {
        _value(defaultValue, type, false, def);
      }
      _directives(def.directives, DirectiveLocation.variableDefinition);
    }
    _directives(op.directives, switch (op.type) {
      OperationType.query => DirectiveLocation.query,
      OperationType.mutation => DirectiveLocation.mutation,
      OperationType.subscription => DirectiveLocation.subscription,
    });
    _selections(op.selectionSet, root);
  }

  /// The type of a type node. Reports unknown names.
  GraphQLType? _typeOf(TypeNode node) {
    NamedTypeNode named = _namedNode(node);
    if (schema.type(named.name.value) == null) {
      _error('Unknown type "${named.name.value}".', <Node>[named]);
      return null;
    }
    return Values.typeFromAst(schema, node);
  }

  static NamedTypeNode _namedNode(TypeNode node) => switch (node) {
    NamedTypeNode() => node,
    ListTypeNode() => _namedNode(node.type),
    _ => throw StateError('Unknown type node $node'),
  };

  void _fragment(FragmentDefinitionNode f) {
    NamedTypeNode on = f.typeCondition.on;
    NamedType? type = schema.type(on.name.value);
    if (type == null) {
      _error('Unknown type "${on.name.value}".', <Node>[on]);
    } else if (!type.isComposite) {
      _error(
        'Fragment "${f.name.value}" cannot condition on non composite type '
        '"${type.name}".',
        <Node>[on],
      );
      type = null;
    }
    _directives(f.directives, DirectiveLocation.fragmentDefinition);
    _selections(f.selectionSet, type);
  }

  bool _overlap(NamedType a, NamedType b) {
    if (identical(a, b)) return true;
    List<ObjectType<Object?, Object?>> pb = schema.possibleTypes(b);
    return schema
        .possibleTypes(a)
        .any(
          (ObjectType<Object?, Object?> t) =>
              pb.any((ObjectType<Object?, Object?> u) => identical(t, u)),
        );
  }

  void _selections(SelectionSetNode set, NamedType? parent) {
    for (SelectionNode s in set.selections) {
      switch (s) {
        case FieldNode():
          _field(s, parent);
        case InlineFragmentNode():
          NamedType? type = parent;
          NamedTypeNode? on = s.typeCondition?.on;
          if (on != null) {
            type = schema.type(on.name.value);
            if (type == null) {
              _error('Unknown type "${on.name.value}".', <Node>[on]);
            } else if (!type.isComposite) {
              _error(
                'Fragment cannot condition on non composite type '
                '"${type.name}".',
                <Node>[on],
              );
              type = null;
            } else if (parent != null && !_overlap(parent, type)) {
              _error(
                'Fragment cannot be spread here as objects of type '
                '"${parent.name}" can never be of type "${type.name}".',
                <Node>[s],
              );
            }
          }
          _directives(s.directives, DirectiveLocation.inlineFragment);
          _selections(s.selectionSet, type);
        case FragmentSpreadNode():
          _uses.spreads.add(s);
          String name = s.name.value;
          FragmentDefinitionNode? f = _fragments[name];
          if (f == null) {
            _error('Unknown fragment "$name".', <Node>[s]);
          } else {
            NamedType? type = schema.type(f.typeCondition.on.name.value);
            if (type != null &&
                type.isComposite &&
                parent != null &&
                !_overlap(parent, type)) {
              _error(
                'Fragment "$name" cannot be spread here as objects of type '
                '"${parent.name}" can never be of type "${type.name}".',
                <Node>[s],
              );
            }
          }
          _directives(s.directives, DirectiveLocation.fragmentSpread);
        default:
          break;
      }
    }
  }

  void _field(FieldNode node, NamedType? parent) {
    String name = node.name.value;
    Field<Object?, Object?>? def = parent == null
        ? null
        : schema.field(parent, name);
    if (parent != null && def == null) {
      _error('Cannot query field "$name" on type "${parent.name}".', <Node>[
        node,
      ]);
    }
    _arguments(
      node.arguments,
      def?.args,
      unknownOn: 'field "${parent?.name}.$name"',
      requiredOf: 'Field "$name"',
      owner: node,
    );
    _directives(node.directives, DirectiveLocation.field);
    SelectionSetNode? sub = node.selectionSet;
    NamedType? subType;
    if (def != null) {
      NamedType named = def.type.namedType;
      if (named.isLeaf && sub != null) {
        _error(
          'Field "$name" must not have a selection since type '
          '"${def.type}" has no subfields.',
          <Node>[node],
        );
      } else if (!named.isLeaf && sub == null) {
        _error(
          'Field "$name" of type "${def.type}" must have a selection of '
          'subfields. Did you mean "$name { ... }"?',
          <Node>[node],
        );
      }
      if (named.isComposite) subType = named;
    }
    if (sub != null) _selections(sub, subType);
  }

  void _arguments(
    List<ArgumentNode> nodes,
    List<Argument>? defs, {
    required String unknownOn,
    required String requiredOf,
    required Node owner,
  }) {
    Set<String> seen = <String>{};
    for (ArgumentNode n in nodes) {
      String name = n.name.value;
      if (!seen.add(name)) {
        _error('There can be only one argument named "$name".', <Node>[n]);
      }
      Argument? def;
      for (Argument a in defs ?? const <Argument>[]) {
        if (a.name == name) def = a;
      }
      if (defs != null && def == null) {
        _error('Unknown argument "$name" on $unknownOn.', <Node>[n]);
      }
      _value(n.value, def?.type, def?.defaultValue != null, n);
    }
    for (Argument a in defs ?? const <Argument>[]) {
      if (a.isRequired && !seen.contains(a.name)) {
        _error(
          '$requiredOf argument "${a.name}" of type "${a.type}" is required, '
          'but it was not provided.',
          <Node>[owner],
        );
      }
    }
  }

  void _directives(List<DirectiveNode> nodes, DirectiveLocation location) {
    Set<String> seen = <String>{};
    for (DirectiveNode n in nodes) {
      String name = n.name.value;
      Directive? def = schema.directive(name);
      if (def == null) {
        _error('Unknown directive "@$name".', <Node>[n]);
        for (ArgumentNode a in n.arguments) {
          _value(a.value, null, false, a);
        }
        continue;
      }
      if (!def.locations.contains(location)) {
        _error(
          'Directive "@$name" may not be used on '
          '${Introspection.locationName(location)}.',
          <Node>[n],
        );
      }
      if (!def.isRepeatable && !seen.add(name)) {
        _error(
          'The directive "@$name" can only be used once at this location.',
          <Node>[n],
        );
      }
      _arguments(
        n.arguments,
        def.args,
        unknownOn: 'directive "@$name"',
        requiredOf: 'Directive "@$name"',
        owner: n,
      );
    }
  }

  /// Checks a value against its expected type. A null type means the place
  /// is not known; then only variable uses are noted. [owner] is the
  /// nearest argument, input field or variable definition: gql keeps no
  /// location on literals, so errors point at the owner.
  void _value(ValueNode node, GraphQLType? type, bool hasDefault, Node owner) {
    if (node is VariableNode) {
      _uses.variables.add(_VariableUsage(node, type, hasDefault));
      return;
    }
    if (type == null) {
      if (node is ListValueNode) {
        for (ValueNode v in node.values) {
          _value(v, null, false, owner);
        }
      } else if (node is ObjectValueNode) {
        for (ObjectFieldNode f in node.fields) {
          _value(f.value, null, false, f);
        }
      }
      return;
    }
    if (type is NonNullType) {
      if (node is NullValueNode) {
        _error(
          'Expected value of type "$type", found null.',
          _where(node, owner),
        );
        return;
      }
      _value(node, type.ofType, hasDefault, owner);
      return;
    }
    if (node is NullValueNode) return;
    switch (type) {
      case ListType():
        if (node is ListValueNode) {
          for (ValueNode v in node.values) {
            _value(v, type.ofType, false, owner);
          }
        } else {
          _value(node, type.ofType, false, owner);
        }
      case InputObjectType():
        if (node is! ObjectValueNode) {
          _error(
            'Expected value of type "${type.name}", found ${printNode(node)}.',
            _where(node, owner),
          );
          _value(node, null, false, owner);
          return;
        }
        Set<String> seen = <String>{};
        for (ObjectFieldNode f in node.fields) {
          String name = f.name.value;
          if (!seen.add(name)) {
            _error('There can be only one input field named "$name".', <Node>[
              f,
            ]);
          }
          InputField? def = type.field(name);
          if (def == null) {
            _error(
              'Field "$name" is not defined by type "${type.name}".',
              <Node>[f],
            );
          }
          _value(f.value, def?.type, def?.defaultValue != null, f);
        }
        for (InputField def in type.fields) {
          if (def.isRequired && !seen.contains(def.name)) {
            _error(
              'Field "${type.name}.${def.name}" of required type '
              '"${def.type}" was not provided.',
              _where(node, owner),
            );
          }
        }
      case EnumType<Object?>():
        if (node is! EnumValueNode) {
          _error(
            'Enum "${type.name}" cannot represent non-enum value: '
            '${printNode(node)}.',
            _where(node, owner),
          );
        } else if (type.valueNamed(node.name.value) == null) {
          _error(
            'Value "${node.name.value}" does not exist in "${type.name}" '
            'enum.',
            _where(node, owner),
          );
        }
      case ScalarType<Object>():
        try {
          type.parseLiteral(node);
        } on GraphQLError catch (e) {
          _error(
            'Expected value of type "${type.name}", found '
            '${printNode(node)}; ${e.message}',
            _where(node, owner),
          );
        } on Object {
          _error(
            'Expected value of type "${type.name}", found '
            '${printNode(node)}.',
            _where(node, owner),
          );
        }
      default:
        break;
    }
  }

  /// [node] when it has a location, else [owner].
  static List<Node> _where(ValueNode node, Node owner) =>
      GraphQLError.locationOf(node) != null ? <Node>[node] : <Node>[owner];

  /// The most work the fragment and variable checks may do.
  static const int _budget = 500000;
  int _work = 0;

  void _spend(int work) {
    _work += work;
    if (_work > _budget) throw const _TooComplex();
  }

  /// Marks every fragment that an operation reaches, in one walk for all
  /// operations.
  void _checkFragmentUse(Map<OperationDefinitionNode, _DefinitionUses> ops) {
    Set<String> used = <String>{};
    List<_DefinitionUses> todo = <_DefinitionUses>[...ops.values];
    while (todo.isNotEmpty) {
      List<FragmentSpreadNode> spreads = todo.removeLast().spreads;
      _spend(spreads.length);
      for (FragmentSpreadNode s in spreads) {
        String name = s.name.value;
        _DefinitionUses? next = _fragmentUses[name];
        if (next != null && used.add(name)) todo.add(next);
      }
    }
    for (FragmentDefinitionNode f in _fragments.values) {
      if (!used.contains(f.name.value)) {
        _error('Fragment "${f.name.value}" is never used.', <Node>[f]);
      }
    }
  }

  /// Finds fragment cycles. It uses its own stack, so a long fragment chain
  /// cannot use up the call stack.
  void _checkFragmentCycles() {
    Set<String> visited = <String>{};
    for (String start in _fragments.keys) {
      if (visited.contains(start)) continue;
      List<String> names = <String>[];
      List<int> nextSpread = <int>[];
      List<FragmentSpreadNode> path = <FragmentSpreadNode>[];
      Map<String, int> pathIndex = <String, int>{};
      visited.add(start);
      pathIndex[start] = 0;
      names.add(start);
      nextSpread.add(0);
      while (names.isNotEmpty) {
        String name = names.last;
        int i = nextSpread.last;
        List<FragmentSpreadNode> spreads =
            _fragmentUses[name]?.spreads ?? const <FragmentSpreadNode>[];
        if (i >= spreads.length) {
          names.removeLast();
          nextSpread.removeLast();
          pathIndex.remove(name);
          if (names.isNotEmpty) path.removeLast();
          continue;
        }
        nextSpread[nextSpread.length - 1] = i + 1;
        _spend(1);
        FragmentSpreadNode s = spreads[i];
        String target = s.name.value;
        int? index = pathIndex[target];
        if (index != null) {
          List<FragmentSpreadNode> cycle = <FragmentSpreadNode>[
            ...path.sublist(index),
            s,
          ];
          List<String> via = <String>[
            for (FragmentSpreadNode c in cycle.sublist(0, cycle.length - 1))
              c.name.value,
          ];
          _error(
            'Cannot spread fragment "$target" within itself'
            '${via.isEmpty ? '' : ' via ${via.join(', ')}'}.',
            cycle,
          );
          continue;
        }
        if (!_fragments.containsKey(target) || !visited.add(target)) continue;
        path.add(s);
        pathIndex[target] = path.length;
        names.add(target);
        nextSpread.add(0);
      }
    }
  }

  /// The variable uses of a fragment and all fragments it reaches, by
  /// name, place type and default. Uses with one key pass or fail the
  /// checks together, so each key is checked once per operation; every
  /// use of a failing key gets its own error. Each fragment is done once,
  /// with its own stack.
  final Map<String, Map<String, List<_VariableUsage>>> _fragmentVariables =
      <String, Map<String, List<_VariableUsage>>>{};

  static String _usageKey(_VariableUsage u) =>
      '${u.node.name.value}|${u.type}|${u.hasDefault}';

  Map<String, List<_VariableUsage>> _variablesOf(String fragment) {
    Map<String, List<_VariableUsage>>? known = _fragmentVariables[fragment];
    if (known != null) return known;
    Set<String> started = <String>{};
    List<String> stack = <String>[fragment];
    while (stack.isNotEmpty) {
      String name = stack.last;
      if (_fragmentVariables.containsKey(name)) {
        stack.removeLast();
        continue;
      }
      _DefinitionUses? uses = _fragmentUses[name];
      if (uses == null) {
        _fragmentVariables[name] = <String, List<_VariableUsage>>{};
        stack.removeLast();
        continue;
      }
      if (started.add(name)) {
        // First its fragments; a fragment in a cycle is skipped.
        for (FragmentSpreadNode s in uses.spreads) {
          String next = s.name.value;
          if (!_fragmentVariables.containsKey(next) &&
              !started.contains(next)) {
            stack.add(next);
          }
        }
        continue;
      }
      stack.removeLast();
      Map<String, List<_VariableUsage>> out = _ownVariables(uses);
      Set<String> spread = <String>{};
      for (FragmentSpreadNode s in uses.spreads) {
        if (!spread.add(s.name.value)) continue;
        Map<String, List<_VariableUsage>>? sub =
            _fragmentVariables[s.name.value];
        if (sub != null) _merge(out, sub);
      }
      _fragmentVariables[name] = out;
    }
    return _fragmentVariables[fragment]!;
  }

  void _merge(
    Map<String, List<_VariableUsage>> into,
    Map<String, List<_VariableUsage>> from,
  ) {
    for (MapEntry<String, List<_VariableUsage>> e in from.entries) {
      _spend(e.value.length);
      (into[e.key] ??= <_VariableUsage>[]).addAll(e.value);
    }
  }

  Map<String, List<_VariableUsage>> _ownVariables(_DefinitionUses uses) {
    _spend(uses.variables.length);
    Map<String, List<_VariableUsage>> out = <String, List<_VariableUsage>>{};
    for (_VariableUsage u in uses.variables) {
      (out[_usageKey(u)] ??= <_VariableUsage>[]).add(u);
    }
    return out;
  }

  void _addGroups(
    Map<String, List<List<_VariableUsage>>> groups,
    Map<String, List<_VariableUsage>> uses,
  ) {
    _spend(uses.length);
    for (MapEntry<String, List<_VariableUsage>> e in uses.entries) {
      (groups[e.key] ??= <List<_VariableUsage>>[]).add(e.value);
    }
  }

  void _checkVariables(OperationDefinitionNode op, _DefinitionUses uses) {
    String? opName = op.name?.value;
    Map<String, VariableDefinitionNode> defs = <String, VariableDefinitionNode>{
      for (VariableDefinitionNode d in op.variableDefinitions)
        d.variable.name.value: d,
    };
    // The use lists of each key, from the operation and its fragments.
    // They are not copied: only a failing key walks its uses.
    Map<String, List<List<_VariableUsage>>> groups =
        <String, List<List<_VariableUsage>>>{};
    _addGroups(groups, _ownVariables(uses));
    Set<String> spread = <String>{};
    for (FragmentSpreadNode s in uses.spreads) {
      if (spread.add(s.name.value)) {
        _addGroups(groups, _variablesOf(s.name.value));
      }
    }

    Set<String> used = <String>{};
    for (List<List<_VariableUsage>> lists in groups.values) {
      _VariableUsage first = lists.first.first;
      String name = first.node.name.value;
      used.add(name);
      VariableDefinitionNode? def = defs[name];
      GraphQLType? location = first.type;
      GraphQLType? varType = def == null
          ? null
          : Values.typeFromAst(schema, def.type);
      if (def != null &&
          (location == null ||
              varType == null ||
              !varType.isInputType ||
              _allowed(varType, def, location, first.hasDefault))) {
        continue;
      }
      // One error per use. A fragment reached twice gives its uses once.
      Set<VariableNode> reported = Set<VariableNode>.identity();
      for (List<_VariableUsage> list in lists) {
        for (_VariableUsage u in list) {
          if (!reported.add(u.node)) continue;
          if (def == null) {
            _error(
              opName == null
                  ? 'Variable "\$$name" is not defined.'
                  : 'Variable "\$$name" is not defined by operation '
                        '"$opName".',
              <Node>[u.node, op],
            );
          } else {
            _error(
              'Variable "\$$name" of type "$varType" used in position '
              'expecting type "$location".',
              <Node>[def, u.node],
            );
          }
        }
      }
    }
    for (VariableDefinitionNode d in op.variableDefinitions) {
      String name = d.variable.name.value;
      if (!used.contains(name)) {
        _error(
          opName == null
              ? 'Variable "\$$name" is never used.'
              : 'Variable "\$$name" is never used in operation "$opName".',
          <Node>[d],
        );
      }
    }
  }

  bool _allowed(
    GraphQLType varType,
    VariableDefinitionNode def,
    GraphQLType location,
    bool locationHasDefault,
  ) {
    if (location is NonNullType && varType is! NonNullType) {
      ValueNode? d = def.defaultValue?.value;
      bool varHasDefault = d != null && d is! NullValueNode;
      if (!varHasDefault && !locationHasDefault) return false;
      return _compatible(varType, location.ofType);
    }
    return _compatible(varType, location);
  }

  bool _compatible(GraphQLType v, GraphQLType l) {
    if (l is NonNullType) {
      return v is NonNullType && _compatible(v.ofType, l.ofType);
    }
    if (v is NonNullType) return _compatible(v.ofType, l);
    if (l is ListType) return v is ListType && _compatible(v.ofType, l.ofType);
    if (v is ListType) return false;
    return identical(v, l);
  }
}

final class _FieldEntry {
  _FieldEntry(this.parent, this.node, this.def);

  final NamedType? parent;
  final FieldNode node;
  final Field<Object?, Object?>? def;
}

/// Thrown when the overlap check needs too much work.
final class _TooComplex {
  const _TooComplex();
}

/// The "overlapping fields can be merged" rule: two fields with the same
/// response name must give one unambiguous value.
///
/// It is linear in normal queries: in a group of fields with the same
/// response name, each field is compared with one reference field, not
/// with every other field. Same name and same arguments is an equivalence,
/// so this finds the same conflicts. A work budget stops hostile queries.
final class _OverlapChecker {
  _OverlapChecker(this.schema, this.fragments, this.report);

  final Schema<Object?> schema;
  final Map<String, FragmentDefinitionNode> fragments;
  final void Function(GraphQLError error) report;

  /// The most field visits and comparisons one document may need.
  static const int _budget = 500000;
  int _work = 0;

  /// The collected fields of each selection set, with fragments expanded.
  final Map<SelectionSetNode, Map<String, List<_FieldEntry>>> _collected =
      Map<SelectionSetNode, Map<String, List<_FieldEntry>>>.identity();

  /// Pairs already compared, as exclusive or not.
  final Map<FieldNode, Set<FieldNode>> _done =
      Map<FieldNode, Set<FieldNode>>.identity();
  final Map<FieldNode, Set<FieldNode>> _doneExclusive =
      Map<FieldNode, Set<FieldNode>>.identity();

  void checkDocument(DocumentNode document) {
    try {
      for (DefinitionNode d in document.definitions) {
        if (d is OperationDefinitionNode) {
          _visit(d.selectionSet, schema.rootType(d.type), true);
        } else if (d is FragmentDefinitionNode) {
          // The fields at the top of a fragment are compared where the
          // fragment is spread. Only its inner selections are checked here.
          _visit(
            d.selectionSet,
            _composite(d.typeCondition.on.name.value),
            false,
          );
        }
      }
    } on _TooComplex {
      report(GraphQLError('The query is too complex to validate.'));
    }
  }

  void _spend(int work) {
    _work += work;
    if (_work > _budget) throw const _TooComplex();
  }

  NamedType? _composite(String name) {
    NamedType? t = schema.type(name);
    return t != null && t.isComposite ? t : null;
  }

  NamedType? _subType(Field<Object?, Object?>? def) {
    NamedType? t = def?.type.namedType;
    return t != null && t.isComposite ? t : null;
  }

  /// Checks a selection set from the text, and the sets inside it.
  void _visit(SelectionSetNode set, NamedType? parent, bool compare) {
    if (compare) {
      for (List<_FieldEntry> group in _collect(set, parent).values) {
        _group(group, false);
      }
    }
    for (SelectionNode s in set.selections) {
      switch (s) {
        case FieldNode():
          SelectionSetNode? sub = s.selectionSet;
          if (sub == null) continue;
          Field<Object?, Object?>? def = parent == null
              ? null
              : schema.field(parent, s.name.value);
          _visit(sub, _subType(def), true);
        case InlineFragmentNode():
          // Its fields are in the collected fields of [set].
          NamedTypeNode? on = s.typeCondition?.on;
          _visit(
            s.selectionSet,
            on == null ? parent : _composite(on.name.value),
            false,
          );
        default:
          break;
      }
    }
  }

  Map<String, List<_FieldEntry>> _collect(
    SelectionSetNode set,
    NamedType? parent,
  ) {
    return _collected[set] ??= _collectInto(
      set,
      parent,
      <String, List<_FieldEntry>>{},
      <String>{},
    );
  }

  Map<String, List<_FieldEntry>> _collectInto(
    SelectionSetNode set,
    NamedType? parent,
    Map<String, List<_FieldEntry>> out,
    Set<String> seen,
  ) {
    _spend(set.selections.length);
    for (SelectionNode s in set.selections) {
      switch (s) {
        case FieldNode():
          Field<Object?, Object?>? def = parent == null
              ? null
              : schema.field(parent, s.name.value);
          String key = (s.alias ?? s.name).value;
          (out[key] ??= <_FieldEntry>[]).add(_FieldEntry(parent, s, def));
        case InlineFragmentNode():
          NamedTypeNode? on = s.typeCondition?.on;
          _collectInto(
            s.selectionSet,
            on == null ? parent : _composite(on.name.value),
            out,
            seen,
          );
        case FragmentSpreadNode():
          FragmentDefinitionNode? f = fragments[s.name.value];
          if (f != null && seen.add(s.name.value)) {
            _collectInto(
              f.selectionSet,
              _composite(f.typeCondition.on.name.value),
              out,
              seen,
            );
          }
        default:
          break;
      }
    }
    return out;
  }

  /// Checks a group of fields with one response name.
  ///
  /// Two fields must have the same name and arguments, unless their
  /// parents are different object types. So each field is compared with a
  /// field it must match: the first one with a non-object parent, else the
  /// first one with the same parent. The first fields of each parent are
  /// compared with the first field of the group, for the response shape.
  ///
  /// Then the sub fields of the whole group are merged and checked the
  /// same way, so a conflict between any two fields deep inside is found.
  void _group(List<_FieldEntry> group, bool parentsExclusive) {
    if (group.length < 2) return;
    _FieldEntry first = group.first;
    _FieldEntry? nonObject;
    for (_FieldEntry e in group) {
      if (e.parent is! ObjectType<Object?, Object?>) {
        nonObject = e;
        break;
      }
    }
    Map<NamedType?, List<_FieldEntry>> byParent =
        Map<NamedType?, List<_FieldEntry>>.identity();
    bool conflict = false;
    for (_FieldEntry e in group) {
      List<_FieldEntry> same = byParent[e.parent] ??= <_FieldEntry>[];
      same.add(e);
      _FieldEntry reference;
      if (parentsExclusive) {
        reference = first;
      } else if (nonObject != null) {
        reference = nonObject;
      } else {
        reference = same.first;
        if (identical(reference, e)) reference = first;
      }
      if (!identical(reference.node, e.node) &&
          _pair(reference, e, parentsExclusive)) {
        conflict = true;
      }
    }
    // Like the spec, stop at the first conflict of a group.
    if (conflict) return;
    if (parentsExclusive || nonObject != null) {
      // All pairs are exclusive, or none is.
      _subFields(group, parentsExclusive);
      return;
    }
    // Fields with one parent must merge. Fields with different object
    // parents must only have the same shape.
    for (List<_FieldEntry> same in byParent.values) {
      _subFields(same, false);
    }
    if (byParent.length > 1) _subFields(group, true);
  }

  /// Merges the sub fields of [group] and checks them.
  void _subFields(List<_FieldEntry> group, bool exclusive) {
    Map<String, List<_FieldEntry>> merged = <String, List<_FieldEntry>>{};
    Set<FieldNode> seen = Set<FieldNode>.identity();
    int sets = 0;
    for (_FieldEntry e in group) {
      SelectionSetNode? set = e.node.selectionSet;
      if (set == null) continue;
      sets++;
      for (MapEntry<String, List<_FieldEntry>> sub in _collect(
        set,
        _subType(e.def),
      ).entries) {
        _spend(sub.value.length);
        List<_FieldEntry> list = merged[sub.key] ??= <_FieldEntry>[];
        for (_FieldEntry x in sub.value) {
          if (seen.add(x.node)) list.add(x);
        }
      }
    }
    if (sets < 2) return;
    for (List<_FieldEntry> list in merged.values) {
      _group(list, exclusive);
    }
  }

  bool _markDone(FieldNode a, FieldNode b, bool exclusive) {
    Map<FieldNode, Set<FieldNode>> done = exclusive ? _doneExclusive : _done;
    Set<FieldNode> forA = done[a] ??= Set<FieldNode>.identity();
    if (!forA.add(b)) return false;
    (done[b] ??= Set<FieldNode>.identity()).add(a);
    return true;
  }

  /// Compares two fields: names, arguments and types. True on a conflict.
  /// Their sub fields are checked by [_group].
  bool _pair(_FieldEntry a, _FieldEntry b, bool parentsExclusive) {
    _spend(1);
    bool exclusive =
        parentsExclusive ||
        (!identical(a.parent, b.parent) &&
            a.parent is ObjectType<Object?, Object?> &&
            b.parent is ObjectType<Object?, Object?>);
    if (!_markDone(a.node, b.node, exclusive)) return false;
    String key = (a.node.alias ?? a.node.name).value;
    String? reason;
    if (!exclusive) {
      String nameA = a.node.name.value;
      String nameB = b.node.name.value;
      if (nameA != nameB) {
        reason = '"$nameA" and "$nameB" are different fields';
      } else if (!_sameArguments(a.node.arguments, b.node.arguments)) {
        reason = 'they have differing arguments';
      }
    }
    Field<Object?, Object?>? defA = a.def;
    Field<Object?, Object?>? defB = b.def;
    if (reason == null &&
        defA != null &&
        defB != null &&
        _typesConflict(defA.type, defB.type)) {
      reason =
          'they return conflicting types "${defA.type}" and "${defB.type}"';
    }
    if (reason == null) return false;
    report(
      GraphQLError.at(
        'Fields "$key" conflict because $reason. Use different aliases on '
        'the fields to fetch both if this was intentional.',
        <Node>[a.node, b.node],
      ),
    );
    return true;
  }

  bool _sameArguments(List<ArgumentNode> a, List<ArgumentNode> b) {
    if (a.length != b.length) return false;
    for (ArgumentNode x in a) {
      ArgumentNode? y;
      for (ArgumentNode n in b) {
        if (n.name.value == x.name.value) y = n;
      }
      if (y == null || printNode(x.value) != printNode(y.value)) return false;
    }
    return true;
  }

  bool _typesConflict(GraphQLType a, GraphQLType b) {
    if (a is ListType) {
      return b is ListType ? _typesConflict(a.ofType, b.ofType) : true;
    }
    if (b is ListType) return true;
    if (a is NonNullType) {
      return b is NonNullType ? _typesConflict(a.ofType, b.ofType) : true;
    }
    if (b is NonNullType) return true;
    if ((a is NamedType && a.isLeaf) || (b is NamedType && b.isLeaf)) {
      return !identical(a, b);
    }
    return false;
  }
}
