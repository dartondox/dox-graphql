import 'package:analyzer/dart/element/element.dart';

import 'schema_model.dart';
import 'schema_reader.dart';

/// Writes the code of `lib/generated/schema.g.dart` from the specs of a
/// [SchemaReader].
class SchemaWriter {
  SchemaWriter(this.reader);

  final SchemaReader reader;

  static const String _context = 'DoxGraphQLContext';
  static const String _info = 'ResolveInfo<$_context> info';

  /// The `can:` and `filter:` checks.
  static const String _allow =
      '''
/// Asks `Gate` (a policy registered with `Gate.policy`, or a
/// `Gate.define`) if the user may do [ability] on [subject]: a row, or
/// the model type. Throws when not: "Unauthenticated" for a guest, else
/// "Forbidden".
Future<void> _allow(
  ResolveInfo<$_context> info,
  String ability,
  Object subject,
) async {
  Object? user = await info.context.user<Object>();
  if (!await Gate.allows(user, ability, subject)) throw _denied(user);
}

/// [_allow] for an id with no row: [blank] is a new, empty row. A user
/// the policy denies gets the same error as for a row that exists, so the
/// answer does not show which ids exist. Any error of the policy on the
/// empty row (a null check, a `late` field that is not set, a parse of an
/// empty value) denies: an id that does not exist must not give another
/// answer than one the user may not see.
Future<void> _allowMissing(
  ResolveInfo<$_context> info,
  String ability,
  Object blank,
) async {
  Object? user = await info.context.user<Object>();
  bool allowed;
  try {
    allowed = await Gate.allows(user, ability, blank);
  } on Object {
    allowed = false;
  }
  if (!allowed) throw _denied(user);
}

/// The rows of [rows] that [ability] allows (`filter:`). The others are
/// left out, with no error.
Future<List<T>?> _filterList<T extends Object>(
  ResolveInfo<$_context> info,
  String ability,
  Future<List<T>?> rows,
) async {
  List<T>? list = await rows;
  if (list == null || list.isEmpty) return list;
  Object? user = await info.context.user<Object>();
  return <T>[
    for (T row in list)
      if (await Gate.allows(user, ability, row)) row,
  ];
}

/// [row] when [ability] allows it (`filter:`), else null.
Future<T?> _filterOne<T extends Object>(
  ResolveInfo<$_context> info,
  String ability,
  Future<T?> row,
) async {
  T? value = await row;
  if (value == null) return null;
  Object? user = await info.context.user<Object>();
  return await Gate.allows(user, ability, value) ? value : null;
}

/// [page] with only the rows that [ability] allows (`filter:`). The
/// count query ran before, so `total` and `lastPage` still count the
/// rows that are left out, and `firstItem` and `lastItem` give the rows
/// of the page before the filter.
Future<Pagination<T>> _filterPage<T extends Object>(
  ResolveInfo<$_context> info,
  String ability,
  Future<Pagination<T>> page,
) async {
  Pagination<T> result = await page;
  List<T> kept = (await _filterList<T>(info, ability, Future<List<T>>.value(result.data)))!;
  return GraphQLOrm.filteredPage<T>(result, kept);
}

GraphQLError _denied(Object? user) =>
    user == null ? GraphQLAuth.unauthenticatedError() : GraphQLAuth.forbidden();
''';

  /// The start check of the abilities of `can:` and `filter:`.
  static const String _checkAbility = r'''
/// Throws when [ability] (of [annotation] on [model]) is not an ability
/// of the policy of [M]: a typo. A model with no policy needs a
/// `Gate.define` of [ability].
void _checkAbility<M>(String annotation, String model, String ability) {
  Policy<dynamic, M>? policy = Gate.policyOf<M>();
  if (policy == null) {
    if (Gate.isDefined(ability)) return;
    throw StateError(
      '$annotation on $model: $model has no policy and there is no '
      "Gate.define('$ability'). Register the policy with "
      'Gate.policy<$model>(...) in the setup() of a provider: the check '
      'runs in GraphQLProvider.boot(), after every setup().',
    );
  }
  if (policy.has(ability)) return;
  throw StateError(
    "$annotation on $model: ${policy.runtimeType} has no ability "
    "'$ability'. Available: ${policy.abilities.keys.join(', ')}.",
  );
}
''';

