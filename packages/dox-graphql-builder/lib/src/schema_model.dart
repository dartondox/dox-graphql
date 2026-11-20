import 'package:analyzer/dart/element/element.dart';

/// One argument of a field, as code.
class ArgSpec {
  ArgSpec(this.name, this.type, {this.defaultValue});

  /// The GraphQL name.
  final String name;

  /// The GraphQL type as code, like `graphqlInt.nonNull`.
  final String type;

  /// The default as GraphQL literal text, like `10`.
  final String? defaultValue;
}

/// One field of an object type or a root type, as code.
class FieldSpec {
  FieldSpec({
    required this.name,
    required this.type,
    required this.resolve,
    required this.where,
    this.description,
    this.deprecationReason,
    this.args = const <ArgSpec>[],
    this.isAsync = false,
    this.auto = false,
    this.auth,
    this.column,
  });

  final String name;

  /// The GraphQL type as code.
  final String type;

  /// The body of the resolver: an expression with `s` (the parent) and
  /// `info`.
  final String resolve;

  /// `Class.member`, for build errors.
  final String where;
  final String? description;
  final String? deprecationReason;
  final List<ArgSpec> args;

  /// True when [resolve] uses `await`.
  final bool isAsync;

  /// A field made for a model (an `AutoField`).
  final bool auto;

  /// The `auth:` of the field: true needs a login, false is public, null
  /// uses the default of the server.
  final bool? auth;

  /// Models only: the column of the field (the snake_case name for a
  /// relation). The field is left out when the model has it in `hidden`,
  /// or has `visibleFields` without it.
  final String? column;
}

/// One `@GraphQLType` class.
class ObjectSpec {
  ObjectSpec(this.element, this.name, this.library, {this.description});

  final ClassElement element;

  /// The GraphQL name.
  final String name;

  /// The import of the class.
  final String library;
  final String? description;

  /// True for a model of dox_orm.
  bool orm = false;

  /// Models: the list and find queries.
  bool queries = true;

  /// Models: the `@Dto` class of `dto:`, for the create, update and
  /// delete mutations.
  ClassElement? dto;

  /// The `auth:` of the type.
  bool? auth;

  /// Models: true with a `policy:`, for the update and delete mutations.
  bool policy = false;

  /// Models: the column of `owner:`, like `userId`. The create mutation
  /// sets it to the id of the logged-in user.
  String? owner;

  /// Models: the Dart type of the [owner] column, `int` or `String`.
  String ownerType = 'int';

  /// Models: the primary key column, like `id`.
  String primaryKey = 'id';

  /// Models: the Dart type of the primary key, `int` or `String`.
  String keyType = 'int';
  final List<FieldSpec> fields = <FieldSpec>[];

  /// The name of the variable in the generated code.
  String get variable => '_t$name';
}

/// One Dart enum used by a field or an argument.
class EnumSpec {
  EnumSpec(this.element, this.library);

  final EnumElement element;
  final String library;

  String get name => element.displayName;

  String get variable => '_e$name';
}

/// One field of an input type: a field of a `@Dto` class.
class InputFieldSpec {
  InputFieldSpec(this.name, this.key, this.type, this.convert);

  /// The GraphQL name: the Dart name.
  final String name;

  /// The input key of the DTO, like `user_id`.
  final String key;

  /// The GraphQL type as code.
  final String type;

  /// Code that turns the GraphQL value `x` into the JSON value the DTO
  /// reads.
  final String convert;
}

/// One input type made from a `@Dto` class.
class InputSpec {
  InputSpec(this.element, this.name, this.library, {this.description});

  final ClassElement element;
  final String name;
  final String library;
  final String? description;
  final List<InputFieldSpec> fields = <InputFieldSpec>[];

  String get variable => '_i$name';

  /// The function that turns the input into a map with the DTO keys.
  String get toMap => '_m$name';

  /// True when a resolver calls [validate], so the function is written.
  bool validated = false;

  /// The function that checks the input with the DTO rules.
  String get validate => '_v$name';
}
