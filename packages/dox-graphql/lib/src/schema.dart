import 'package:gql/ast.dart';

import 'errors.dart';
import 'introspection.dart';
import 'types.dart';
import 'values.dart';

/// A GraphQL schema: the root types and every type they reach.
///
/// [C] is the type of the context object that every resolver gets.
/// The schema is checked when it is built. A bad schema throws a
/// [SchemaError] with all problems.
///
/// Subscriptions are not supported yet. A `subscription` root will be
/// added next to [query] and [mutation].
final class GraphQLSchema<C> {
  GraphQLSchema({
    required this.query,
    this.mutation,
    List<NamedType> types = const <NamedType>[],
    this.description,
  }) {
    List<String> problems = <String>[];
    _collect(query, problems);
    ObjectType<Object?, C>? mutation = this.mutation;
    if (mutation != null) _collect(mutation, problems);
    for (NamedType t in types) {
      _collect(t, problems);
    }
    for (NamedType t in Introspection.types) {
      _collect(t, problems);
    }
    for (NamedType t in typeMap.values) {
      List<InterfaceType> interfaces = switch (t) {
        ObjectType<Object?, Object?>() => t.interfaces,
        InterfaceType() => t.interfaces,
        _ => const <InterfaceType>[],
      };
      for (InterfaceType i in interfaces) {
        (_implementations[i] ??= <NamedType>[]).add(t);
      }
    }
    if (problems.isEmpty) _SchemaChecker(this, problems).check();
    if (problems.isNotEmpty) throw SchemaError(problems);
  }

  final ObjectType<Object?, C> query;
  final ObjectType<Object?, C>? mutation;
  final String? description;

  /// Every named type, by name.
  final Map<String, NamedType> typeMap = <String, NamedType>{};

  final Map<InterfaceType, List<NamedType>> _implementations =
      Map<InterfaceType, List<NamedType>>.identity();
  final Map<NamedType, List<ObjectType<Object?, Object?>>> _possible =
      Map<NamedType, List<ObjectType<Object?, Object?>>>.identity();

  /// The directives this schema knows.
  List<Directive> get directives => Introspection.directives;

  /// The named type with this name, or null.
  NamedType? type(String name) => typeMap[name];

  /// The directive with this name, or null.
  Directive? directive(String name) {
    for (Directive d in directives) {
      if (d.name == name) return d;
    }
    return null;
  }

  /// The root type of an operation type, or null when the schema has none.
  ObjectType<Object?, C>? rootType(OperationType operation) {
    return switch (operation) {
      OperationType.query => query,
      OperationType.mutation => mutation,
      OperationType.subscription => null,
    };
  }

  /// The object types a value of an abstract type can have. For an object
  /// type, just that type.
  List<ObjectType<Object?, Object?>> possibleTypes(NamedType type) {
    return _possible[type] ??= switch (type) {
      ObjectType<Object?, Object?>() => <ObjectType<Object?, Object?>>[type],
      UnionType() => type.types,
      InterfaceType() => <ObjectType<Object?, Object?>>[
        for (NamedType t in _implementations[type] ?? const <NamedType>[])
          if (t is ObjectType<Object?, Object?>) t,
      ],
      _ => const <ObjectType<Object?, Object?>>[],
    };
  }

  /// True when [sub] is a member of the union, or implements the interface.
  bool isSubType(NamedType abstractType, NamedType sub) {
    return switch (abstractType) {
      UnionType() => abstractType.types.any(
        (ObjectType<Object?, Object?> t) => identical(t, sub),
      ),
      InterfaceType() =>
        (_implementations[abstractType] ?? const <NamedType>[]).any(
          (NamedType t) => identical(t, sub),
        ),
      _ => false,
    };
  }

