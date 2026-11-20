import 'dart:async';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:meta/meta.dart';

import 'errors.dart';
import 'schema.dart';

/// Any GraphQL type: a named type, or a list or non-null wrapper.
sealed class GraphQLTypeRef {
  const GraphQLTypeRef();

  /// A list of this type: `[T]`.
  ListType get list => ListType(this);

  /// This type, but null is not allowed: `T!`.
  NonNullType get nonNull => NonNullType(this);

  /// The named type inside all wrappers.
  NamedType get namedType;

  /// This type without the outer non-null wrapper.
  GraphQLTypeRef get nullable => this;

  /// True for scalars, enums, input objects and wrappers of them.
  bool get isInputType;

  /// True for every type but input objects and wrappers of them.
  bool get isOutputType;
}

/// A list wrapper: `[T]`.
final class ListType extends GraphQLTypeRef {
  ListType(this.ofType);

  final GraphQLTypeRef ofType;

  @override
  NamedType get namedType => ofType.namedType;

  @override
  bool get isInputType => ofType.isInputType;

  @override
  bool get isOutputType => ofType.isOutputType;

  @override
  bool operator ==(Object other) => other is ListType && other.ofType == ofType;

  @override
  int get hashCode => Object.hash('[]', ofType);

  @override
  String toString() => '[$ofType]';
}

/// A non-null wrapper: `T!`.
final class NonNullType extends GraphQLTypeRef {
  NonNullType(this.ofType) {
    if (ofType is NonNullType) {
      throw ArgumentError('A non-null type cannot wrap a non-null type.');
    }
  }

  final GraphQLTypeRef ofType;

  @override
  NonNullType get nonNull => this;

  @override
  GraphQLTypeRef get nullable => ofType;

  @override
  NamedType get namedType => ofType.namedType;

  @override
  bool get isInputType => ofType.isInputType;

  @override
  bool get isOutputType => ofType.isOutputType;

  @override
  bool operator ==(Object other) =>
      other is NonNullType && other.ofType == ofType;

  @override
  int get hashCode => Object.hash('!', ofType);

  @override
  String toString() => '$ofType!';
}

/// A type with a name. Two named types are equal only when they are the
/// same object.
sealed class NamedType extends GraphQLTypeRef {
  NamedType(this.name, {this.description});

  final String name;
  final String? description;

  @override
  NamedType get namedType => this;

  /// Scalars and enums: they have no sub fields.
  bool get isLeaf => false;

  /// Objects, interfaces and unions: they need a selection of fields.
  bool get isComposite => false;

  /// Interfaces and unions.
  bool get isAbstract => false;

  @override
  bool get isInputType => false;

  @override
  bool get isOutputType => true;

  @override
  String toString() => name;
}

/// A scalar type. Extend it to make a custom scalar.
///
/// [I] is the Dart type of the value that resolvers get in their
/// arguments. The methods work on JSON values, so their parameters are
/// loose: [serialize] gets the value a resolver returned, [parseValue]
/// gets a value from the request JSON. Throw a [GraphQLError] when a value
/// is not valid.
abstract class ScalarType<I extends Object> extends NamedType {
  ScalarType(super.name, {super.description, this.specifiedByUrl});

  /// A link to the spec of this scalar, shown in introspection.
  final String? specifiedByUrl;

  /// Turns a resolved value into a JSON value for the response.
  Object serialize(Object value);

  /// Turns a JSON value from the request variables into the input value.
  I parseValue(Object value);

  /// Turns a literal in the query into the input value. The literal is
  /// never a variable or null.
  I parseLiteral(ValueNode node);

  @override
  bool get isLeaf => true;

  @override
  bool get isInputType => true;
}

/// One value of an [EnumType].
final class EnumValue<T> {
  EnumValue(this.name, this.value, {this.description, this.deprecationReason});

  /// The name in the query and the response, like `NEWHOPE`.
  final String name;

  /// The Dart value that resolvers return and get in arguments.
  final T value;
  final String? description;
  final String? deprecationReason;

  bool get isDeprecated => deprecationReason != null;
}

