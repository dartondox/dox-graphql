import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dox_builder/dox_builder.dart';
import 'package:source_gen/source_gen.dart';

import 'schema_model.dart';

/// The import prefixes of the generated file: `i1`, `i2`, ...
class Imports {
  /// import uri -> prefix
  final Map<String, String> prefixes = <String, String>{};

  /// The prefix of [library], like `i1`.
  String prefix(LibraryElement library) {
    return prefixes.putIfAbsent(
      library.uri.toString(),
      () => 'i${prefixes.length + 1}',
    );
  }

  /// [type] as code in the generated file, like `i1.Post?`.
  String code(DartType type) {
    String question = type.nullabilitySuffix == NullabilitySuffix.question
        ? '?'
        : '';
    if (type is! InterfaceType) return type.getDisplayString();
    InterfaceElement element = type.element;
    String start = element.library.isDartCore
        ? ''
        : '${prefix(element.library)}.';
    String args = type.typeArguments.isEmpty
        ? ''
        : '<${type.typeArguments.map(code).join(', ')}>';
    return '$start${element.displayName}$args$question';
  }

  /// [type] as code, without `?`.
  String nonNullCode(DartType type) {
    String text = code(type);
    return text.endsWith('?') ? text.substring(0, text.length - 1) : text;
  }
}

/// Reads the annotations of `dox_graphql` and the classes they are on,
/// and makes the specs the writer needs. A wrong type stops the build
/// with an error that names the class and the member.
class SchemaReader {
  SchemaReader(this.imports);

  final Imports imports;

  static const DtoReader _dtos = DtoReader();

  final Map<ClassElement, ObjectSpec> objects = <ClassElement, ObjectSpec>{};
  final Map<EnumElement, EnumSpec> enums = <EnumElement, EnumSpec>{};
  final Map<ClassElement, InputSpec> inputs = <ClassElement, InputSpec>{};
  final List<FieldSpec> query = <FieldSpec>[];
  final List<FieldSpec> mutation = <FieldSpec>[];

  /// GraphQL type name -> `Class` that made it, to find two types with one
  /// name.
  final Map<String, String> _typeNames = <String, String>{};

  static final RegExp _validName = RegExp(r'^[_A-Za-z][_0-9A-Za-z]*$');

  // ---------------------------------------------------------------------
  // Annotations
  // ---------------------------------------------------------------------

  /// The first annotation of class [name] of `package:[package]` on
  /// [element], or null.
  static DartObject? annotation(
    Element element,
    String name, {
    String package = 'dox_graphql',
  }) {
    for (ElementAnnotation a in element.metadata.annotations) {
      DartObject? value = a.computeConstantValue();
      DartType? type = value?.type;
      if (value != null &&
          type is InterfaceType &&
          type.element.name == name &&
          type.element.library.uri.toString().startsWith('package:$package/')) {
        return value;
      }
    }
    return null;
  }

  static String? _string(DartObject? annotation, String field) {
    return annotation?.getField(field)?.toStringValue();
  }

  /// The `///` comment of [element] as plain text, or null.
  static String? docOf(Element element) {
    String? doc = element.documentationComment;
    if (doc == null) return null;
    List<String> lines = <String>[
      for (String line in doc.split('\n'))
        line.trim().replaceFirst(RegExp(r'^///? ?'), ''),
    ];
    String text = lines.join('\n').trim();
    return text.isEmpty ? null : text;
  }

  // ---------------------------------------------------------------------
  // Types
  // ---------------------------------------------------------------------

  /// Step 1: register a `@GraphQLType` class, so fields can point at it.
  void addType(ClassElement element) {
    DartObject type = annotation(element, 'GraphQLType')!;
    String where = element.displayName;
    String name = _string(type, 'name') ?? element.displayName;
    _checkName(name, where, element);
    _claimTypeName(name, where, element);
    if (element.typeParameters.isNotEmpty) {
      _fail(where, 'a @GraphQLType class can not be generic.', element);
    }
    if (annotation(element, 'DoxModel', package: 'dox_annotation') != null) {
      _fail(
        where,
        '@GraphQLType() on a @DoxModel is not supported yet. Write a '
        'plain class, or a resolver.',
        element,
      );
    }
    if (type.getField('dto')?.toTypeValue() != null) {
      _fail(
        where,
        '`dto:` works only on a model of dox_orm. A plain class has no '
        'table to write to: write a @Mutation() in a resolver.',
        element,
      );
    }
    imports.prefix(element.library);
    objects[element] = ObjectSpec(
      element,
      name,
      element.library.uri.toString(),
      description: _string(type, 'description') ?? docOf(element),
    );
  }

