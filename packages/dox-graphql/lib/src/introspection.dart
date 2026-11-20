import 'package:gql/ast.dart';
import 'package:meta/meta.dart';

import 'scalars.dart';
import 'schema.dart';
import 'types.dart';

/// The introspection types, meta fields and built-in directives.
@internal
final class Introspection {
  const Introspection._();

  static final ObjectType<GraphQLSchema<Object?>, Object?> schemaType =
      ObjectType<GraphQLSchema<Object?>, Object?>(
        '__Schema',
        description:
            'A GraphQL Schema defines the capabilities of a GraphQL server. '
            'It exposes all available types and directives on the server, '
            'as well as the entry points for query, mutation, and '
            'subscription operations.',
        fields: _schemaFields,
      );

  static List<Field<GraphQLSchema<Object?>, Object?>> _schemaFields() {
    return <Field<GraphQLSchema<Object?>, Object?>>[
      Field<GraphQLSchema<Object?>, Object?>(
        'description',
        graphqlString,
        resolve: (GraphQLSchema<Object?> s, ResolveInfo<Object?> i) =>
            s.description,
      ),
      Field<GraphQLSchema<Object?>, Object?>(
        'types',
        typeType.nonNull.list.nonNull,
        description: 'A list of all types supported by this server.',
        resolve: (GraphQLSchema<Object?> s, ResolveInfo<Object?> i) =>
            s.typeMap.values.toList(),
      ),
      Field<GraphQLSchema<Object?>, Object?>(
        'queryType',
        typeType.nonNull,
        description: 'The type that query operations will be rooted at.',
        resolve: (GraphQLSchema<Object?> s, ResolveInfo<Object?> i) => s.query,
      ),
      Field<GraphQLSchema<Object?>, Object?>(
        'mutationType',
        typeType,
        description:
            'If this server supports mutation, the type that mutation '
            'operations will be rooted at.',
        resolve: (GraphQLSchema<Object?> s, ResolveInfo<Object?> i) =>
            s.mutation,
      ),
      Field<GraphQLSchema<Object?>, Object?>(
        'subscriptionType',
        typeType,
        description:
            'If this server support subscription, the type that '
            'subscription operations will be rooted at.',
        resolve: (GraphQLSchema<Object?> s, ResolveInfo<Object?> i) => null,
      ),
      Field<GraphQLSchema<Object?>, Object?>(
        'directives',
        directiveType.nonNull.list.nonNull,
        description: 'A list of all directives supported by this server.',
        resolve: (GraphQLSchema<Object?> s, ResolveInfo<Object?> i) =>
            s.directives,
      ),
    ];
  }

  static final EnumType<String> typeKind = EnumType<String>(
    '__TypeKind',
    <EnumValue<String>>[
      EnumValue<String>(
        'SCALAR',
        'SCALAR',
        description: 'Indicates this type is a scalar.',
      ),
      EnumValue<String>(
        'OBJECT',
        'OBJECT',
        description:
            'Indicates this type is an object. `fields` and `interfaces` '
            'are valid fields.',
      ),
      EnumValue<String>(
        'INTERFACE',
        'INTERFACE',
        description:
            'Indicates this type is an interface. `fields`, `interfaces`, '
            'and `possibleTypes` are valid fields.',
      ),
      EnumValue<String>(
        'UNION',
        'UNION',
        description:
            'Indicates this type is a union. `possibleTypes` is a valid '
            'field.',
      ),
      EnumValue<String>(
        'ENUM',
        'ENUM',
        description:
            'Indicates this type is an enum. `enumValues` is a valid field.',
      ),
      EnumValue<String>(
        'INPUT_OBJECT',
        'INPUT_OBJECT',
        description:
            'Indicates this type is an input object. `inputFields` is a '
            'valid field.',
      ),
      EnumValue<String>(
        'LIST',
        'LIST',
        description:
            'Indicates this type is a list. `ofType` is a valid field.',
      ),
      EnumValue<String>(
        'NON_NULL',
        'NON_NULL',
        description:
            'Indicates this type is a non-null. `ofType` is a valid field.',
      ),
    ],
    description: 'An enum describing what kind of type a given `__Type` is.',
  );

  static String _kind(GraphQLType t) => switch (t) {
    ScalarType<Object>() => 'SCALAR',
    ObjectType<Object?, Object?>() => 'OBJECT',
    InterfaceType() => 'INTERFACE',
    UnionType() => 'UNION',
    EnumType<Object?>() => 'ENUM',
    InputObjectType() => 'INPUT_OBJECT',
    ListType() => 'LIST',
    NonNullType() => 'NON_NULL',
  };

  static Argument _includeDeprecated() =>
      Argument('includeDeprecated', graphqlBoolean, defaultValue: 'false');