/// An enum type. [T] is the Dart value of each enum value.
class EnumType<T> extends NamedType {
  EnumType(super.name, this.values, {super.description});

  final List<EnumValue<T>> values;

  late final Map<String, EnumValue<T>> _byName = <String, EnumValue<T>>{
    for (EnumValue<T> v in values) v.name: v,
  };

  /// The enum value with this name, or null.
  EnumValue<T>? valueNamed(String name) => _byName[name];

  @override
  bool get isLeaf => true;

  @override
  bool get isInputType => true;

  @internal
  String serialize(Object value) {
    for (EnumValue<T> v in values) {
      if (v.value == value) return v.name;
    }
    throw GraphQLError('Enum "$name" cannot represent value: $value');
  }

  @internal
  T parseValue(Object value) {
    EnumValue<T>? v = value is String ? _byName[value] : null;
    if (v == null) {
      throw GraphQLError('Value "$value" does not exist in "$name" enum.');
    }
    return v.value;
  }

  @internal
  T parseLiteral(ValueNode node) {
    EnumValue<T>? v = node is EnumValueNode ? _byName[node.name.value] : null;
    if (v == null) {
      throw GraphQLError(
        'Value "${printNode(node)}" does not exist in "$name" enum.',
      );
    }
    return v.value;
  }
}

/// An argument of a field or directive, or a field of an input object.
final class Argument {
  Argument(
    this.name,
    this.type, {
    this.description,
    this.defaultValue,
    this.deprecationReason,
  });

  final String name;
  final GraphQLTypeRef type;
  final String? description;

  /// The default as GraphQL literal text, like `10`, `"hi"`, `NEWHOPE`,
  /// `[1, 2]` or `{limit: 5}`. It is checked when the schema is built.
  final String? defaultValue;

  /// Only nullable arguments, or ones with a default, can be deprecated.
  final String? deprecationReason;

  bool get isDeprecated => deprecationReason != null;

  /// True when the type is non-null and there is no default.
  bool get isRequired => type is NonNullType && defaultValue == null;

  /// The parsed [defaultValue]. Throws when the text is not a literal.
  @internal
  late final ValueNode? defaultLiteral = defaultValue == null
      ? null
      : parseLiteralText(defaultValue!);

  /// Parses GraphQL literal text, like `{a: [1, 2]}`.
  @internal
  static ValueNode parseLiteralText(String text) {
    DocumentNode doc = parseString('{f(a: $text)}');
    List<SelectionNode> fields =
        (doc.definitions.single as OperationDefinitionNode)
            .selectionSet
            .selections;
    if (fields.length != 1) throw FormatException('Not a literal: $text');
    List<ArgumentNode> args = (fields.single as FieldNode).arguments;
    if (args.length != 1) throw FormatException('Not a literal: $text');
    return args.single.value;
  }
}

/// A field of an input object. It has the same parts as an [Argument].
typedef InputField = Argument;

/// Turns the parent value into the field value. It can return a value or a
/// Future. The return value is loose: it is response data, checked against
/// the field type when the field is completed.
typedef FieldResolver<S, C> = FutureOr<Object?> Function(
  S source,
  ResolveInfo<C> info,
);

/// A field of an object or interface type.
///
/// [S] is the Dart type of the parent value. [C] is the type of the
/// context object of the request.
class Field<S, C> {
  Field(
    this.name,
    this.type, {
    this.description,
    this.args = const <Argument>[],
    this.deprecationReason,
    this._resolve,
    this.auth,
  });

  final String name;
  final GraphQLTypeRef type;
  final String? description;
  final List<Argument> args;
  final String? deprecationReason;
  final FieldResolver<S, C>? _resolve;

  /// True: the field needs a logged-in user. False: the field is public.
  /// Null: the default of the server. The engine only keeps this value;
  /// a [FieldGuard] given to the executor checks it.
  final bool? auth;

  bool get isDeprecated => deprecationReason != null;

  /// The argument with this name, or null.
  Argument? arg(String name) {
    for (Argument a in args) {
      if (a.name == name) return a;
    }
    return null;
  }