  /// Step 2: the fields of each registered class.
  void readTypes() {
    for (ObjectSpec spec in objects.values) {
      _readPlainFields(spec);
    }
  }

  /// The public fields, and the getters with `@GraphQLField()`.
  void _readPlainFields(ObjectSpec spec) {
    ClassElement element = spec.element;
    // ponytail: fields of a superclass are not read. Read
    // element.allSupertypes when a type needs them.
    for (FieldElement field in element.fields) {
      if (field.isStatic || field.isPrivate || !field.isOriginDeclaration) {
        continue;
      }
      if (annotation(field, 'GraphQLIgnore') != null) continue;
      _addMember(spec, field, field.displayName, field.type, field);
    }
    for (GetterElement getter in element.getters) {
      if (!getter.isOriginDeclaration) continue;
      DartObject? field = annotation(getter, 'GraphQLField');
      if (field == null) continue;
      String where = '${element.displayName}.${getter.displayName}';
      if (getter.isStatic || getter.isPrivate) {
        _fail(where, '@GraphQLField() needs a public instance getter.', getter);
      }
      _addMember(spec, getter, getter.displayName, getter.returnType, getter);
    }
    for (MethodElement method in element.methods) {
      if (annotation(method, 'GraphQLField') == null) continue;
      _fail(
        '${element.displayName}.${method.displayName}',
        '@GraphQLField() works on a getter or a field. For a field with '
            'arguments, write a @ResolveField() method in a resolver.',
        method,
      );
    }
  }

  void _addMember(
    ObjectSpec spec,
    Element member,
    String dartName,
    DartType type,
    Element annotated,
  ) {
    String where = '${spec.element.displayName}.$dartName';
    DartObject? field = annotation(annotated, 'GraphQLField');
    String name = _string(field, 'name') ?? dartName;
    _checkName(name, where, member);
    String gql = _outputType(_unwrapFuture(type), where, member);
    _addField(
      spec.fields,
      FieldSpec(
        name: name,
        type: gql,
        resolve: 's.$dartName',
        where: where,
        description: _string(field, 'description') ?? docOf(member),
        deprecationReason: _string(field, 'deprecationReason'),
      ),
      spec.name,
      member,
    );
  }

  // ---------------------------------------------------------------------
  // Resolvers
  // ---------------------------------------------------------------------

  /// True when [element] has a `@Query`, `@Mutation` or `@ResolveField`
  /// method.
  static bool isResolver(ClassElement element) {
    for (MethodElement method in element.methods) {
      if (_rootKind(method) != null) return true;
    }
    return false;
  }

  static String? _rootKind(MethodElement method) {
    for (String kind in const <String>['Query', 'Mutation', 'ResolveField']) {
      if (annotation(method, kind) != null) return kind;
    }
    return null;
  }

  /// Reads the `@Query`, `@Mutation` and `@ResolveField` methods of
  /// [element]. The class is made for each call, with its constructor
  /// parameters from the Dox container.
  void readResolver(ClassElement element) {
    String className = element.displayName;
    if (element.isAbstract || element.typeParameters.isNotEmpty) {
      _fail(
        className,
        'a resolver class can not be abstract or generic: Dox makes it '
        'for each call.',
        element,
      );
    }
    if (element.isPrivate) {
      _fail(
        className,
        'a resolver class can not be private: schema.g.dart is another '
        'library. Remove the `_`.',
        element,
      );
    }
    ConstructorElement? constructor = element.unnamedConstructor;
    if (constructor == null) {
      _fail(
        className,
        'a resolver class needs an unnamed constructor. Dox calls it with '
        'services from the container.',
        element,
      );
    }
    List<String> values = <String>[];
    for (FormalParameterElement param in constructor.formalParameters) {
      if (param.isOptional) continue;
      String value = 'info.context.make<${imports.nonNullCode(param.type)}>()';
      values.add(param.isNamed ? '${param.displayName}: $value' : value);
    }
    String instance =
        '${imports.prefix(element.library)}.$className(${values.join(', ')})';

    for (MethodElement method in element.methods) {
      String? kind = _rootKind(method);
      if (kind == null) continue;
      _readMethod(element, method, kind, instance);
    }
  }