  String write() {
    StringBuffer out = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln(
        '// Made by dox_graphql_builder. Run `dart run build_runner build`.',
      )
      // the `can:` helpers are written as one block: some may be unused
      ..writeln('// ignore_for_file: type=lint, unused_element')
      ..writeln()
      ..writeln("import 'package:dox_graphql/dox_graphql.dart';");
    if (reader.hasModels) {
      out.writeln("import 'package:dox_graphql_orm/dox_graphql_orm.dart';");
    }
    if (reader.usesGate) {
      out.writeln("import 'package:dox_auth/dox_auth.dart' show Gate, Policy;");
    }
    StringBuffer body = StringBuffer();
    _writeSchema(body);
    for (ObjectSpec object in reader.objects.values) {
      _writeObject(body, object);
    }
    for (ObjectSpec object in reader.paginators) {
      _writePaginator(body, object);
    }
    for (EnumSpec spec in reader.enums.values) {
      _writeEnum(body, spec);
    }
    for (InputSpec input in reader.inputs.values) {
      _writeInput(body, input);
    }
    for (String function in reader.functions) {
      body.writeln(function);
    }
    if (reader.usesGate) body.writeln(_allow);
    if (reader.abilityChecks.isNotEmpty) {
      body
        ..writeln('/// The abilities of `can:` and `filter:`, checked when the')
        ..writeln('/// app starts (`GraphQLSchema.startChecks`).')
        ..writeln('void _checkAbilities() {');
      for (AbilityCheck check in reader.abilityChecks) {
        body.writeln(
          '_checkAbility<${check.model}>(${literal(check.annotation)}, '
          '${literal(check.modelName)}, ${literal(check.ability)});',
        );
      }
      body
        ..writeln('}')
        ..writeln()
        ..writeln(_checkAbility);
    }
    // the imports last: writing the code finds the prefixes
    for (MapEntry<String, String> import in reader.imports.prefixes.entries) {
      out.writeln("import '${import.key}' as ${import.value};");
    }
    out
      ..writeln()
      ..write(body);
    return out.toString();
  }

  void _writeSchema(StringBuffer out) {
    out
      ..writeln('/// The GraphQL schema of the app, made from the')
      ..writeln(
        '/// `@GraphQL`, `@GraphQLAll`, `@GraphQLQuery`, ... annotations.',
      )
      ..writeln('/// Use it in `GraphQLConfig(schema: graphqlSchema)`.')
      ..writeln(
        'final GraphQLSchema<$_context> graphqlSchema = '
        'GraphQLSchema<$_context>(',
      )
      ..writeln('query: ${_root('Query', reader.query)},');
    if (reader.mutation.isNotEmpty) {
      out.writeln('mutation: ${_root('Mutation', reader.mutation)},');
    }
    out.writeln('types: <NamedType>[');
    for (ObjectSpec object in reader.objects.values) {
      out.writeln('${object.variable},');
    }
    for (ObjectSpec object in reader.paginators) {
      out.writeln('${object.paginator},');
    }
    if (reader.paginators.isNotEmpty) out.writeln('GraphQLOrm.paginatorInfo,');
    out.writeln('],');
    if (reader.abilityChecks.isNotEmpty) {
      out.writeln('startChecks: <void Function()>[_checkAbilities],');
    }
    out
      ..writeln(');')
      ..writeln();
  }

  /// The `<Name>Paginator` type of a model with `@GraphQLPaginate`.
  void _writePaginator(StringBuffer out, ObjectSpec object) {
    String dartType =
        'Pagination<${_prefix(object.library)}.${object.element.displayName}>';
    String type = 'ObjectType<$dartType, $_context>';
    String field = 'Field<$dartType, $_context>';
    out
      ..writeln('final $type ${object.paginator} = $type(')
      ..writeln('${literal('${object.name}Paginator')},')
      ..writeln("description: 'A page of ${object.name} rows.',");
    // the page of a guarded type needs a login too, before the queries run
    if (object.guard) out.writeln('guard: true,');
    out
      ..writeln('fields: () => <$field>[')
      ..writeln(
        "$field('data', ${object.variable}.nonNull.list.nonNull, "
        'resolve: ($dartType s, $_info) => s.data,),',
      )
      ..writeln(
        "$field('paginatorInfo', GraphQLOrm.paginatorInfo.nonNull, "
        'resolve: ($dartType s, $_info) => s,),',
      )
      ..writeln('],')
      ..writeln(');')
      ..writeln();
  }

  String _root(String name, List<FieldSpec> fields) {
    StringBuffer out = StringBuffer()
      ..writeln('ObjectType<Object?, $_context>(')
      ..writeln("'$name',")
      ..writeln('fields: () => <Field<Object?, $_context>>[');
    for (FieldSpec field in fields) {
      out.writeln('${_field(field, 'Object?', '_')},');
    }
    out.write('],)');
    return out.toString();
  }

