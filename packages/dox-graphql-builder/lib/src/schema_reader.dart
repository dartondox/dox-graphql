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

  /// By GraphQL name: one `@Dto` can give more than one input type, like
  /// `CreatePostInput` and `UpdatePostInput`.
  final Map<String, InputSpec> inputs = <String, InputSpec>{};

  /// Functions the root fields of models call, as code.
  final List<String> functions = <String>[];

  /// True when a model is in the schema: the code imports
  /// dox_graphql_orm.
  bool get hasModels => objects.values.any((ObjectSpec o) => o.orm);

  /// True when a model has `policy:`: the code then uses `Gate` of
  /// dox_auth.
  bool hasPolicies = false;
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
    if (element.isPrivate) {
      _fail(
        where,
        'a @GraphQLType class can not be private: schema.g.dart is another '
        'library. Remove the `_`.',
        element,
      );
    }
    String name = _string(type, 'name') ?? element.displayName;
    _checkName(name, where, element);
    _claimTypeName(name, where, element);
    if (element.typeParameters.isNotEmpty) {
      _fail(where, 'a @GraphQLType class can not be generic.', element);
    }
    DartObject? model = annotation(
      element,
      'DoxModel',
      package: 'dox_annotation',
    );
    DartType? dto = type.getField('dto')?.toTypeValue();
    DartType? policy = type.getField('policy')?.toTypeValue();
    if (model == null && policy != null) {
      _fail(
        where,
        '`policy:` works only on a model of dox_orm with `dto:`.',
        element,
      );
    }
    if (model == null && dto != null) {
      _fail(
        where,
        '`dto:` works only on a model of dox_orm. A plain class has no '
        'table to write to: write a @GraphQLMutation() in a resolver.',
        element,
      );
    }
    imports.prefix(element.library);
    ObjectSpec spec = objects[element] = ObjectSpec(
      element,
      name,
      element.library.uri.toString(),
      description: _string(type, 'description') ?? docOf(element),
    );
    spec.auth = type.getField('auth')?.toBoolValue();
    if (model == null) return;
    spec.orm = true;
    spec.queries = type.getField('queries')?.toBoolValue() ?? true;
    if (dto != null) {
      Element? dtoElement = dto is InterfaceType ? dto.element : null;
      if (dtoElement is! ClassElement || !_dtos.isDto(dtoElement)) {
        _fail(
          where,
          '`dto:` must be a class with @Dto(), not '
          '${dto.getDisplayString()}.',
          element,
        );
      }
      spec.dto = dtoElement;
    }
    if (policy != null) {
      if (dto == null) {
        _fail(
          where,
          '`policy:` needs `dto:`: the policy guards the update and delete '
          'mutations, and they come from the DTO.',
          element,
        );
      }
      if (!_isPolicyOf(policy, element)) {
        _fail(
          where,
          '`policy:` must be a Policy of dox_auth for ${element.displayName}, '
          'like `class ${element.displayName}Policy extends '
          'Policy<User, ${element.displayName}>`, not '
          '${policy.getDisplayString()}.',
          element,
        );
      }
      spec.policy = true;
      hasPolicies = true;
    }
    spec.primaryKey = model.getField('primaryKey')?.toStringValue() ?? 'id';
    DartType? key = model.getField('primaryKeyType')?.toTypeValue();
    spec.keyType = key is InterfaceType ? key.element.displayName : 'int';
  }

  /// Step 2: the fields of each registered class, and the list, find and
  /// write fields of the models.
  void readTypes() {
    for (ObjectSpec spec in objects.values) {
      if (spec.orm) {
        _readModelFields(spec);
      } else {
        _readPlainFields(spec);
      }
      _readGetters(spec);
    }
    for (ObjectSpec spec in objects.values) {
      if (spec.orm) _addModelRoots(spec);
    }
  }

  /// The public fields of a plain class.
  void _readPlainFields(ObjectSpec spec) {
    ClassElement element = spec.element;
    Set<String> seen = <String>{};
    // the class, then its superclasses up to Object. The getters of an
    // InterfaceType have the type arguments of the superclass filled in.
    for (
      InterfaceType? type = element.thisType;
      type != null && !type.isDartCoreObject;
      type = type.superclass
    ) {
      for (GetterElement getter in type.getters) {
        if (getter.isStatic || !seen.add(getter.displayName)) continue;
        if (getter.isOriginVariable) {
          Element field = getter.variable;
          if (getter.isPrivate || annotation(field, 'GraphQLIgnore') != null) {
            continue;
          }
          _addMember(spec, field, getter.displayName, getter.returnType, field);
          continue;
        }
        if (!getter.isOriginDeclaration) continue;
        if (annotation(getter, 'GraphQLField') == null) continue;
        if (getter.isPrivate) {
          _fail(
            '${element.displayName}.${getter.displayName}',
            '@GraphQLField() needs a public instance getter.',
            getter,
          );
        }
        _addMember(spec, getter, getter.displayName, getter.returnType, getter);
      }
    }
  }

  /// The relation annotations of dox_orm.
  static const List<String> _relations = <String>[
    'HasOne',
    'HasMany',
    'BelongsTo',
    'ManyToMany',
    'HasManyThrough',
    'HasOneThrough',
    'MorphMany',
    'MorphOne',
    'MorphTo',
  ];

  static bool _isRelation(FieldElement field) {
    for (String name in _relations) {
      if (annotation(field, name, package: 'dox_orm') != null) return true;
    }
    return false;
  }

  /// The key, the `@Column` fields and the relations of a model. A field
  /// is left out at run time when its column (or for a relation, its
  /// name in snake_case) is in `hidden`, or `visibleFields` is not empty
  /// and does not have it.
  void _readModelFields(ObjectSpec spec) {
    ClassElement element = spec.element;
    String key = camelCase(spec.primaryKey);
    _addField(
      spec.fields,
      FieldSpec(
        name: key,
        type: 'graphqlId.nonNull',
        resolve: 's.$key',
        where: '${element.displayName}.$key',
        column: spec.primaryKey,
      ),
      spec.name,
      element,
    );
    String model = '${imports.prefix(element.library)}.${element.displayName}';
    for (FieldElement field in element.fields) {
      if (field.isStatic || !field.isOriginDeclaration) continue;
      if (annotation(field, 'GraphQLIgnore') != null) continue;
      DartObject? column = annotation(field, 'Column', package: 'dox_orm');
      bool relation = _isRelation(field);
      if (column == null && !relation) continue;
      String dartName = field.displayName;
      if (field.isPrivate) continue;
      if (column != null) {
        String columnName =
            column.getField('name')?.toStringValue() ?? snakeCase(dartName);
        _addMember(
          spec,
          field,
          dartName,
          field.type,
          field,
          column: columnName,
        );
        continue;
      }
      _addMember(
        spec,
        field,
        dartName,
        field.type,
        field,
        resolve:
            'GraphQLOrm.relation<$model, ${imports.code(field.type)}>(s, '
            "'$dartName', info.context, ($model p) => p.$dartName)",
        // the name toJson() gives a relation, so `hidden` can name it
        column: snakeCase(dartName),
      );
    }
  }

  /// The list and find queries, and with `dto:` the create, update and
  /// delete mutations of a model. They are `AutoField`s, so
  /// `GraphQLConfig(autoResolvers: false)` can leave them out.
  void _addModelRoots(ObjectSpec spec) {
    ClassElement element = spec.element;
    String model = '${imports.prefix(element.library)}.${element.displayName}';
    String name = spec.name;
    String id = spec.keyType == 'int'
        ? "int.tryParse(info.args.get<String>('id')!)"
        : "info.args.get<String>('id')!";
    ArgSpec idArg = ArgSpec('id', 'graphqlId.nonNull');
    String auto = '$name (made for the model)';
    if (spec.queries) {
      String hint = '$auto. Turn it off with @GraphQLType(queries: false)';
      _addField(
        query,
        FieldSpec(
          name: lcFirst(plural(name)),
          type: '${spec.variable}.nonNull.list.nonNull',
          args: <ArgSpec>[
            ArgSpec('limit', 'graphqlInt', defaultValue: '20'),
            ArgSpec('offset', 'graphqlInt', defaultValue: '0'),
          ],
          resolve: 'GraphQLOrm.list<$model>($model(), info)',
          where: hint,
          auto: true,
          auth: spec.auth,
        ),
        'Query',
        element,
      );
      _addField(
        query,
        FieldSpec(
          name: lcFirst(name),
          type: spec.variable,
          args: <ArgSpec>[idArg],
          resolve: 'GraphQLOrm.find<$model>($model(), $id)',
          where: hint,
          auto: true,
          auth: spec.auth,
        ),
        'Query',
        element,
      );
    }
    ClassElement? dtoElement = spec.dto;
    if (dtoElement == null) return;
    InputSpec create = inputOf(dtoElement, name: 'Create${name}Input')
      ..validated = true;
    InputSpec? update = spec.policy
        ? inputOf(dtoElement, name: 'Update${name}Input')
        : null;
    String dtoPrefix = imports.prefix(dtoElement.library);
    String dto = '$dtoPrefix.${dtoElement.displayName}';
    String schema = '$dtoPrefix.\$${dtoElement.displayName}Dto';

    List<String> sets = <String>[];
    List<String> updates = <String>[];
    List<String> current = <String>[];
    List<String> names = <String>[];
    List<String> placeholders = <String>[];
    for (DtoField field in _dtos.read(dtoElement).fields) {
      String where = '${dtoElement.displayName}.${field.name}';
      if (field.maybe) {
        _fail(
          where,
          'a Maybe field can not be in the `dto:` of a model. The update '
          'mutation already sets only the fields the client sends.',
          field.element,
        );
      }
      FieldElement? column = _columnNamed(element, field.name);
      if (column == null) {
        _fail(
          where,
          '${element.displayName} has no @Column() field "${field.name}". '
          'The `dto:` of a model can set only its columns.',
          field.element,
        );
      }
      if (!element.library.typeSystem.isAssignableTo(
        field.element.type,
        column.type,
      )) {
        _fail(
          where,
          'the type ${field.element.type.getDisplayString()} can not be set '
          'on ${element.displayName}.${field.name} '
          '(${column.type.getDisplayString()}).',
          field.element,
        );
      }
      String value = switch (field.type.kind) {
        DtoKind.date => 'model.${field.name}?.toIso8601String()',
        DtoKind.enumName => 'model.${field.name}?.name',
        DtoKind.string ||
        DtoKind.integer ||
        DtoKind.decimal ||
        DtoKind.number ||
        DtoKind.boolean => 'model.${field.name}',
        _ => _fail(
          where,
          'the `dto:` of a model can set only text, number, bool, '
          'DateTime and enum columns.',
          field.element,
        ),
      };
      sets.add('..${field.name} = dto.${field.name}');
      updates.add(
        "if (input.has('${field.name}')) "
        'model.${field.name} = dto.${field.name};',
      );
      current.add("'${field.key}': $value,");
      // a value of the right type, for a stored value that has a wrong
      // one (see GraphQLDto.validateSent). It is never saved.
      String placeholder = switch (field.type.kind) {
        // not empty: a DTO reads "" as missing
        DtoKind.string => "'-'",
        DtoKind.integer || DtoKind.number => '0',
        DtoKind.decimal => '0.0',
        DtoKind.boolean => 'false',
        DtoKind.date => "'1970-01-01T00:00:00.000Z'",
        // enum: the name of its first value
        _ => "'${_enumOf(field.type).constants.first.displayName}'",
      };
      placeholders.add("'${field.key}': $placeholder,");
      if (field.key != field.name) {
        names.add("'${field.key}': '${field.name}',");
      }
    }
    String key = camelCase(spec.primaryKey);
    functions.add('''
/// Makes a $name from the input of `create$name`.
Future<$model> _create$name(ResolveInfo<DoxGraphQLContext> info) async {
  $dto dto = await ${create.validate}(info.args.input('input')!, info.context);
  $model model = $model()${sets.join()};
  await model.save();
  return model;
}
''');
    String hint = '$auto from `dto:`';
    _addField(
      mutation,
      FieldSpec(
        name: 'create$name',
        type: '${spec.variable}.nonNull',
        args: <ArgSpec>[ArgSpec('input', '${create.variable}.nonNull')],
        resolve: '_create$name(info)',
        where: hint,
        auto: true,
        auth: spec.auth,
      ),
      'Mutation',
      element,
    );
    // ponytail: no policy, no update or delete: a write to a row needs a
    // rule about who owns it.
    if (update == null) return;
    functions
      ..add('''
/// Sets the fields the client sent on a $name. Null when there is no
/// $name with that id.
Future<$model?> _update$name(ResolveInfo<DoxGraphQLContext> info) async {
  $model? model = await GraphQLOrm.find<$model>($model(), $id);
  if (model == null) return null;
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = ${update.toMap}(input);
  // the other fields keep their stored values, and are not checked
  $dto dto = await GraphQLDto.validateSent<$dto>(
    $schema,
    <String, Object?>{${current.join()} ...given},
    info.context,
    sent: given.keys.toSet(),
    placeholders: const <String, Object?>{${placeholders.join()}},
    names: const <String, String>{${names.join()}},
    params: <String, String>{'id': '\${model.$key}'},
  );
  ${updates.join('\n  ')}
  await model.save();
  return model;
}
''')
      ..add('''
/// Deletes a $name. False when there is no $name with that id.
Future<bool> _delete$name(ResolveInfo<DoxGraphQLContext> info) async {
  $model? model = await GraphQLOrm.find<$model>($model(), $id);
  if (model == null) return false;
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}
''');
    _addField(
      mutation,
      FieldSpec(
        name: 'update$name',
        type: spec.variable,
        args: <ArgSpec>[idArg, ArgSpec('input', '${update.variable}.nonNull')],
        resolve: '_update$name(info)',
        where: hint,
        auto: true,
        auth: spec.auth,
      ),
      'Mutation',
      element,
    );
    _addField(
      mutation,
      FieldSpec(
        name: 'delete$name',
        type: 'graphqlBoolean.nonNull',
        args: <ArgSpec>[idArg],
        resolve: '_delete$name(info)',
        where: hint,
        auto: true,
        auth: spec.auth,
      ),
      'Mutation',
      element,
    );
  }

  /// True when [policy] is a `Policy<U, M>` of dox_auth with [model] as
  /// `M`.
  static bool _isPolicyOf(DartType policy, ClassElement model) {
    if (policy is! InterfaceType) return false;
    for (InterfaceType t in policy.allSupertypes) {
      if (t.element.name != 'Policy' ||
          !t.element.library.uri.toString().startsWith('package:dox_auth/') ||
          t.typeArguments.length != 2) {
        continue;
      }
      DartType m = t.typeArguments[1];
      return m is InterfaceType && m.element == model;
    }
    return false;
  }

  static EnumElement _enumOf(DtoType type) {
    return (type.type as InterfaceType).element as EnumElement;
  }

  static FieldElement? _columnNamed(ClassElement model, String name) {
    for (FieldElement field in model.fields) {
      if (field.displayName == name &&
          !field.isStatic &&
          annotation(field, 'Column', package: 'dox_orm') != null) {
        return field;
      }
    }
    return null;
  }

  /// The getters with `@GraphQLField()` of a model, and a check that no
  /// method has it. A plain class reads its getters with its fields.
  void _readGetters(ObjectSpec spec) {
    ClassElement element = spec.element;
    for (GetterElement getter
        in spec.orm ? element.getters : const <GetterElement>[]) {
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
    Element annotated, {
    String? resolve,
    String? column,
  }) {
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
        resolve: resolve ?? 's.$dartName',
        where: where,
        description: _string(field, 'description') ?? docOf(member),
        deprecationReason: _string(field, 'deprecationReason'),
        auth: field?.getField('auth')?.toBoolValue(),
        column: column,
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
    for (String kind in const <String>[
      'GraphQLQuery',
      'GraphQLMutation',
      'ResolveField',
    ]) {
      if (annotation(method, kind) != null) return kind;
    }
    return null;
  }

  /// Reads the `@GraphQLQuery`, `@GraphQLMutation` and `@ResolveField` methods of
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
      auth: ann.getField('auth')?.toBoolValue(),
      args: args,
      isAsync: isAsync,
    );
    switch (kind) {
      case 'GraphQLQuery':
        _addField(query, field, 'Query', method);
      case 'GraphQLMutation':
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
        InputSpec input = inputOf(element)..validated = true;
        String call =
            'await ${input.validate}(info.args.input($quoted)!, info.context)';
        if (nullable) {
          call = 'info.args.input($quoted) == null ? null : $call';
        }
        return (call, true);
      }
      if (type.isDartCoreList) {
        return (_cast(type, 'info.args.get<Object?>($quoted)', 1), isAsync);
      }
    }
    return (
      'info.args.get<${imports.nonNullCode(type)}>($quoted)$bang',
      isAsync,
    );
  }

  /// Code that turns the argument value [value] into a [type]. A list is
  /// copied item by item, so a nested list like `List<List<int>>` gets
  /// the right type at every level. [depth] keeps the names of nested
  /// patterns apart.
  String _cast(DartType type, String value, int depth) {
    if (type is InterfaceType && type.isDartCoreList) {
      DartType item = type.typeArguments.first;
      String inner = _cast(item, 'x$depth', depth + 1);
      String list =
          'switch ($value) { List<Object?> l$depth => '
          '<${imports.code(item)}>[for (Object? x$depth in l$depth) $inner], '
          '_ => null }';
      return type.nullabilitySuffix == NullabilitySuffix.question
          ? '($list)'
          : '($list)!';
    }
    return '($value as ${imports.code(type)})';
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
    if (element.isPrivate) {
      _fail(
        element.displayName,
        'a private enum can not be a GraphQL type: schema.g.dart is another '
        'library. Remove the `_`.',
        element,
      );
    }
    _claimTypeName(element.displayName, element.displayName, element);
    imports.prefix(element.library);
    return enums[element] = EnumSpec(element, element.library.uri.toString());
  }

  /// The input type of the `@Dto` class [element], made on first use.
  /// [name] is the type name. Default: the class name without `Dto`, and
  /// `Input`.
  InputSpec inputOf(ClassElement element, {String? name}) {
    if (name == null) {
      String base = element.displayName;
      if (base.endsWith('Dto') && base.length > 3) {
        base = base.substring(0, base.length - 3);
      }
      name = '${base}Input';
    }
    InputSpec? spec = inputs[name];
    if (spec != null && spec.element == element) return spec;
    _claimTypeName(name, element.displayName, element);
    imports.prefix(element.library);
    spec = inputs[name] = InputSpec(
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

/// `user_id` -> `userId`.
String camelCase(String text) {
  List<String> words = text.split('_');
  StringBuffer out = StringBuffer(words.first);
  for (String word in words.skip(1)) {
    if (word.isEmpty) continue;
    out.write(word[0].toUpperCase() + word.substring(1));
  }
  return out.toString();
}

/// `userId` -> `user_id`, the column name of a field.
String snakeCase(String text) {
  StringBuffer out = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    String char = text[i];
    if (i > 0 && char != char.toLowerCase()) out.write('_');
    out.write(char.toLowerCase());
  }
  return out.toString().replaceAll(RegExp('_+'), '_');
}

/// `Post` -> `post`.
String lcFirst(String text) => text[0].toLowerCase() + text.substring(1);

/// The English plural of a name: `Post` -> `Posts`, `Category` ->
/// `Categories`, `Box` -> `Boxes`.
String plural(String name) {
  // ponytail: simple rules, no list of odd words (Person, Child). A model
  // with an odd plural turns its queries off and writes a resolver.
  if (RegExp(r'[^aeiou]y$').hasMatch(name)) {
    return '${name.substring(0, name.length - 1)}ies';
  }
  if (RegExp(r'(s|x|z|ch|sh)$').hasMatch(name)) return '${name}es';
  return '${name}s';
}