  void _readMethod(
    ClassElement owner,
    MethodElement method,
    String kind,
    String instance,
  ) {
    String where = '${owner.displayName}.${method.displayName}';
    DartObject ann = annotation(method, kind)!;
    if (method.isStatic || method.isPrivate) {
      _fail(where, '@$kind() needs a public instance method.', method);
    }
    if (method.typeParameters.isNotEmpty) {
      _fail(where, '@$kind() can not be on a generic method.', method);
    }
    String name = _string(ann, 'name') ?? method.displayName;
    _checkName(name, where, method);
    List<FormalParameterElement> params = method.formalParameters;

    ObjectSpec? parent;
    if (kind == 'ResolveField') {
      DartType? first = params.isEmpty ? null : params.first.type;
      Element? firstElement = first is InterfaceType ? first.element : null;
      parent = firstElement is ClassElement ? objects[firstElement] : null;
      if (parent == null ||
          !params.first.isPositional ||
          first!.nullabilitySuffix == NullabilitySuffix.question) {
        _fail(
          where,
          'the first parameter of a @ResolveField() method must be the '
          'parent: a non-null @GraphQLType class, like `Post post`.',
          method,
        );
      }
      params = params.skip(1).toList();
    }

    List<ArgSpec> args = <ArgSpec>[];
    List<String> values = <String>[if (parent != null) 's'];
    bool isAsync = false;
    for (FormalParameterElement param in params) {
      String argWhere = '$where(${param.displayName})';
      String value;
      if (_isContext(param.type)) {
        value = 'info.context';
      } else {
        String argName = param.displayName;
        _checkName(argName, argWhere, param);
        String type = _inputType(param.type, argWhere, param);
        String? defaultValue;
        if (param.hasDefaultValue) {
          DartObject? constant = param.computeConstantValue();
          String? literal = constant == null ? null : _literal(constant);
          if (literal == null) {
            _fail(
              argWhere,
              'the default value can not be a GraphQL default. Use a '
              'number, text, bool, enum or list default.',
              param,
            );
          }
          if (literal != 'null') defaultValue = literal;
        }
        args.add(ArgSpec(argName, type, defaultValue: defaultValue));
        (value, isAsync) = _readArg(param.type, argName, isAsync);
      }
      values.add(param.isNamed ? '${param.displayName}: $value' : value);
    }

    DartType returnType = _unwrapFuture(method.returnType);
    String type = _outputType(returnType, where, method);
    FieldSpec field = FieldSpec(
      name: name,
      type: type,
      resolve: '$instance.${method.displayName}(${values.join(', ')})',
      where: where,
      description: _string(ann, 'description') ?? docOf(method),
      deprecationReason: _string(ann, 'deprecationReason'),
      args: args,
      isAsync: isAsync,
    );
    switch (kind) {
      case 'Query':
        _addField(query, field, 'Query', method);
      case 'Mutation':
        _addField(mutation, field, 'Mutation', method);
      default:
        _addField(parent!.fields, field, parent.name, method);
    }
  }

  /// The code that reads argument [name] as a [type], and if that code
  /// awaits.
  (String, bool) _readArg(DartType type, String name, bool isAsync) {
    bool nullable = type.nullabilitySuffix == NullabilitySuffix.question;
    String bang = nullable ? '' : '!';
    String quoted = "'$name'";
    if (type is InterfaceType) {
      InterfaceElement element = type.element;
      if (element is ClassElement && _dtos.isDto(element)) {
        InputSpec input = inputs[element]!;
        String call =
            'await ${input.validate}(info.args.input($quoted)!, info.context)';
        if (nullable) {
          call = 'info.args.input($quoted) == null ? null : $call';
        }
        return (call, true);
      }
      if (type.isDartCoreList) {
        String item = imports.code(type.typeArguments.first);
        return ('info.args.list<$item>($quoted)$bang', isAsync);
      }
    }
    return (
      'info.args.get<${imports.nonNullCode(type)}>($quoted)$bang',
      isAsync,
    );
  }