  /// The field [name] on [parent], with the meta fields `__typename`,
  /// `__schema` and `__type`. Null when there is no such field.
  Field<Object?, Object?>? field(NamedType parent, String name) {
    if (name.startsWith('__')) {
      if (name == '__typename' && parent.isComposite) {
        return Introspection.typenameField;
      }
      if (identical(parent, query)) {
        if (name == '__schema') return Introspection.schemaField;
        if (name == '__type') return Introspection.typeField;
      }
    }
    return switch (parent) {
      ObjectType<Object?, Object?>() => parent.field(name),
      InterfaceType() => parent.field(name),
      _ => null,
    };
  }

  void _collect(NamedType type, List<String> problems) {
    NamedType? known = typeMap[type.name];
    if (known != null) {
      if (!identical(known, type)) {
        problems.add(
          'Schema must contain uniquely named types but contains multiple '
          'types named "${type.name}".',
        );
      }
      return;
    }
    typeMap[type.name] = type;
    switch (type) {
      case ObjectType<Object?, Object?>():
        for (InterfaceType i in type.interfaces) {
          _collect(i, problems);
        }
        _collectFields(type.fields, problems);
      case InterfaceType():
        for (InterfaceType i in type.interfaces) {
          _collect(i, problems);
        }
        _collectFields(type.fields, problems);
      case UnionType():
        for (ObjectType<Object?, Object?> t in type.types) {
          _collect(t, problems);
        }
      case InputObjectType():
        for (InputField f in type.fields) {
          _collect(f.type.namedType, problems);
        }
      case ScalarType<Object>() || EnumType<Object?>():
        break;
    }
  }

  void _collectFields(
    List<Field<Object?, Object?>> fields,
    List<String> problems,
  ) {
    for (Field<Object?, Object?> f in fields) {
      _collect(f.type.namedType, problems);
      for (Argument a in f.args) {
        _collect(a.type.namedType, problems);
      }
    }
  }
}

/// Checks the type system rules of the spec.
final class _SchemaChecker {
  _SchemaChecker(this.schema, this.problems);

  final GraphQLSchema<Object?> schema;
  final List<String> problems;

  static final RegExp _name = RegExp(r'^[_A-Za-z][_0-9A-Za-z]*$');

  void check() {
    for (NamedType t in schema.typeMap.values) {
      bool builtIn = Introspection.types.contains(t);
      if (!builtIn) _checkName(t.name, 'Type');
      switch (t) {
        case ObjectType<Object?, Object?>():
          _checkFields(t, t.fields);
          _checkInterfaces(t, t.interfaces);
        case InterfaceType():
          _checkFields(t, t.fields);
          _checkInterfaces(t, t.interfaces);
        case UnionType():
          _checkUnion(t);
        case EnumType<Object?>():
          _checkEnum(t);
        case InputObjectType():
          _checkInputObject(t);
        case ScalarType<Object>():
          break;
      }
    }
    _checkInputCycles();
    for (Directive d in schema.directives) {
      for (Argument a in d.args) {
        _checkDefault(a, '@${d.name}(${a.name}:)');
      }
    }
  }

  void _checkName(String name, String what) {
    if (!_name.hasMatch(name)) {
      problems.add(
        '$what name "$name" must match /^[_a-zA-Z][_a-zA-Z0-9]*\$/.',
      );
    } else if (name.startsWith('__')) {
      problems.add(
        '$what name "$name" must not begin with "__", which is reserved by '
        'GraphQL introspection.',
      );
    }
  }

  bool _isIntrospection(NamedType t) => Introspection.types.contains(t);

  void _checkFields(NamedType type, List<Field<Object?, Object?>> fields) {
    if (fields.isEmpty) {
      problems.add('Type ${type.name} must define one or more fields.');
    }
    Set<String> names = <String>{};
    for (Field<Object?, Object?> f in fields) {
      String at = '${type.name}.${f.name}';
      if (!_isIntrospection(type)) _checkName(f.name, 'Field');
      if (!names.add(f.name)) {
        problems.add('Field $at can only be defined once.');
      }
      if (!f.type.isOutputType) {
        problems.add('The type of $at must be Output Type but got: ${f.type}.');
      }
      _checkArgs(f.args, at);
    }
  }