  /// Runs the resolver. Without a resolver, a `Map` parent gives the value
  /// under the field name, and any other parent gives null.
  @internal
  FutureOr<Object?> resolveFor(Object? source, ResolveInfo<Object?> info) {
    FieldResolver<S, C>? resolve = _resolve;
    if (resolve == null) {
      return source is Map<String, Object?> ? source[name] : null;
    }
    return resolve(source as S, info.withContext<C>(info.context as C));
  }
}

/// The context of one field resolve.
final class ResolveInfo<C> {
  @internal
  ResolveInfo({
    required this.context,
    required this.args,
    required this.fieldName,
    required this.fieldNodes,
    required this.parentType,
    required this.returnType,
    required this.schema,
    required this.operation,
    required this.fragments,
    required this.variables,
    required this._responsePath,
  });

  /// The context object given to `execute`.
  final C context;

  /// The coerced arguments of the field.
  final InputValues args;
  final String fieldName;

  /// The query nodes of this field. More than one when the query asks for
  /// the same field twice. Useful to look ahead at the sub selection.
  final List<FieldNode> fieldNodes;
  final ObjectType<Object?, Object?> parentType;
  final GraphQLTypeRef returnType;
  final GraphQLSchema<Object?> schema;
  final OperationDefinitionNode operation;
  final Map<String, FragmentDefinitionNode> fragments;

  /// The coerced variables of the request.
  final InputValues variables;
  final ResponsePath _responsePath;

  /// The response path of this field.
  late final List<PathSegment> path = _responsePath.toList();

  @internal
  ResolveInfo<T> withContext<T>(T context) {
    return ResolveInfo<T>(
      context: context,
      args: args,
      fieldName: fieldName,
      fieldNodes: fieldNodes,
      parentType: parentType,
      returnType: returnType,
      schema: schema,
      operation: operation,
      fragments: fragments,
      variables: variables,
      responsePath: _responsePath,
    );
  }
}

/// A linked response path. Cheap to grow, turned into a list only when
/// needed.
@internal
final class ResponsePath {
  const ResponsePath(this.prev, this.segment);

  final ResponsePath? prev;
  final PathSegment segment;

  ResponsePath key(String key) => ResponsePath(this, PathKey(key));

  ResponsePath index(int index) => ResponsePath(this, PathIndex(index));

  List<PathSegment> toList() {
    List<PathSegment> out = <PathSegment>[];
    for (ResponsePath? p = this; p != null; p = p.prev) {
      out.add(p.segment);
    }
    return out.reversed.toList();
  }
}

/// An object type. [S] is the Dart type of the values it is made from,
/// [C] the type of the request context.
///
/// [fields] is a function, so that types can point at each other.
/// Without [isTypeOf], a value belongs to this type when it is an [S].
/// For an interface or union, that Dart check must pick exactly one
/// possible type. Two types made from the same Dart type (like two `Map`
/// types) need [isTypeOf], or `resolveType` on the interface or union.
class ObjectType<S, C> extends NamedType {
  ObjectType(
    super.name, {
    super.description,
    required this._fields,
    this.interfaces = const <InterfaceType>[],
    this._isTypeOf,
  });

  final List<Field<S, C>> Function() _fields;
  final bool Function(Object value)? _isTypeOf;
  final List<InterfaceType> interfaces;

  late final List<Field<S, C>> fields = _fields();

  late final Map<String, Field<S, C>> _byName = <String, Field<S, C>>{
    for (Field<S, C> f in fields) f.name: f,
  };

  /// The field with this name, or null.
  Field<S, C>? field(String name) => _byName[name];

  /// True when an `isTypeOf` function was given.
  bool get hasIsTypeOf => _isTypeOf != null;

  /// True when [value] belongs to this type.
  bool isTypeOf(Object value) {
    bool Function(Object value)? check = _isTypeOf;
    return check != null ? check(value) : value is S;
  }

  @override
  bool get isComposite => true;
}

/// Picks the object type of a value of an interface or union.
typedef TypeResolver = ObjectType<Object?, Object?>? Function(Object value);