  static bool _withDeprecated(ResolveInfo<Object?> i) =>
      i.args.get<bool>('includeDeprecated') ?? false;

  static final ObjectType<GraphQLType, Object?> typeType =
      ObjectType<GraphQLType, Object?>(
        '__Type',
        description:
            'The fundamental unit of any GraphQL Schema is the type. There '
            'are many kinds of types in GraphQL as represented by the '
            '`__TypeKind` enum.',
        fields: _typeFields,
      );

  static List<Field<GraphQLType, Object?>> _typeFields() {
    return <Field<GraphQLType, Object?>>[
      Field<GraphQLType, Object?>(
        'kind',
        typeKind.nonNull,
        resolve: (GraphQLType t, ResolveInfo<Object?> i) => _kind(t),
      ),
      Field<GraphQLType, Object?>(
        'name',
        graphqlString,
        resolve: (GraphQLType t, ResolveInfo<Object?> i) =>
            t is NamedType ? t.name : null,
      ),
      Field<GraphQLType, Object?>(
        'description',
        graphqlString,
        resolve: (GraphQLType t, ResolveInfo<Object?> i) =>
            t is NamedType ? t.description : null,
      ),
      Field<GraphQLType, Object?>(
        'specifiedByURL',
        graphqlString,
        resolve: (GraphQLType t, ResolveInfo<Object?> i) =>
            t is ScalarType<Object> ? t.specifiedByUrl : null,
      ),
      Field<GraphQLType, Object?>(
        'fields',
        fieldType.nonNull.list,
        args: <Argument>[_includeDeprecated()],
        resolve: (GraphQLType t, ResolveInfo<Object?> i) {
          List<Field<Object?, Object?>>? fields = switch (t) {
            ObjectType<Object?, Object?>() => t.fields,
            InterfaceType() => t.fields,
            _ => null,
          };
          if (fields == null || _withDeprecated(i)) return fields;
          return <Field<Object?, Object?>>[
            for (Field<Object?, Object?> f in fields)
              if (!f.isDeprecated) f,
          ];
        },
      ),
      Field<GraphQLType, Object?>(
        'interfaces',
        typeType.nonNull.list,
        resolve: (GraphQLType t, ResolveInfo<Object?> i) => switch (t) {
          ObjectType<Object?, Object?>() => t.interfaces,
          InterfaceType() => t.interfaces,
          _ => null,
        },
      ),
      Field<GraphQLType, Object?>(
        'possibleTypes',
        typeType.nonNull.list,
        resolve: (GraphQLType t, ResolveInfo<Object?> i) =>
            t is NamedType && t.isAbstract ? i.schema.possibleTypes(t) : null,
      ),
      Field<GraphQLType, Object?>(
        'enumValues',
        enumValueType.nonNull.list,
        args: <Argument>[_includeDeprecated()],
        resolve: (GraphQLType t, ResolveInfo<Object?> i) {
          if (t is! EnumType<Object?>) return null;
          return <EnumValue<Object?>>[
            for (EnumValue<Object?> v in t.values)
              if (_withDeprecated(i) || !v.isDeprecated) v,
          ];
        },
      ),
      Field<GraphQLType, Object?>(
        'inputFields',
        inputValueType.nonNull.list,
        args: <Argument>[_includeDeprecated()],
        resolve: (GraphQLType t, ResolveInfo<Object?> i) {
          if (t is! InputObjectType) return null;
          return <InputField>[
            for (InputField f in t.fields)
              if (_withDeprecated(i) || !f.isDeprecated) f,
          ];
        },
      ),
      Field<GraphQLType, Object?>(
        'ofType',
        typeType,
        resolve: (GraphQLType t, ResolveInfo<Object?> i) => switch (t) {
          ListType() => t.ofType,
          NonNullType() => t.ofType,
          _ => null,
        },
      ),
      Field<GraphQLType, Object?>(
        'isOneOf',
        graphqlBoolean,
        resolve: (GraphQLType t, ResolveInfo<Object?> i) =>
            t is InputObjectType ? false : null,
      ),
    ];
  }

  static final ObjectType<Field<Object?, Object?>, Object?> fieldType =
      ObjectType<Field<Object?, Object?>, Object?>(
        '__Field',
        description:
            'Object and Interface types are described by a list of Fields, '
            'each of which has a name, potentially a list of arguments, and '
            'a return type.',
        fields: _fieldFields,
      );

