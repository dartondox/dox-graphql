import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

import 'star_wars.dart';

/// The query GraphiQL sends, with every option on.
const String introspectionQuery = '''
query IntrospectionQuery {
  __schema {
    description
    queryType { name kind }
    mutationType { name kind }
    subscriptionType { name kind }
    types { ...FullType }
    directives {
      name
      description
      isRepeatable
      locations
      args(includeDeprecated: true) { ...InputValue }
    }
  }
}

fragment FullType on __Type {
  kind
  name
  description
  specifiedByURL
  isOneOf
  fields(includeDeprecated: true) {
    name
    description
    args(includeDeprecated: true) { ...InputValue }
    type { ...TypeRef }
    isDeprecated
    deprecationReason
  }
  inputFields(includeDeprecated: true) { ...InputValue }
  interfaces { ...TypeRef }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes { ...TypeRef }
}

fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
  isDeprecated
  deprecationReason
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType { kind name ofType { kind name ofType { kind name ofType { kind name } } } }
      }
    }
  }
}
''';

Map<String, Object?> _map(Object? v) => v as Map<String, Object?>;

void main() {
  test('the full introspection query works', () async {
    Map<String, Object?> r = await runStarWars(introspectionQuery);
    expect(r.containsKey('errors'), isFalse, reason: '${r['errors']}');
    Map<String, Object?> s = _map(_map(r['data'])['__schema']);
    expect(s['queryType'], <String, Object?>{
      'name': 'Query',
      'kind': 'OBJECT',
    });
    expect(s['mutationType'], isNull);
    expect(s['subscriptionType'], isNull);

    List<Map<String, Object?>> types = <Map<String, Object?>>[
      for (Object? t in s['types'] as List<Object?>) _map(t),
    ];
    expect(
      <Object?>[for (Map<String, Object?> t in types) t['name']]..sort(),
      <String>[
        'Boolean',
        'Character',
        'Droid',
        'Episode',
        'Human',
        'Query',
        'String',
        '__Directive',
        '__DirectiveLocation',
        '__EnumValue',
        '__Field',
        '__InputValue',
        '__Schema',
        '__Type',
        '__TypeKind',
      ],
    );

    Map<String, Object?> character = types.firstWhere(
      (Map<String, Object?> t) => t['name'] == 'Character',
    );
    expect(character['kind'], 'INTERFACE');
    expect(character['possibleTypes'], <Object?>[
      <String, Object?>{'kind': 'OBJECT', 'name': 'Human', 'ofType': null},
      <String, Object?>{'kind': 'OBJECT', 'name': 'Droid', 'ofType': null},
    ]);
    Map<String, Object?> id = _map(
      (character['fields'] as List<Object?>).first,
    );
    expect(id['type'], <String, Object?>{
      'kind': 'NON_NULL',
      'name': null,
      'ofType': <String, Object?>{
        'kind': 'SCALAR',
        'name': 'String',
        'ofType': null,
      },
    });

    Map<String, Object?> episode = types.firstWhere(
      (Map<String, Object?> t) => t['name'] == 'Episode',
    );
    expect(episode['enumValues'], hasLength(3));
    expect(episode['fields'], isNull);

    List<Object?> directives = s['directives'] as List<Object?>;
    Map<String, Object?> deprecated = _map(
      directives.firstWhere((Object? d) => _map(d)['name'] == 'deprecated'),
    );
    expect(deprecated['locations'], <String>[
      'FIELD_DEFINITION',
      'ARGUMENT_DEFINITION',
      'INPUT_FIELD_DEFINITION',
      'ENUM_VALUE',
    ]);
    expect(
      _map((deprecated['args'] as List<Object?>).single)['defaultValue'],
      '"No longer supported"',
    );
  });

  test('__type', () async {
    expect(
      await runStarWars('''
        { __type(name: "Droid") { name kind interfaces { name } fields { name } } }
      '''),
      <String, Object?>{
        'data': <String, Object?>{
          '__type': <String, Object?>{
            'name': 'Droid',
            'kind': 'OBJECT',
            'interfaces': <Object?>[
              <String, Object?>{'name': 'Character'},
            ],
            'fields': <Object?>[
              for (String n in <String>[
                'id',
                'name',
                'friends',
                'appearsIn',
                'secretBackstory',
                'primaryFunction',
              ])
                <String, Object?>{'name': n},
            ],
          },
        },
      },
    );
    expect(
      await runStarWars('{ __type(name: "Nope") { name } }'),
      <String, Object?>{
        'data': <String, Object?>{'__type': null},
      },
    );
  });

  test('deprecated fields and values are hidden by default', () async {
    GraphQLSchema<Object?> s = GraphQLSchema<Object?>(
      query: ObjectType<Object?, Object?>(
        'Query',
        fields: () => <Field<Object?, Object?>>[
          Field<Object?, Object?>('a', graphqlInt),
          Field<Object?, Object?>(
            'old',
            graphqlInt,
            deprecationReason: 'Use a.',
            args: <Argument>[
              Argument('x', graphqlInt, deprecationReason: 'No x.'),
            ],
          ),
          Field<Object?, Object?>(
            'e',
            EnumType<int>('E', <EnumValue<int>>[
              EnumValue<int>('ONE', 1),
              EnumValue<int>('TWO', 2, deprecationReason: 'Gone.'),
            ]),
          ),
        ],
      ),
    );
    GraphQLResponse r = await GraphQLExecutor<Object?>(s).execute(
      const GraphQLRequest('''
        {
          __type(name: "Query") {
            fields { name }
            all: fields(includeDeprecated: true) {
              name isDeprecated deprecationReason
              args { name } allArgs: args(includeDeprecated: true) { name isDeprecated }
            }
          }
          e: __type(name: "E") { enumValues { name } all: enumValues(includeDeprecated: true) { name } }
        }
      '''),
      context: null,
    );
    Map<String, Object?> data = r.data!;
    Map<String, Object?> q = _map(data['__type']);
    expect(q['fields'], <Object?>[
      <String, Object?>{'name': 'a'},
      <String, Object?>{'name': 'e'},
    ]);
    expect((q['all'] as List<Object?>)[1], <String, Object?>{
      'name': 'old',
      'isDeprecated': true,
      'deprecationReason': 'Use a.',
      'args': <Object?>[],
      'allArgs': <Object?>[
        <String, Object?>{'name': 'x', 'isDeprecated': true},
      ],
    });
    expect(_map(data['e'])['enumValues'], <Object?>[
      <String, Object?>{'name': 'ONE'},
    ]);
    expect(_map(data['e'])['all'], hasLength(2));
  });

  test('introspection off', () async {
    GraphQLExecutor<StarWarsContext> off = GraphQLExecutor<StarWarsContext>(
      starWarsSchema,
      introspection: false,
    );
    GraphQLResponse r = await off.execute(
      const GraphQLRequest('{ __type(name: "Droid") { name } }'),
      context: StarWarsContext(),
    );
    expect(r.hasData, isFalse);
    expect(
      r.errors.single.message,
      'GraphQL introspection has been disabled, but the requested query '
      'contained the field "__type".',
    );
    r = await off.execute(
      const GraphQLRequest('{ hero { __typename } }'),
      context: StarWarsContext(),
    );
    expect(r.data, <String, Object?>{
      'hero': <String, Object?>{'__typename': 'Droid'},
    });
  });
}
