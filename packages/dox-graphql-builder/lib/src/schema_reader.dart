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

  /// True when a `can:` or `filter:` is used: the code then uses `Gate`
  /// of dox_auth.
  bool usesGate = false;

  /// Each ability of a `can:` or `filter:`, for the start check.
  final List<AbilityCheck> abilityChecks = <AbilityCheck>[];

  /// The models with `@GraphQLPaginate`: each gets a `<Name>Paginator`
  /// type.
  final List<ObjectSpec> paginators = <ObjectSpec>[];
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

  /// The operation annotations of a model, like `@GraphQLAll`.
  static const List<String> operations = <String>[
    'GraphQLAll',
    'GraphQLPaginate',
    'GraphQLFind',
    'GraphQLCreate',
    'GraphQLUpdate',
    'GraphQLDelete',
  ];

  /// Stops the build when [element] has an operation annotation but no
  /// `@GraphQLType`.
  static void checkOperations(ClassElement element) {
    if (annotation(element, 'GraphQLType') != null) return;
    for (String kind in operations) {
      if (annotation(element, kind) == null) continue;
      _fail(
        element.displayName,
        '@$kind() needs @GraphQLType() on the model too.',
        element,
      );
    }
  }

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
    String? filter = _string(type, 'filter');
    if (model == null) {
      if (filter != null) {
        _fail(where, '`filter:` works only on a model of dox_orm.', element);
      }
      for (String kind in operations) {
        if (annotation(element, kind) == null) continue;
        _fail(
          where,
          '@$kind() works only on a model of dox_orm. A plain class has no '
          'table: write a @GraphQLQuery() or @GraphQLMutation() in a '
          'resolver.',
          element,
        );
      }
    }
    imports.prefix(element.library);
    ObjectSpec spec = objects[element] = ObjectSpec(
      element,
      name,
      element.library.uri.toString(),
      description: _string(type, 'description') ?? docOf(element),
    );
    spec.guard = type.getField('guard')?.toBoolValue() ?? false;
    if (model == null) return;
    spec.orm = true;
    spec.filter = filter;
    spec.all = _operation(element, 'GraphQLAll');
    spec.paginate = _operation(element, 'GraphQLPaginate');
    spec.find = _operation(element, 'GraphQLFind');
    spec.create = _operation(element, 'GraphQLCreate');
    spec.update = _operation(element, 'GraphQLUpdate');
    spec.delete = _operation(element, 'GraphQLDelete');
    String? owner = spec.create?.owner;
    if (owner != null) {
      FieldElement? column = _columnNamed(element, owner);
      if (column == null) {
        _fail(
          where,
          '`owner:` must be a column of ${element.displayName}, but it has '
          'no @Column() field "$owner".',
          element,
        );
      }
      DartType ownerType = column.type;
      if (!ownerType.isDartCoreInt && !ownerType.isDartCoreString) {
        _fail(
          where,
          '`owner:` "$owner" must be an int or String column, like the id '
          'of the user, not ${ownerType.getDisplayString()}.',
          element,
        );
      }
      spec.owner = owner;
      spec.ownerType = ownerType.isDartCoreInt ? 'int' : 'String';
    }
    spec.primaryKey = model.getField('primaryKey')?.toStringValue() ?? 'id';
    DartType? key = model.getField('primaryKeyType')?.toTypeValue();
    spec.keyType = key is InterfaceType ? key.element.displayName : 'int';
  }

  /// The operation annotation [kind] of the model [element], or null.
  OperationSpec? _operation(ClassElement element, String kind) {
    DartObject? a = annotation(element, kind);
    if (a == null) return null;
    String where = '${element.displayName} @$kind';
    String? name = _string(a, 'name');
    if (name != null) _checkName(name, where, element);
    ClassElement? dtoElement;
    DartObject? dtoField = a.getField('dto');
    if (dtoField != null) {
      DartType? dto = dtoField.toTypeValue();
      Element? e = dto is InterfaceType ? dto.element : null;
      if (e is! ClassElement || !_dtos.isDto(e)) {
        _fail(
          where,
          '`dto:` must be a class with @Dto(), not '
          '${dto?.getDisplayString() ?? 'null'}.',
          element,
        );
      }
      dtoElement = e;
    }
    String? can = _string(a, 'can');
    if (can != null && can.isEmpty) {
      _fail(where, '`can:` can not be empty.', element);
    }
    return OperationSpec(
      kind,
      name: name,
      description: _string(a, 'description'),
      can: can,
      guard: a.getField('guard')?.toBoolValue() ?? false,
      dto: dtoElement,
      owner: _string(a, 'owner'),
    );
  }

  /// Step 2: the fields of each registered class, and the root fields of
  /// the operation annotations of the models.
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
        relation: true,
        resolve: _relation(field, model),
        // the name toJson() gives a relation, so `hidden` can name it
        column: snakeCase(dartName),
      );
    }
  }

  /// The relations that give a list. They load with a row cap.
  static const List<String> _manyRelations = <String>[
    'HasMany',
    'ManyToMany',
    'HasManyThrough',
    'MorphMany',
  ];

  /// The resolver code of relation [field] of the model [model] (as code).
  /// A list relation loads with `GraphQLOrm.many`, so one request can not
  /// read a huge table. A relation to a model with `filter:` drops the
  /// rows that the ability denies.
  String _relation(FieldElement field, String model) {
    String name = field.displayName;
    DartType type = field.type;
    bool many =
        type is InterfaceType &&
        type.isDartCoreList &&
        _manyRelations.any(
          (String a) => annotation(field, a, package: 'dox_orm') != null,
        );
    String code;
    DartType related = type;
    if (many) {
      related = type.typeArguments.first;
      bool pivot = annotation(field, 'ManyToMany', package: 'dox_orm') != null;
      code =
          'GraphQLOrm.many<$model, ${imports.nonNullCode(related)}>(s, '
          "'$name', info.context, ($model p) => p.$name"
          '${pivot ? ', pivot: true' : ''})';
    } else {
      if (type is InterfaceType && type.isDartCoreList) {
        related = type.typeArguments.first;
      }
      code =
          'GraphQLOrm.relation<$model, ${imports.code(type)}>(s, '
          "'$name', info.context, ($model p) => p.$name)";
    }
    Element? element = related is InterfaceType ? related.element : null;
    String? filter = objects[element]?.filter;
    if (filter == null) return code;
    usesGate = true;
    String relatedModel = imports.nonNullCode(related);
    // a single related row that the filter denies becomes null
    return identical(related, type)
        ? '_filterOne<$relatedModel>(info, ${literal(filter)}, $code)'
        : '_filterList<$relatedModel>(info, ${literal(filter)}, $code)';
  }

  /// Registers the start check of [ability] (of [annotation]) on the model
  /// of [spec], and marks that the code uses `Gate`.
  void _checkAbility(ObjectSpec spec, String annotation, String ability) {
    usesGate = true;
    ClassElement element = spec.element;
    abilityChecks.add(
      AbilityCheck(
        annotation,
        '${imports.prefix(element.library)}.${element.displayName}',
        element.displayName,
        ability,
      ),
    );
  }

  /// `@GraphQLFind(can: 'view')`, for the start check.
  static String _canText(OperationSpec op) =>
      "@${op.annotation}(can: '${op.can}')";

  /// The root fields of the operation annotations of a model:
  /// `@GraphQLAll`, `@GraphQLPaginate`, `@GraphQLFind`, `@GraphQLCreate`,
  /// `@GraphQLUpdate` and `@GraphQLDelete`. A model without them has no
  /// root field.
  void _addModelRoots(ObjectSpec spec) {
    ClassElement element = spec.element;
    String model = '${imports.prefix(element.library)}.${element.displayName}';
    String name = spec.name;
    String id = spec.keyType == 'int'
        ? "int.tryParse(info.args.get<String>('id')!)"
        : "info.args.get<String>('id')!";
    ArgSpec idArg = ArgSpec('id', 'graphqlId.nonNull');
    String? filter = spec.filter;
    if (filter != null) {
      _checkAbility(spec, "@GraphQLType(filter: '$filter')", filter);
    }
    for (OperationSpec? op in <OperationSpec?>[
      spec.all,
      spec.paginate,
      spec.find,
      spec.create,
      spec.update,
      spec.delete,
    ]) {
      String? can = op?.can;
      if (op != null && can != null) _checkAbility(spec, _canText(op), can);
    }
    String many = lcFirst(plural(name));

    OperationSpec? all = spec.all;
    if (all != null) {
      String list = 'GraphQLOrm.list<$model>($model(), info)';
      if (filter != null) {
        list = '_filterList<$model>(info, ${literal(filter)}, $list)';
      }
      _addField(
        query,
        FieldSpec(
          name: all.name ?? many,
          type: '${spec.variable}.nonNull.list.nonNull',
          description: all.description,
          args: <ArgSpec>[
            ArgSpec('limit', 'graphqlInt', defaultValue: '20'),
            ArgSpec('offset', 'graphqlInt', defaultValue: '0'),
          ],
          resolve: _typeCheck(all, model, list),
          where: '@GraphQLAll on ${element.displayName}',
          guard: all.guard,
        ),
        'Query',
        element,
      );
    }

    OperationSpec? paginate = spec.paginate;
    if (paginate != null) {
      _claimTypeName('${name}Paginator', '@GraphQLPaginate on $name', element);
      if (paginators.isEmpty) {
        _claimTypeName('PaginatorInfo', '@GraphQLPaginate on $name', element);
      }
      paginators.add(spec);
      String page = 'GraphQLOrm.paginate<$model>($model(), info)';
      if (filter != null) {
        page = '_filterPage<$model>(info, ${literal(filter)}, $page)';
      }
      _addField(
        query,
        FieldSpec(
          name: paginate.name ?? (all == null ? many : '${many}Paginate'),
          type: '${spec.paginator}.nonNull',
          description: paginate.description,
          args: <ArgSpec>[
            ArgSpec('first', 'graphqlInt', defaultValue: '20'),
            ArgSpec('page', 'graphqlInt', defaultValue: '1'),
          ],
          resolve: _typeCheck(paginate, model, page),
          where: '@GraphQLPaginate on ${element.displayName}',
          guard: paginate.guard,
        ),
        'Query',
        element,
      );
    }

    OperationSpec? find = spec.find;
    if (find != null) {
      String read = 'GraphQLOrm.find<$model>($model(), $id)';
      String? can = find.can;
      if (can != null || filter != null) {
        String check = can == null
            ? ''
            : '''
  await (model == null
      ? _allowMissing(info, ${literal(can)}, $model())
      : _allow(info, ${literal(can)}, model));''';
        // a row that the filter denies gives null, like a missing id
        String result = filter == null
            ? 'model'
            : 'await _filterOne<$model>(info, ${literal(filter)}, '
                  'Future<$model?>.value(model))';
        functions.add('''
/// The $name with the id, after the `can:` check and the `filter:` of
/// the type. A missing id is checked as a blank $name, so a denied user
/// gets the same error for an id that exists and one that does not. A
/// row that the filter denies gives null, like a missing id.
Future<$model?> _find$name(ResolveInfo<DoxGraphQLContext> info) async {
  $model? model = await $read;$check
  return $result;
}
''');
        read = '_find$name(info)';
      }
      _addField(
        query,
        FieldSpec(
          name: find.name ?? lcFirst(name),
          type: spec.variable,
          description: find.description,
          args: <ArgSpec>[idArg],
          resolve: read,
          where: '@GraphQLFind on ${element.displayName}',
          guard: find.guard,
        ),
        'Query',
        element,
      );
    }

    OperationSpec? create = spec.create;
    if (create != null) _addCreate(spec, create, model);
    OperationSpec? update = spec.update;
    if (update != null) _addUpdate(spec, update, model, id, idArg);

    OperationSpec? delete = spec.delete;
    if (delete != null) {
      String? can = delete.can;
      String missing = can == null
          ? ''
          : '\n    await _allowMissing(info, ${literal(can)}, $model());';
      String allow = can == null
          ? ''
          : '\n  await _allow(info, ${literal(can)}, model);';
      functions.add('''
/// Deletes a $name. False when there is no $name with that id.
Future<bool> _delete$name(ResolveInfo<DoxGraphQLContext> info) async {
  $model? model = await GraphQLOrm.find<$model>($model(), $id);
  if (model == null) {$missing
    return false;
  }$allow
  await model.delete();
  return true;
}
''');
      _addField(
        mutation,
        FieldSpec(
          name: delete.name ?? 'delete$name',
          type: 'graphqlBoolean.nonNull',
          description: delete.description,
          args: <ArgSpec>[idArg],
          resolve: '_delete$name(info)',
          where: '@GraphQLDelete on ${element.displayName}',
          // it gives a Boolean, so the guard of the type does not reach it
          guard: delete.guard || spec.guard,
        ),
        'Mutation',
        element,
      );
    }
  }

  /// [code] after the `can:` check of [op] on the model type, when it has
  /// one.
  static String _typeCheck(OperationSpec op, String model, String code) {
    String? can = op.can;
    if (can == null) return code;
    return '_allow(info, ${literal(can)}, $model).then((_) => $code)';
  }

  void _addCreate(ObjectSpec spec, OperationSpec op, String model) {
    ClassElement element = spec.element;
    String name = spec.name;
    ClassElement dtoElement = op.dto!;
    InputSpec input = inputOf(dtoElement, name: 'Create${name}Input')
      ..validated = true;
    String dto =
        '${imports.prefix(dtoElement.library)}.${dtoElement.displayName}';
    _DtoCode code = _dtoCode(spec, dtoElement, 'GraphQLCreate');
    String? owner = spec.owner;
    String ownerSet = owner == null
        ? ''
        : '\n  model.$owner = await GraphQLAuth.ownerId<${spec.ownerType}>('
              "info.context, '${element.displayName}.$owner');";
    String? can = op.can;
    String allow = can == null
        ? ''
        : '\n  await _allow(info, ${literal(can)}, $model);';
    functions.add('''
/// Makes a $name from the input of `@GraphQLCreate`.
Future<$model> _create$name(ResolveInfo<DoxGraphQLContext> info) async {$allow
  $dto dto = await ${input.validate}(info.args.input('input')!, info.context);
  $model model = $model()${code.sets.join()};$ownerSet
  await model.save();
  return model;
}
''');
    _addField(
      mutation,
      FieldSpec(
        name: op.name ?? 'create$name',
        type: '${spec.variable}.nonNull',
        description: op.description,
        args: <ArgSpec>[ArgSpec('input', '${input.variable}.nonNull')],
        resolve: '_create$name(info)',
        where: '@GraphQLCreate on ${element.displayName}',
        // the owner is the logged-in user, so there must be one
        guard: op.guard || owner != null,
      ),
      'Mutation',
      element,
    );
  }

  void _addUpdate(
    ObjectSpec spec,
    OperationSpec op,
    String model,
    String id,
    ArgSpec idArg,
  ) {
    ClassElement element = spec.element;
    String name = spec.name;
    ClassElement dtoElement = op.dto!;
    InputSpec input = inputOf(dtoElement, name: 'Update${name}Input');
    String dtoPrefix = imports.prefix(dtoElement.library);
    String dto = '$dtoPrefix.${dtoElement.displayName}';
    String schema = '$dtoPrefix.\$${dtoElement.displayName}Dto';
    _DtoCode code = _dtoCode(spec, dtoElement, 'GraphQLUpdate');
    String key = camelCase(spec.primaryKey);
    String? can = op.can;
    String missing = can == null
        ? ''
        : '\n    await _allowMissing(info, ${literal(can)}, $model());';
    String allow = can == null
        ? ''
        : '\n  await _allow(info, ${literal(can)}, model);';
    functions.add('''
/// Sets the fields the client sent on a $name. Null when there is no
/// $name with that id.
Future<$model?> _update$name(ResolveInfo<DoxGraphQLContext> info) async {
  $model? model = await GraphQLOrm.find<$model>($model(), $id);
  if (model == null) {$missing
    return null;
  }$allow
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = ${input.toMap}(input);
  // the other fields keep their stored values, and are not checked
  $dto dto = await GraphQLDto.validateSent<$dto>(
    $schema,
    <String, Object?>{${code.current.join()} ...given},
    info.context,
    sent: given.keys.toSet(),
    placeholders: const <String, Object?>{${code.placeholders.join()}},
    names: const <String, String>{${code.names.join()}},
    params: <String, String>{'id': '\${model.$key}'},
  );
  ${code.updates.join('\n  ')}
  await model.save();
  return model;
}
''');
    _addField(
      mutation,
      FieldSpec(
        name: op.name ?? 'update$name',
        type: spec.variable,
        description: op.description,
        args: <ArgSpec>[idArg, ArgSpec('input', '${input.variable}.nonNull')],
        resolve: '_update$name(info)',
        where: '@GraphQLUpdate on ${element.displayName}',
        guard: op.guard,
      ),
      'Mutation',
      element,
    );
  }

  /// The code that sets the fields of the `@Dto` class [dtoElement] on the
  /// model of [spec], with the build checks of each field.
  _DtoCode _dtoCode(ObjectSpec spec, ClassElement dtoElement, String kind) {
    ClassElement element = spec.element;
    _DtoCode code = _DtoCode();
    for (DtoField field in _dtos.read(dtoElement).fields) {
      String where = '${dtoElement.displayName}.${field.name}';
      if (field.maybe) {
        _fail(
          where,
          'a Maybe field can not be in the `dto:` of @$kind. The update '
          'mutation already sets only the fields the client sends.',
          field.element,
        );
      }
      if (field.name == spec.owner) {
        _fail(
          where,
          '"${field.name}" is the `owner:` of ${element.displayName}, so it '
          'can not be in the `dto:` of @$kind. The create mutation sets it '
          'to the id of the logged-in user, and the update never changes '
          'it. Remove it from the DTO.',
          field.element,
        );
      }
      FieldElement? column = _columnNamed(element, field.name);
      if (column == null) {
        _fail(
          where,
          '${element.displayName} has no @Column() field "${field.name}". '
          'The `dto:` of @$kind can set only its columns.',
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
          'the `dto:` of @$kind can set only text, number, bool, DateTime '
          'and enum columns.',
          field.element,
        ),
      };
      code.sets.add('..${field.name} = dto.${field.name}');
      code.updates.add(
        "if (input.has('${field.name}')) "
        'model.${field.name} = dto.${field.name};',
      );
      code.current.add("'${field.key}': $value,");
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
      code.placeholders.add("'${field.key}': $placeholder,");
      if (field.key != field.name) {
        code.names.add("'${field.key}': '${field.name}',");
      }
    }
    return code;
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
            'arguments, write a @GraphQLResolveField() method in a resolver.',
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
    bool relation = false,
  }) {
    String where = '${spec.element.displayName}.$dartName';
    DartObject? field = annotation(annotated, 'GraphQLField');
    String name = _string(field, 'name') ?? dartName;
    _checkName(name, where, member);
    String gql = _outputType(_unwrapFuture(type), where, member);
    bool fieldGuard = field?.getField('guard')?.toBoolValue() ?? false;
    // A relation can fail on its own (a policy, a login, the row cap, a
    // database error), so it is always nullable. Another field is nullable
    // when it can be refused. A non-null field would null the parent. List
    // items stay non-null: a policy drops a row, it does not null it.
    if (relation || _mayRefuse(type, fieldGuard)) gql = _nullable(gql);
    _addField(
      spec.fields,
      FieldSpec(
        name: name,
        type: gql,
        resolve: resolve ?? 's.$dartName',
        where: where,
        description: _string(field, 'description') ?? docOf(member),
        deprecationReason: _string(field, 'deprecationReason'),
        guard: fieldGuard,
        column: column,
      ),
      spec.name,
      member,
    );
  }

  /// True when a field can be refused at run time, so it must be nullable:
  /// it has `guard: true`, or it gives a registered type with
  /// `guard: true`. Like `GraphQLAuth.needsLogin`.
  bool _mayRefuse(DartType type, bool fieldGuard) {
    if (fieldGuard) return true;
    DartType related = _unwrapFuture(type);
    if (related is InterfaceType && related.isDartCoreList) {
      related = related.typeArguments.first;
    }
    Element? element = related is InterfaceType ? related.element : null;
    return objects[element]?.guard ?? false;
  }

  // ---------------------------------------------------------------------
  // Resolvers
  // ---------------------------------------------------------------------

  /// True when [element] has a `@GraphQLQuery`, `@GraphQLMutation` or
  /// `@GraphQLResolveField` method.
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
      'GraphQLResolveField',
    ]) {
      if (annotation(method, kind) != null) return kind;
    }
    return null;
  }

  /// Reads the `@GraphQLQuery`, `@GraphQLMutation` and `@GraphQLResolveField` methods of
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
    if (kind == 'GraphQLResolveField') {
      DartType? first = params.isEmpty ? null : params.first.type;
      Element? firstElement = first is InterfaceType ? first.element : null;
      parent = firstElement is ClassElement ? objects[firstElement] : null;
      if (parent == null ||
          !params.first.isPositional ||
          first!.nullabilitySuffix == NullabilitySuffix.question) {
        _fail(
          where,
          'the first parameter of a @GraphQLResolveField() method must be the '
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
    bool methodGuard = ann.getField('guard')?.toBoolValue() ?? false;
    // a root field is made nullable in _addField
    if (_mayRefuse(returnType, methodGuard)) type = _nullable(type);
    FieldSpec field = FieldSpec(
      name: name,
      type: type,
      resolve: '$instance.${method.displayName}(${values.join(', ')})',
      where: where,
      description: _string(ann, 'description') ?? docOf(method),
      deprecationReason: _string(ann, 'deprecationReason'),
      guard: methodGuard,
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
    // A root field is always nullable: an error (login, policy, DTO,
    // database) then nulls only this field, not all of `data`.
    if (identical(fields, query) || identical(fields, mutation)) {
      field.type = _nullable(field.type);
    }
    fields.add(field);
  }

  /// [type] without its outer `.nonNull`. List items stay non-null.
  static String _nullable(String type) {
    const String suffix = '.nonNull';
    return type.endsWith(suffix)
        ? type.substring(0, type.length - suffix.length)
        : type;
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

/// The code of each field of a `@Dto` class of a create or update.
class _DtoCode {
  /// `..title = dto.title`
  final List<String> sets = <String>[];

  /// `if (input.has('title')) model.title = dto.title;`
  final List<String> updates = <String>[];

  /// `'title': model.title,`: the stored values
  final List<String> current = <String>[];

  /// `'title': '-',`: a value of the right type for each field
  final List<String> placeholders = <String>[];

  /// `'user_id': 'userId',`: the input keys that differ from the names
  final List<String> names = <String>[];
}

/// [text] as a Dart string literal.
String literal(String text) {
  String escaped = text
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
  return "'$escaped'";
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
  // with an odd plural sets `name:` on @GraphQLAll.
  if (RegExp(r'[^aeiou]y$').hasMatch(name)) {
    return '${name.substring(0, name.length - 1)}ies';
  }
  if (RegExp(r'(s|x|z|ch|sh)$').hasMatch(name)) return '${name}es';
  return '${name}s';
}