  static List<Field<Field<Object?, Object?>, Object?>> _fieldFields() {
    return <Field<Field<Object?, Object?>, Object?>>[
      Field<Field<Object?, Object?>, Object?>(
        'name',
        graphqlString.nonNull,
        resolve: (Field<Object?, Object?> f, ResolveInfo<Object?> i) => f.name,
      ),
      Field<Field<Object?, Object?>, Object?>(
        'description',
        graphqlString,
        resolve: (Field<Object?, Object?> f, ResolveInfo<Object?> i) =>
            f.description,
      ),
      Field<Field<Object?, Object?>, Object?>(
        'args',
        inputValueType.nonNull.list.nonNull,
        args: <Argument>[_includeDeprecated()],
        resolve: (Field<Object?, Object?> f, ResolveInfo<Object?> i) =>
            <Argument>[
              for (Argument a in f.args)
                if (_withDeprecated(i) || !a.isDeprecated) a,
            ],
      ),
      Field<Field<Object?, Object?>, Object?>(
        'type',
        typeType.nonNull,
        resolve: (Field<Object?, Object?> f, ResolveInfo<Object?> i) => f.type,
      ),
      Field<Field<Object?, Object?>, Object?>(
        'isDeprecated',
        graphqlBoolean.nonNull,
        resolve: (Field<Object?, Object?> f, ResolveInfo<Object?> i) =>
            f.isDeprecated,
      ),
      Field<Field<Object?, Object?>, Object?>(
        'deprecationReason',
        graphqlString,
        resolve: (Field<Object?, Object?> f, ResolveInfo<Object?> i) =>
            f.deprecationReason,
      ),
    ];
  }

  static final ObjectType<Argument, Object?> inputValueType =
      ObjectType<Argument, Object?>(
        '__InputValue',
        description:
            'Arguments provided to Fields or Directives and the input fields '
            'of an InputObject are represented as Input Values which '
            'describe their type and optionally a default value.',
        fields: _inputValueFields,
      );

  static List<Field<Argument, Object?>> _inputValueFields() {
    return <Field<Argument, Object?>>[
      Field<Argument, Object?>(
        'name',
        graphqlString.nonNull,
        resolve: (Argument a, ResolveInfo<Object?> i) => a.name,
      ),
      Field<Argument, Object?>(
        'description',
        graphqlString,
        resolve: (Argument a, ResolveInfo<Object?> i) => a.description,
      ),
      Field<Argument, Object?>(
        'type',
        typeType.nonNull,
        resolve: (Argument a, ResolveInfo<Object?> i) => a.type,
      ),
      Field<Argument, Object?>(
        'defaultValue',
        graphqlString,
        description:
            'A GraphQL-formatted string representing the default value for '
            'this input value.',
        resolve: (Argument a, ResolveInfo<Object?> i) => a.defaultValue?.trim(),
      ),
      Field<Argument, Object?>(
        'isDeprecated',
        graphqlBoolean.nonNull,
        resolve: (Argument a, ResolveInfo<Object?> i) => a.isDeprecated,
      ),
      Field<Argument, Object?>(
        'deprecationReason',
        graphqlString,
        resolve: (Argument a, ResolveInfo<Object?> i) => a.deprecationReason,
      ),
    ];
  }

  static final ObjectType<EnumValue<Object?>, Object?> enumValueType =
      ObjectType<EnumValue<Object?>, Object?>(
        '__EnumValue',
        description:
            'One possible value for a given Enum. Enum values are unique '
            'values, not a placeholder for a string or numeric value.',
        fields: _enumValueFields,
      );

  static List<Field<EnumValue<Object?>, Object?>> _enumValueFields() {
    return <Field<EnumValue<Object?>, Object?>>[
      Field<EnumValue<Object?>, Object?>(
        'name',
        graphqlString.nonNull,
        resolve: (EnumValue<Object?> v, ResolveInfo<Object?> i) => v.name,
      ),
      Field<EnumValue<Object?>, Object?>(
        'description',
        graphqlString,
        resolve: (EnumValue<Object?> v, ResolveInfo<Object?> i) =>
            v.description,
      ),
      Field<EnumValue<Object?>, Object?>(
        'isDeprecated',
        graphqlBoolean.nonNull,
        resolve: (EnumValue<Object?> v, ResolveInfo<Object?> i) =>
            v.isDeprecated,
      ),
      Field<EnumValue<Object?>, Object?>(
        'deprecationReason',
        graphqlString,
        resolve: (EnumValue<Object?> v, ResolveInfo<Object?> i) =>
            v.deprecationReason,
      ),
    ];
  }

  static final ObjectType<Directive, Object?> directiveType =
      ObjectType<Directive, Object?>(
        '__Directive',
        description:
            'A Directive provides a way to describe alternate runtime '
            'execution and type validation behavior in a GraphQL document.',
        fields: _directiveFields,
      );