/// An interface type. Its fields have no resolvers: the object types that
/// implement it resolve them.
class InterfaceType extends NamedType {
  InterfaceType(
    super.name, {
    super.description,
    required this._fields,
    this.interfaces = const <InterfaceType>[],
    this.resolveType,
  });

  final List<Field<Object?, Object?>> Function() _fields;
  final List<InterfaceType> interfaces;

  /// Picks the object type of a value. Without it, a `Map` value with a
  /// `__typename` key is used. Then a possible type whose explicit
  /// `isTypeOf` is true. Then the one possible type whose Dart type
  /// matches; when none or more than one match, the field fails.
  final TypeResolver? resolveType;

  late final List<Field<Object?, Object?>> fields = _fields();

  late final Map<String, Field<Object?, Object?>> _byName =
      <String, Field<Object?, Object?>>{
        for (Field<Object?, Object?> f in fields) f.name: f,
      };

  /// The field with this name, or null.
  Field<Object?, Object?>? field(String name) => _byName[name];

  @override
  bool get isComposite => true;

  @override
  bool get isAbstract => true;
}

/// A union of object types.
class UnionType extends NamedType {
  UnionType(super.name, this.types, {super.description, this.resolveType});

  final List<ObjectType<Object?, Object?>> types;

  /// Picks the object type of a value. See [InterfaceType.resolveType].
  final TypeResolver? resolveType;

  @override
  bool get isComposite => true;

  @override
  bool get isAbstract => true;
}

/// An input object type. Resolvers get its values as [InputValues].
/// [fields] is a function, so that input types can point at each other.
class InputObjectType extends NamedType {
  InputObjectType(super.name, {super.description, required this._fields});

  final List<InputField> Function() _fields;

  late final List<InputField> fields = _fields();

  late final Map<String, InputField> _byName = <String, InputField>{
    for (InputField f in fields) f.name: f,
  };

  /// The field with this name, or null.
  InputField? field(String name) => _byName[name];

  @override
  bool get isInputType => true;

  @override
  bool get isOutputType => false;
}

/// A directive the schema knows. Only the built-in directives exist for
/// now: `@skip`, `@include`, `@deprecated` and `@specifiedBy`.
final class Directive {
  Directive(
    this.name, {
    this.description,
    required this.locations,
    this.args = const <Argument>[],
    this.isRepeatable = false,
  });

  final String name;
  final String? description;
  final List<DirectiveLocation> locations;
  final List<Argument> args;
  final bool isRepeatable;

  Argument? arg(String name) {
    for (Argument a in args) {
      if (a.name == name) return a;
    }
    return null;
  }
}

/// Coerced input values: the arguments of a field, the fields of an input
/// object, or the variables of a request.
///
/// A name that the query did not give is missing ([has] is false). A name
/// given as null is there with the value null.
final class InputValues {
  @internal
  const InputValues(this._values);

  final Map<String, Object?> _values;

  /// True when the value was given, even when it was null.
  bool has(String name) => _values.containsKey(name);

  /// All given names.
  Iterable<String> get names => _values.keys;

  /// The value of [name] as a [T]: `String`, `int`, `double`, `bool`, the
  /// Dart value of an enum or custom scalar, or [InputValues] for an input
  /// object. Null when missing or null.
  T? get<T>(String name) => _values[name] as T?;

  /// A list value, with items of type [T]. Use a nullable [T] when the
  /// items can be null.
  List<T>? list<T>(String name) => (_values[name] as List<Object?>?)?.cast<T>();

  /// An input object value.
  InputValues? input(String name) => _values[name] as InputValues?;

  /// The values as JSON, for logs and tests.
  Map<String, Object?> toJson() => <String, Object?>{
    for (MapEntry<String, Object?> e in _values.entries)
      e.key: _toJson(e.value),
  };

  static Object? _toJson(Object? value) => switch (value) {
    InputValues() => value.toJson(),
    List<Object?>() => <Object?>[for (Object? v in value) _toJson(v)],
    _ => value,
  };

  @override
  String toString() => 'InputValues(${toJson()})';
}