  /// True for the `DoxGraphQLContext` of dox_graphql: it is given, not an
  /// argument.
  static bool _isContext(DartType type) {
    return type is InterfaceType &&
        type.element.name == 'DoxGraphQLContext' &&
        type.element.library.uri.toString().startsWith('package:dox_graphql/');
  }

  // ---------------------------------------------------------------------
  // Type mapping
  // ---------------------------------------------------------------------

  static DartType _unwrapFuture(DartType type) {
    if (type is InterfaceType &&
        (type.isDartAsyncFuture || type.isDartAsyncFutureOr)) {
      return type.typeArguments.first;
    }
    return type;
  }

  /// The GraphQL type of a field, as code.
  String _outputType(DartType type, String where, Element element) {
    String? gql = _type(type, input: false);
    if (gql != null) return gql;
    _fail(
      where,
      'the type ${type.getDisplayString()} can not be a GraphQL field. Use '
      'String, int, double, bool, DateTime, an enum, a @GraphQLType class '
      'or a List of them. Or add @GraphQLIgnore().',
      element,
    );
  }

  /// The GraphQL type of an argument, as code.
  String _inputType(DartType type, String where, Element element) {
    String? gql = _type(type, input: true);
    if (gql != null) return gql;
    _fail(
      where,
      'the type ${type.getDisplayString()} can not be a GraphQL argument. '
      'Use String, int, double, bool, DateTime, an enum, a @Dto class or '
      'a List of them.',
      element,
    );
  }

  String? _type(DartType type, {required bool input}) {
    if (type is! InterfaceType) return null;
    String? base;
    if (type.isDartCoreList) {
      DartType item = type.typeArguments.first;
      // a list of DTOs needs one check per item: wrap them in one DTO
      if (input && item is InterfaceType && _dtos.isDto(item.element)) {
        return null;
      }
      String? itemType = _type(item, input: input);
      if (itemType != null) base = '$itemType.list';
    } else {
      base = _named(type, input: input);
    }
    if (base == null) return null;
    return type.nullabilitySuffix == NullabilitySuffix.question
        ? base
        : '$base.nonNull';
  }

  String? _named(InterfaceType type, {required bool input}) {
    if (type.isDartCoreInt) return 'graphqlInt';
    if (type.isDartCoreDouble || type.isDartCoreNum) return 'graphqlFloat';
    if (type.isDartCoreString) return 'graphqlString';
    if (type.isDartCoreBool) return 'graphqlBoolean';
    InterfaceElement element = type.element;
    if (element.library.isDartCore && element.name == 'DateTime') {
      return 'graphqlDateTime';
    }
    if (element is EnumElement) return _enum(element).variable;
    if (element is! ClassElement) return null;
    if (input) {
      return _dtos.isDto(element) ? inputOf(element).variable : null;
    }
    return objects[element]?.variable;
  }

  EnumSpec _enum(EnumElement element) {
    EnumSpec? spec = enums[element];
    if (spec != null) return spec;
    _claimTypeName(element.displayName, element.displayName, element);
    imports.prefix(element.library);
    return enums[element] = EnumSpec(element, element.library.uri.toString());
  }

  /// The input type of the `@Dto` class [element], made on first use.
  InputSpec inputOf(ClassElement element) {
    InputSpec? spec = inputs[element];
    if (spec != null) return spec;
    String base = element.displayName;
    if (base.endsWith('Dto') && base.length > 3) {
      base = base.substring(0, base.length - 3);
    }
    String name = '${base}Input';
    _claimTypeName(name, element.displayName, element);
    imports.prefix(element.library);
    spec = inputs[element] = InputSpec(
      element,
      name,
      element.library.uri.toString(),
      description: docOf(element),
    );
    DtoClass dto = _dtos.read(element);
    for (DtoField field in dto.fields) {
      String where = '${element.displayName}.${field.name}';
      String? type = _dtoType(field.type, where, field.element);
      spec.fields.add(
        InputFieldSpec(
          field.name,
          field.key,
          type!,
          _convert(field.type, "v.get<Object?>('${field.name}')", 1),
        ),
      );
    }
    return spec;
  }