  void _writeObject(StringBuffer out, ObjectSpec object) {
    String dartType =
        '${_prefix(object.library)}.${object.element.displayName}';
    String type = 'ObjectType<$dartType, $_context>';
    out
      ..writeln('final $type ${object.variable} = $type(')
      ..writeln('${literal(object.name)},');
    if (object.description != null) {
      out.writeln('description: ${literal(object.description!)},');
    }
    if (object.guard) out.writeln('guard: true,');
    if (object.orm) {
      // a column or relation in `hidden` of the model is left out, so it
      // never leaks. With `visibleFields`, only those are shown.
      out
        ..writeln('fields: () {')
        ..writeln('$dartType model = $dartType();')
        ..writeln('List<String> hidden = model.hidden;')
        ..writeln('List<String> visible = model.visibleFields;')
        ..writeln(
          'bool show(String name) => !hidden.contains(name) && '
          '(visible.isEmpty || visible.contains(name));',
        )
        ..writeln('return <Field<$dartType, $_context>>[');
    } else {
      out.writeln('fields: () => <Field<$dartType, $_context>>[');
    }
    for (FieldSpec field in object.fields) {
      out.writeln('${_field(field, dartType, 's')},');
    }
    out.writeln(object.orm ? '];},' : '],');
    out
      ..writeln(');')
      ..writeln();
  }

  /// One `Field(...)` of a parent of Dart type [parent]. [source] is the
  /// name of the parent parameter of the resolver.
  String _field(FieldSpec field, String parent, String source) {
    StringBuffer out = StringBuffer()
      ..write('Field<$parent, $_context>(')
      ..write('${literal(field.name)}, ${field.type},');
    if (field.description != null) {
      out.write('description: ${literal(field.description!)},');
    }
    if (field.deprecationReason != null) {
      out.write('deprecationReason: ${literal(field.deprecationReason!)},');
    }
    if (field.guard) out.write('guard: true,');
    if (field.args.isNotEmpty) {
      out.write('args: <Argument>[');
      for (ArgSpec arg in field.args) {
        out.write('Argument(${literal(arg.name)}, ${arg.type}');
        if (arg.defaultValue != null) {
          out.write(', defaultValue: ${literal(arg.defaultValue!)}');
        }
        out.write('),');
      }
      out.write('],');
    }
    String async = field.isAsync ? ' async' : '';
    out.write('resolve: ($parent $source, $_info)$async => ${field.resolve},)');
    String text = out.toString();
    String? column = field.column;
    return column == null ? text : 'if (show(${literal(column)})) $text';
  }

  void _writeEnum(StringBuffer out, EnumSpec spec) {
    String dartType = '${_prefix(spec.library)}.${spec.name}';
    out.writeln(
      'final EnumType<$dartType> ${spec.variable} = '
      'EnumType<$dartType>(${literal(spec.name)}, <EnumValue<$dartType>>[',
    );
    for (FieldElement constant in spec.element.constants) {
      String value = constant.displayName;
      out.writeln('EnumValue<$dartType>(${literal(value)}, $dartType.$value),');
    }
    out
      ..writeln(']);')
      ..writeln();
  }

  void _writeInput(StringBuffer out, InputSpec input) {
    String prefix = _prefix(input.library);
    String dto = '$prefix.${input.element.displayName}';
    out
      ..writeln('final InputObjectType ${input.variable} = InputObjectType(')
      ..writeln('${literal(input.name)},');
    if (input.description != null) {
      out.writeln('description: ${literal(input.description!)},');
    }
    out.writeln('fields: () => <InputField>[');
    for (InputFieldSpec field in input.fields) {
      out.writeln('InputField(${literal(field.name)}, ${field.type}),');
    }
    out
      ..writeln('],')
      ..writeln(');')
      ..writeln()
      ..writeln('Map<String, Object?> ${input.toMap}(InputValues v) {')
      ..writeln('return <String, Object?>{');
    for (InputFieldSpec field in input.fields) {
      out.writeln(
        "if (v.has('${field.name}')) ${literal(field.key)}: ${field.convert},",
      );
    }
    out
      ..writeln('};')
      ..writeln('}')
      ..writeln();
    // a nested DTO is checked by the DTO it is in
    if (!input.validated) return;
    out
      ..writeln(
        'Future<$dto> ${input.validate}(InputValues v, $_context context) {',
      )
      ..writeln(
        'return GraphQLDto.validate<$dto>($prefix.\$${input.element.displayName}Dto, '
        '${input.toMap}(v), context, names: const <String, String>{',
      );
    for (InputFieldSpec field in input.fields) {
      if (field.key != field.name) {
        out.writeln('${literal(field.key)}: ${literal(field.name)},');
      }
    }
    out
      ..writeln('},);')
      ..writeln('}')
      ..writeln();
  }

  String _prefix(String library) => reader.imports.prefixes[library]!;
}
