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

  /// The policy checks of the models with `policy:`.
  static const String _allow =
      '''
/// Asks the policy (registered with `Gate.policy`) if the user may do
/// [ability] on [subject]: a row, or the model type. Throws when not:
/// "Unauthenticated" for a guest, else "Forbidden".
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
/// answer does not show which ids exist. A policy that throws on the
/// blank row denies.
Future<void> _allowMissing(
  ResolveInfo<$_context> info,
  String ability,
  Object blank,
) async {
  Object? user = await info.context.user<Object>();
  bool allowed;
  try {
    allowed = await Gate.allows(user, ability, blank);
  } catch (_) {
    allowed = false;
  }
  if (!allowed) throw _denied(user);
}

/// "Unauthenticated" before the row lookup, when the policy denies every
/// guest.
Future<void> _login(ResolveInfo<$_context> info) async {
  if (await info.context.auth() == null) throw GraphQLAuth.unauthenticatedError();
}

GraphQLError _denied(Object? user) =>
    user == null ? GraphQLAuth.unauthenticatedError() : GraphQLAuth.forbidden();
''';

  String write() {
    StringBuffer out = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln(
        '// Made by dox_graphql_builder. Run `dart run build_runner build`.',
      )
      ..writeln('// ignore_for_file: type=lint')
      ..writeln()
      ..writeln("import 'package:dox_graphql/dox_graphql.dart';");
    if (reader.hasModels) {
      out.writeln("import 'package:dox_graphql_orm/dox_graphql_orm.dart';");
    }
    if (reader.hasPolicies) {
      out.writeln("import 'package:dox_auth/dox_auth.dart' show Gate;");
    }
    StringBuffer body = StringBuffer();
    _writeSchema(body);
    for (ObjectSpec object in reader.objects.values) {
      _writeObject(body, object);
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
    if (reader.hasPolicies) body.writeln(_allow);
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
        '/// `@GraphQLType`, `@GraphQLQuery` and `@GraphQLMutation` annotations.',
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
    out
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
      ..writeln('${_string(object.name)},');
    if (object.description != null) {
      out.writeln('description: ${_string(object.description!)},');
    }
    if (object.auth != null) out.writeln('auth: ${object.auth},');
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
    String kind = field.auto ? 'AutoField' : 'Field';
    StringBuffer out = StringBuffer()
      ..write('$kind<$parent, $_context>(')
      ..write('${_string(field.name)}, ${field.type},');
    if (field.description != null) {
      out.write('description: ${_string(field.description!)},');
    }
    if (field.deprecationReason != null) {
      out.write('deprecationReason: ${_string(field.deprecationReason!)},');
    }
    if (field.auth != null) out.write('auth: ${field.auth},');
    if (field.args.isNotEmpty) {
      out.write('args: <Argument>[');
      for (ArgSpec arg in field.args) {
        out.write('Argument(${_string(arg.name)}, ${arg.type}');
        if (arg.defaultValue != null) {
          out.write(', defaultValue: ${_string(arg.defaultValue!)}');
        }
        out.write('),');
      }
      out.write('],');
    }
    String async = field.isAsync ? ' async' : '';
    out.write('resolve: ($parent $source, $_info)$async => ${field.resolve},)');
    String text = out.toString();
    String? column = field.column;
    return column == null ? text : 'if (show(${_string(column)})) $text';
  }

  void _writeEnum(StringBuffer out, EnumSpec spec) {
    String dartType = '${_prefix(spec.library)}.${spec.name}';
    out.writeln(
      'final EnumType<$dartType> ${spec.variable} = '
      'EnumType<$dartType>(${_string(spec.name)}, <EnumValue<$dartType>>[',
    );
    for (FieldElement constant in spec.element.constants) {
      String value = constant.displayName;
      out.writeln('EnumValue<$dartType>(${_string(value)}, $dartType.$value),');
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
      ..writeln('${_string(input.name)},');
    if (input.description != null) {
      out.writeln('description: ${_string(input.description!)},');
    }
    out.writeln('fields: () => <InputField>[');
    for (InputFieldSpec field in input.fields) {
      out.writeln('InputField(${_string(field.name)}, ${field.type}),');
    }
    out
      ..writeln('],')
      ..writeln(');')
      ..writeln()
      ..writeln('Map<String, Object?> ${input.toMap}(InputValues v) {')
      ..writeln('return <String, Object?>{');
    for (InputFieldSpec field in input.fields) {
      out.writeln(
        "if (v.has('${field.name}')) ${_string(field.key)}: ${field.convert},",
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
        out.writeln('${_string(field.key)}: ${_string(field.name)},');
      }
    }
    out
      ..writeln('},);')
      ..writeln('}')
      ..writeln();
  }

  String _prefix(String library) => reader.imports.prefixes[library]!;

  /// [text] as a Dart string literal.
  static String _string(String text) {
    String escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
    return "'$escaped'";
  }
}