  /// The GraphQL type of a DTO field. Every input field is nullable, so
  /// a missing value gets the message of the DTO rules, not a GraphQL
  /// error.
  String? _dtoType(DtoType type, String where, Element element) {
    switch (type.kind) {
      case DtoKind.string:
        return 'graphqlString';
      case DtoKind.integer:
        return 'graphqlInt';
      case DtoKind.decimal || DtoKind.number:
        return 'graphqlFloat';
      case DtoKind.boolean:
        return 'graphqlBoolean';
      case DtoKind.date:
        return 'graphqlDateTime';
      case DtoKind.enumName:
        return _enum((type.type as InterfaceType).element as EnumElement)
            .variable;
      case DtoKind.dto:
        return inputOf((type.type as InterfaceType).element as ClassElement)
            .variable;
      case DtoKind.list:
        String? item = _dtoType(type.item!, where, element);
        return '$item.list';
      case DtoKind.file || DtoKind.map || DtoKind.anyMap || DtoKind.any:
        _fail(
          where,
          'the type ${type.type.getDisplayString()} can not be a GraphQL '
          'input field. Use String, int, double, bool, DateTime, an enum, '
          'a @Dto class or a List of them.',
          element,
        );
    }
  }

  /// Code that turns the GraphQL value [value] into the JSON value a DTO
  /// reads. [depth] keeps the names of nested patterns apart.
  String _convert(DtoType type, String value, int depth) {
    switch (type.kind) {
      case DtoKind.date:
        return 'switch ($value) { DateTime d$depth => '
            'd$depth.toIso8601String(), _ => null }';
      case DtoKind.enumName:
        String code = imports.nonNullCode(type.type);
        return 'switch ($value) { $code e$depth => e$depth.name, _ => null }';
      case DtoKind.dto:
        InputSpec nested = inputOf(
          (type.type as InterfaceType).element as ClassElement,
        );
        return 'switch ($value) { InputValues n$depth => '
            '${nested.toMap}(n$depth), _ => null }';
      case DtoKind.list:
        String item = _convert(type.item!, 'y$depth', depth + 1);
        if (item == 'y$depth') return value;
        return 'switch ($value) { List<Object?> l$depth => <Object?>[for '
            '(Object? y$depth in l$depth) $item], _ => null }';
      default:
        return value;
    }
  }

  /// A Dart constant as GraphQL literal text, or null when it has no
  /// GraphQL form. `null` gives the text `null`.
  String? _literal(DartObject value) {
    if (value.isNull) return 'null';
    int? i = value.toIntValue();
    if (i != null) return '$i';
    double? d = value.toDoubleValue();
    if (d != null) return d.isFinite ? '$d' : null;
    bool? b = value.toBoolValue();
    if (b != null) return '$b';
    String? s = value.toStringValue();
    if (s != null) return jsonEncode(s);
    List<DartObject>? list = value.toListValue();
    if (list != null) {
      List<String> items = <String>[];
      for (DartObject item in list) {
        String? text = _literal(item);
        if (text == null) return null;
        items.add(text);
      }
      return '[${items.join(', ')}]';
    }
    DartType? type = value.type;
    if (type is InterfaceType && type.element is EnumElement) {
      return value.variable?.displayName;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Checks
  // ---------------------------------------------------------------------

  void _addField(
    List<FieldSpec> fields,
    FieldSpec field,
    String typeName,
    Element element,
  ) {
    for (FieldSpec other in fields) {
      if (other.name == field.name) {
        _fail(
          field.where,
          'the field "${field.name}" of $typeName is made twice: here and '
          'in ${other.where}. Rename one with `name:`.',
          element,
        );
      }
    }
    fields.add(field);
  }

  void _claimTypeName(String name, String where, Element element) {
    String? other = _typeNames[name];
    if (other != null) {
      _fail(
        where,
        'the GraphQL type name "$name" is used twice: here and by $other. '
        'Rename one, like @GraphQLType(name: \'Other\').',
        element,
      );
    }
    _typeNames[name] = where;
  }

  void _checkName(String name, String where, Element element) {
    if (_validName.hasMatch(name) && !name.startsWith('__')) return;
    _fail(
      where,
      '"$name" is not a valid GraphQL name. Use letters, digits and `_`, '
      'and do not start with `__`.',
      element,
    );
  }

  static Never _fail(String where, String message, Element element) {
    throw InvalidGenerationSourceError('$where: $message', element: element);
  }
}