  void _checkArgs(List<Argument> args, String at) {
    Set<String> names = <String>{};
    for (Argument a in args) {
      String argAt = '$at(${a.name}:)';
      _checkName(a.name, 'Argument');
      if (!names.add(a.name)) {
        problems.add('Argument $argAt can only be defined once.');
      }
      if (!a.type.isInputType) {
        problems.add(
          'The type of $argAt must be Input Type but got: ${a.type}.',
        );
      }
      if (a.isRequired && a.isDeprecated) {
        problems.add('Required argument $argAt cannot be deprecated.');
      }
      _checkDefault(a, argAt);
    }
  }

  void _checkDefault(Argument a, String at) {
    if (a.defaultValue == null || !a.type.isInputType) return;
    ValueNode node;
    try {
      node = a.defaultLiteral!;
    } on Object {
      problems.add(
        'Default value of $at is not a GraphQL literal: ${a.defaultValue}',
      );
      return;
    }
    if (identical(Values.fromLiteral(a.type, node, null), Values.invalid)) {
      problems.add(
        'Default value of $at is not valid for type "${a.type}": '
        '${a.defaultValue}',
      );
    }
  }

  void _checkInterfaces(NamedType type, List<InterfaceType> interfaces) {
    Set<InterfaceType> seen = Set<InterfaceType>.identity();
    for (InterfaceType i in interfaces) {
      if (identical(i, type)) {
        problems.add(
          'Type ${type.name} cannot implement itself because it would '
          'create a circular reference.',
        );
        continue;
      }
      if (!seen.add(i)) {
        problems.add('Type ${type.name} can only implement ${i.name} once.');
        continue;
      }
      for (InterfaceType transitive in i.interfaces) {
        if (!identical(transitive, type) &&
            !interfaces.any((InterfaceType x) => identical(x, transitive))) {
          problems.add(
            'Type ${type.name} must implement ${transitive.name} because it '
            'is implemented by ${i.name}.',
          );
        }
      }
      _checkImplementation(type, i);
    }
  }

  Field<Object?, Object?>? _fieldOf(NamedType type, String name) {
    return switch (type) {
      ObjectType<Object?, Object?>() => type.field(name),
      InterfaceType() => type.field(name),
      _ => null,
    };
  }

  void _checkImplementation(NamedType type, InterfaceType i) {
    for (Field<Object?, Object?> iField in i.fields) {
      String iAt = '${i.name}.${iField.name}';
      String tAt = '${type.name}.${iField.name}';
      Field<Object?, Object?>? tField = _fieldOf(type, iField.name);
      if (tField == null) {
        problems.add(
          'Interface field $iAt expected but ${type.name} does not provide '
          'it.',
        );
        continue;
      }
      if (!_isValidImplementationType(tField.type, iField.type)) {
        problems.add(
          'Interface field $iAt expects type ${iField.type} but $tAt is '
          'type ${tField.type}.',
        );
      }
      for (Argument iArg in iField.args) {
        Argument? tArg = tField.arg(iArg.name);
        if (tArg == null) {
          problems.add(
            'Interface field argument $iAt(${iArg.name}:) expected but $tAt '
            'does not provide it.',
          );
        } else if (tArg.type != iArg.type) {
          problems.add(
            'Interface field argument $iAt(${iArg.name}:) expects type '
            '${iArg.type} but $tAt(${iArg.name}:) is type ${tArg.type}.',
          );
        }
      }
      for (Argument tArg in tField.args) {
        if (iField.arg(tArg.name) == null && tArg.isRequired) {
          problems.add(
            'Object field $tAt includes required argument ${tArg.name} that '
            'is missing from the Interface field $iAt.',
          );
        }
      }
    }
  }