  static List<Field<Directive, Object?>> _directiveFields() {
    return <Field<Directive, Object?>>[
      Field<Directive, Object?>(
        'name',
        graphqlString.nonNull,
        resolve: (Directive d, ResolveInfo<Object?> i) => d.name,
      ),
      Field<Directive, Object?>(
        'description',
        graphqlString,
        resolve: (Directive d, ResolveInfo<Object?> i) => d.description,
      ),
      Field<Directive, Object?>(
        'isRepeatable',
        graphqlBoolean.nonNull,
        resolve: (Directive d, ResolveInfo<Object?> i) => d.isRepeatable,
      ),
      Field<Directive, Object?>(
        'locations',
        directiveLocation.nonNull.list.nonNull,
        resolve: (Directive d, ResolveInfo<Object?> i) => d.locations,
      ),
      Field<Directive, Object?>(
        'args',
        inputValueType.nonNull.list.nonNull,
        args: <Argument>[_includeDeprecated()],
        resolve: (Directive d, ResolveInfo<Object?> i) => <Argument>[
          for (Argument a in d.args)
            if (_withDeprecated(i) || !a.isDeprecated) a,
        ],
      ),
    ];
  }

  /// The spec name of a directive location, like `FIELD_DEFINITION`.
  static String locationName(DirectiveLocation l) {
    if (l == DirectiveLocation.enumDefinition) return 'ENUM';
    return l.name
        .replaceAllMapped(RegExp('[A-Z]'), (Match m) => '_${m[0]}')
        .toUpperCase();
  }

  static final EnumType<DirectiveLocation> directiveLocation =
      EnumType<DirectiveLocation>(
        '__DirectiveLocation',
        <EnumValue<DirectiveLocation>>[
          for (DirectiveLocation l in DirectiveLocation.values)
            EnumValue<DirectiveLocation>(locationName(l), l),
        ],
        description:
            'A Directive can be adjacent to many parts of the GraphQL '
            'language, a __DirectiveLocation describes one such possible '
            'adjacencies.',
      );

  /// All introspection types.
  static final List<NamedType> types = <NamedType>[
    schemaType,
    typeType,
    typeKind,
    fieldType,
    inputValueType,
    enumValueType,
    directiveType,
    directiveLocation,
  ];

  static final Field<Object?, Object?> typenameField = Field<Object?, Object?>(
    '__typename',
    graphqlString.nonNull,
    description: 'The name of the current Object type at runtime.',
    resolve: (Object? s, ResolveInfo<Object?> i) => i.parentType.name,
  );

  static final Field<Object?, Object?> schemaField = Field<Object?, Object?>(
    '__schema',
    schemaType.nonNull,
    description: 'Access the current type schema of this server.',
    resolve: (Object? s, ResolveInfo<Object?> i) => i.schema,
  );

  static final Field<Object?, Object?> typeField = Field<Object?, Object?>(
    '__type',
    typeType,
    description: 'Request the type information of a single type.',
    args: <Argument>[Argument('name', graphqlString.nonNull)],
    resolve: (Object? s, ResolveInfo<Object?> i) =>
        i.schema.type(i.args.get<String>('name')!),
  );

  static final Directive skip = Directive(
    'skip',
    description:
        'Directs the executor to skip this field or fragment when the `if` '
        'argument is true.',
    locations: <DirectiveLocation>[
      DirectiveLocation.field,
      DirectiveLocation.fragmentSpread,
      DirectiveLocation.inlineFragment,
    ],
    args: <Argument>[
      Argument('if', graphqlBoolean.nonNull, description: 'Skipped when true.'),
    ],
  );

  static final Directive include = Directive(
    'include',
    description:
        'Directs the executor to include this field or fragment only when '
        'the `if` argument is true.',
    locations: <DirectiveLocation>[
      DirectiveLocation.field,
      DirectiveLocation.fragmentSpread,
      DirectiveLocation.inlineFragment,
    ],
    args: <Argument>[
      Argument(
        'if',
        graphqlBoolean.nonNull,
        description: 'Included when true.',
      ),
    ],
  );

  static final Directive deprecated = Directive(
    'deprecated',
    description: 'Marks an element of a GraphQL schema as no longer supported.',
    locations: <DirectiveLocation>[
      DirectiveLocation.fieldDefinition,
      DirectiveLocation.argumentDefinition,
      DirectiveLocation.inputFieldDefinition,
      DirectiveLocation.enumValue,
    ],
    args: <Argument>[
      Argument(
        'reason',
        graphqlString,
        description: 'Explains why this element was deprecated.',
        defaultValue: '"No longer supported"',
      ),
    ],
  );

  static final Directive specifiedBy = Directive(
    'specifiedBy',
    description: 'Exposes a URL that specifies the behavior of this scalar.',
    locations: <DirectiveLocation>[DirectiveLocation.scalar],
    args: <Argument>[
      Argument(
        'url',
        graphqlString.nonNull,
        description: 'The URL that specifies the behavior of this scalar.',
      ),
    ],
  );

  static final List<Directive> directives = <Directive>[
    include,
    skip,
    deprecated,
    specifiedBy,
  ];
}