  bool _isValidImplementationType(
    GraphQLTypeRef field,
    GraphQLTypeRef expected,
  ) {
    if (expected is NonNullType) {
      return field is NonNullType &&
          _isValidImplementationType(field.ofType, expected.ofType);
    }
    if (field is NonNullType) {
      return _isValidImplementationType(field.ofType, expected);
    }
    if (expected is ListType) {
      return field is ListType &&
          _isValidImplementationType(field.ofType, expected.ofType);
    }
    if (field is ListType) return false;
    if (identical(field, expected)) return true;
    return expected is NamedType &&
        field is NamedType &&
        expected.isAbstract &&
        (field is ObjectType<Object?, Object?> || field is InterfaceType) &&
        schema.isSubType(expected, field);
  }

  void _checkUnion(UnionType u) {
    if (u.types.isEmpty) {
      problems.add(
        'Union type ${u.name} must define one or more member types.',
      );
    }
    Set<NamedType> seen = Set<NamedType>.identity();
    for (ObjectType<Object?, Object?> t in u.types) {
      if (!seen.add(t)) {
        problems.add(
          'Union type ${u.name} can only include type ${t.name} once.',
        );
      }
    }
  }

  void _checkEnum(EnumType<Object?> e) {
    if (e.values.isEmpty) {
      problems.add('Enum type ${e.name} must define one or more values.');
    }
    Set<String> names = <String>{};
    for (EnumValue<Object?> v in e.values) {
      if (!_isIntrospection(e)) _checkName(v.name, 'Enum value');
      if (v.name == 'true' || v.name == 'false' || v.name == 'null') {
        problems.add('Enum type ${e.name} cannot include value: ${v.name}.');
      }
      if (!names.add(v.name)) {
        problems.add(
          'Enum value ${e.name}.${v.name} can only be defined once.',
        );
      }
    }
  }

  void _checkInputObject(InputObjectType t) {
    if (t.fields.isEmpty) {
      problems.add(
        'Input Object type ${t.name} must define one or more fields.',
      );
    }
    Set<String> names = <String>{};
    for (InputField f in t.fields) {
      String at = '${t.name}.${f.name}';
      _checkName(f.name, 'Field');
      if (!names.add(f.name)) {
        problems.add('Input field $at can only be defined once.');
      }
      if (!f.type.isInputType) {
        problems.add('The type of $at must be Input Type but got: ${f.type}.');
      }
      if (f.isRequired && f.isDeprecated) {
        problems.add('Required input field $at cannot be deprecated.');
      }
      _checkDefault(f, at);
    }
  }

  /// An input object cannot point at itself through non-null fields only:
  /// no value could ever be given.
  void _checkInputCycles() {
    Set<InputObjectType> done = Set<InputObjectType>.identity();
    for (NamedType t in schema.typeMap.values) {
      if (t is InputObjectType) _visitInput(t, <InputField>[], done, t);
    }
  }

  void _visitInput(
    InputObjectType type,
    List<InputField> path,
    Set<InputObjectType> done,
    InputObjectType start,
  ) {
    if (done.contains(type) && !identical(type, start)) return;
    for (InputField f in type.fields) {
      GraphQLTypeRef ft = f.type;
      if (ft is! NonNullType) continue;
      GraphQLTypeRef inner = ft.ofType;
      if (inner is! InputObjectType) continue;
      if (identical(inner, start)) {
        String via = <String>[
          for (InputField p in path) p.name,
          f.name,
        ].join('.');
        problems.add(
          'Cannot reference Input Object "${start.name}" within itself '
          'through a series of non-null fields: "$via".',
        );
        continue;
      }
      if (path.any((InputField p) => identical(p, f))) continue;
      _visitInput(inner, <InputField>[...path, f], done, start);
    }
    if (identical(type, start)) done.add(type);
  }
}
