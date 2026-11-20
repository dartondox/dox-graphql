import 'dart:async';

import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

class Ctx {
  final List<String> log = <String>[];
  String user = 'ann';
}

/// A custom scalar: a date as `YYYY-MM-DD`.
class DateScalar extends ScalarType<DateTime> {
  DateScalar() : super('Date', specifiedByUrl: 'https://example.com/date');

  @override
  Object serialize(Object value) {
    if (value is DateTime) return value.toIso8601String().substring(0, 10);
    throw GraphQLError('Date cannot represent value: $value');
  }

  @override
  DateTime parseValue(Object value) {
    DateTime? d = value is String ? DateTime.tryParse(value) : null;
    if (d == null) throw GraphQLError('Date cannot represent value: $value');
    return d;
  }

  @override
  DateTime parseLiteral(ValueNode node) {
    if (node is StringValueNode) return parseValue(node.value);
    throw GraphQLError('Date must be a string');
  }
}

final DateScalar dateScalar = DateScalar();

enum Color { red, green }

final EnumType<Color> colorEnum = EnumType<Color>('Color', <EnumValue<Color>>[
  EnumValue<Color>('RED', Color.red),
  EnumValue<Color>('GREEN', Color.green, deprecationReason: 'Use RED.'),
]);

final InputObjectType filterInput = InputObjectType(
  'Filter',
  fields: () => <InputField>[
    InputField('text', graphqlString.nonNull),
    InputField('limit', graphqlInt, defaultValue: '10'),
    InputField('tags', graphqlString.list),
    InputField('inner', filterInput),
  ],
);

class Cat {
  Cat(this.name);
  final String name;
}

class Dog {
  Dog(this.name);
  final String name;
}

final ObjectType<Cat, Ctx> catType = ObjectType<Cat, Ctx>(
  'Cat',
  fields: () => <Field<Cat, Ctx>>[
    Field<Cat, Ctx>(
      'name',
      graphqlString,
      resolve: (Cat c, ResolveInfo<Ctx> i) => c.name,
    ),
    Field<Cat, Ctx>(
      'meows',
      graphqlBoolean,
      resolve: (Cat c, ResolveInfo<Ctx> i) => true,
    ),
  ],
);

final ObjectType<Dog, Ctx> dogType = ObjectType<Dog, Ctx>(
  'Dog',
  fields: () => <Field<Dog, Ctx>>[
    Field<Dog, Ctx>(
      'name',
      graphqlString,
      resolve: (Dog d, ResolveInfo<Ctx> i) => d.name,
    ),
    Field<Dog, Ctx>(
      'barks',
      graphqlBoolean,
      resolve: (Dog d, ResolveInfo<Ctx> i) => true,
    ),
  ],
);

final UnionType petUnion = UnionType('Pet', <ObjectType<Object?, Object?>>[
  catType,
  dogType,
]);

/// For the null bubbling tests: every field can fail or give null.
final ObjectType<int, Ctx> nodeType = ObjectType<int, Ctx>(
  'Node',
  fields: () => <Field<int, Ctx>>[
    Field<int, Ctx>(
      'value',
      graphqlInt,
      resolve: (int n, ResolveInfo<Ctx> i) => n,
    ),
    Field<int, Ctx>(
      'nonNullFail',
      graphqlInt.nonNull,
      resolve: (int n, ResolveInfo<Ctx> i) => throw StateError('boom $n'),
    ),
    Field<int, Ctx>(
      'nonNullNull',
      graphqlInt.nonNull,
      resolve: (int n, ResolveInfo<Ctx> i) => null,
    ),
    Field<int, Ctx>(
      'child',
      nodeType,
      resolve: (int n, ResolveInfo<Ctx> i) => n + 1,
    ),
    Field<int, Ctx>(
      'nonNullChild',
      nodeType.nonNull,
      resolve: (int n, ResolveInfo<Ctx> i) => n + 1,
    ),
    Field<int, Ctx>(
      'items',
      graphqlInt.nonNull.list,
      resolve: (int n, ResolveInfo<Ctx> i) => <int?>[1, null, 3],
    ),
    Field<int, Ctx>(
      'nullableItems',
      graphqlInt.list,
      resolve: (int n, ResolveInfo<Ctx> i) => <Object?>[1, null, 'x'],
    ),
    Field<int, Ctx>(
      'notAList',
      graphqlInt.list,
      resolve: (int n, ResolveInfo<Ctx> i) => 5,
    ),
  ],
);

final ObjectType<Object?, Ctx> query = ObjectType<Object?, Ctx>(
  'Query',
  fields: () => <Field<Object?, Ctx>>[
    Field<Object?, Ctx>(
      'echo',
      graphqlString,
      args: <Argument>[Argument('text', graphqlString, defaultValue: '"hi"')],
      resolve: (Object? _, ResolveInfo<Ctx> i) =>
          i.args.has('text') ? i.args.get<String>('text') : 'absent',
    ),
    Field<Object?, Ctx>(
      'user',
      graphqlString,
      resolve: (Object? _, ResolveInfo<Ctx> i) => i.context.user,
    ),
    Field<Object?, Ctx>(
      'slow',
      graphqlString,
      resolve: (Object? _, ResolveInfo<Ctx> i) async {
        i.context.log.add('slow start');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        i.context.log.add('slow end');
        return 'slow';
      },
    ),
    Field<Object?, Ctx>(
      'fast',
      graphqlString,
      resolve: (Object? _, ResolveInfo<Ctx> i) {
        i.context.log.add('fast');
        return 'fast';
      },
    ),
    Field<Object?, Ctx>(
      'filter',
      graphqlString,
      args: <Argument>[Argument('f', filterInput)],
      resolve: (Object? _, ResolveInfo<Ctx> i) =>
          i.args.input('f')?.toJson().toString(),
    ),
    Field<Object?, Ctx>(
      'ints',
      graphqlString,
      args: <Argument>[Argument('list', graphqlInt.nonNull.list)],
      resolve: (Object? _, ResolveInfo<Ctx> i) =>
          i.args.list<int>('list')?.join(','),
    ),
    Field<Object?, Ctx>(
      'date',
      dateScalar,
      args: <Argument>[Argument('d', dateScalar)],
      resolve: (Object? _, ResolveInfo<Ctx> i) =>
          i.args.get<DateTime>('d')?.add(const Duration(days: 1)),
    ),
    Field<Object?, Ctx>(
      'color',
      colorEnum,
      args: <Argument>[Argument('c', colorEnum.nonNull)],
      resolve: (Object? _, ResolveInfo<Ctx> i) => i.args.get<Color>('c'),
    ),
    Field<Object?, Ctx>(
      'badColor',
      colorEnum,
      resolve: (Object? _, ResolveInfo<Ctx> i) => 'nope',
    ),
    Field<Object?, Ctx>(
      'pets',
      petUnion.list,
      resolve: (Object? _, ResolveInfo<Ctx> i) => <Object>[
        Cat('Tom'),
        Dog('Rex'),
      ],
    ),
    Field<Object?, Ctx>(
      'mapPet',
      petUnion,
      resolve: (Object? _, ResolveInfo<Ctx> i) => <String, Object?>{
        '__typename': 'Dog',
      },
    ),
    Field<Object?, Ctx>(
      'strangePet',
      petUnion,
      resolve: (Object? _, ResolveInfo<Ctx> i) => 42,
    ),
    Field<Object?, Ctx>(
      'node',
      nodeType,
      resolve: (Object? _, ResolveInfo<Ctx> i) => 0,
    ),
    Field<Object?, Ctx>(
      'nonNullNode',
      nodeType.nonNull,
      resolve: (Object? _, ResolveInfo<Ctx> i) => 0,
    ),
    Field<Object?, Ctx>(
      'path',
      graphqlString,
      resolve: (Object? _, ResolveInfo<Ctx> i) => i.path.join('/'),
    ),
    Field<Object?, Ctx>(
      'fromMap',
      ObjectType<Object?, Ctx>(
        'MapObject',
        fields: () => <Field<Object?, Ctx>>[
          Field<Object?, Ctx>('a', graphqlInt),
        ],
      ),
      resolve: (Object? _, ResolveInfo<Ctx> i) => <String, Object?>{'a': 1},
    ),
  ],
);

final ObjectType<Object?, Ctx> mutation = ObjectType<Object?, Ctx>(
  'Mutation',
  fields: () => <Field<Object?, Ctx>>[
    for (String name in <String>['first', 'second', 'third'])
      Field<Object?, Ctx>(
        name,
        graphqlString,
        args: <Argument>[Argument('wait', graphqlInt, defaultValue: '0')],
        resolve: (Object? _, ResolveInfo<Ctx> i) async {
          i.context.log.add('$name start');
          await Future<void>.delayed(
            Duration(milliseconds: i.args.get<int>('wait')!),
          );
          i.context.log.add('$name end');
          return name;
        },
      ),
  ],
);

final Schema<Ctx> schema = Schema<Ctx>(query: query, mutation: mutation);
final GraphQLExecutor<Ctx> executor = GraphQLExecutor<Ctx>(schema);

Future<Map<String, Object?>> run(
  String q, {
  Map<String, Object?> variables = const <String, Object?>{},
  String? operationName,
  Ctx? ctx,
}) async {
  GraphQLResponse r = await executor.execute(
    GraphQLRequest(q, variables: variables, operationName: operationName),
    context: ctx ?? Ctx(),
  );
  return r.toJson();
}

List<String> messages(Map<String, Object?> r) => <String>[
  for (Object? e in r['errors'] as List<Object?>)
    (e as Map<String, Object?>)['message'] as String,
];

void main() {
  group('arguments', () {
    test('default, absent and null are different', () async {
      expect(
        await run('{ a: echo b: echo(text: null) c: echo(text: "x") }'),
        <String, Object?>{
          'data': <String, Object?>{'a': 'hi', 'b': null, 'c': 'x'},
        },
      );
    });

    test('a missing variable gives the default', () async {
      expect(
        await run(r'query ($t: String) { echo(text: $t) }'),
        <String, Object?>{
          'data': <String, Object?>{'echo': 'hi'},
        },
      );
    });

    test('input object with defaults and nested values', () async {
      Map<String, Object?> r = await run(
        r'query ($tags: [String]) { filter(f: {text: "a", tags: $tags, inner: {text: "b", limit: 2}}) }',
        variables: <String, Object?>{'tags': 'one'},
      );
      expect(
        (r['data'] as Map<String, Object?>)['filter'],
        '{text: a, limit: 10, tags: [one], inner: {text: b, limit: 2}}',
      );
    });

    test('a single value is coerced to a list', () async {
      expect(await run('{ ints(list: 3) }'), <String, Object?>{
        'data': <String, Object?>{'ints': '3'},
      });
      expect(
        await run(
          r'query ($l: [Int!]) { ints(list: $l) }',
          variables: <String, Object?>{
            'l': <Object?>[1, 2.0],
          },
        ),
        <String, Object?>{
          'data': <String, Object?>{'ints': '1,2'},
        },
      );
    });

    test('custom scalar in literals, variables and results', () async {
      expect(
        await run(
          r'query ($d: Date) { a: date(d: "2024-01-31") b: date(d: $d) }',
          variables: <String, Object?>{'d': '2024-02-28'},
        ),
        <String, Object?>{
          'data': <String, Object?>{'a': '2024-02-01', 'b': '2024-02-29'},
        },
      );
    });

    test('enum in and out', () async {
      expect(
        await run(
          r'query ($c: Color!) { a: color(c: RED) b: color(c: $c) }',
          variables: <String, Object?>{'c': 'GREEN'},
        ),
        <String, Object?>{
          'data': <String, Object?>{'a': 'RED', 'b': 'GREEN'},
        },
      );
    });

    test('an enum value that cannot be serialized is a field error', () async {
      Map<String, Object?> r = await run('{ badColor }');
      expect(r['data'], <String, Object?>{'badColor': null});
      expect(messages(r), <String>[
        'Enum "Color" cannot represent value: nope',
      ]);
    });
  });

  group('variables', () {
    test('wrong types are request errors', () async {
      Map<String, Object?> r = await run(
        r'query ($c: Color!, $f: Filter, $i: [Int!]) { color(c: $c) filter(f: $f) ints(list: $i) }',
        variables: <String, Object?>{
          'c': 'BLUE',
          'f': <String, Object?>{'limit': 'x'},
          'i': <Object?>[1, null],
        },
      );
      expect(r.containsKey('data'), isFalse);
      expect(messages(r), <String>[
        r'Variable "$c" got invalid value "BLUE"; Value "BLUE" does not exist in "Color" enum.',
        r'Variable "$f" got invalid value {"limit":"x"}; Field "text" of required type "String!" was not provided.',
        r'Variable "$i" got invalid value [1,null] at "i[1]"; Expected non-nullable type "Int!" not to be null.',
      ]);
    });

    test('required variables', () async {
      Map<String, Object?> r = await run(
        r'query ($c: Color!) { color(c: $c) }',
      );
      expect(messages(r), <String>[
        r'Variable "$c" of required type "Color!" was not provided.',
      ]);
      r = await run(
        r'query ($c: Color!) { color(c: $c) }',
        variables: <String, Object?>{'c': null},
      );
      expect(messages(r), <String>[
        r'Variable "$c" of non-null type "Color!" must not be null.',
      ]);
    });

    test('Int range and unknown input fields', () async {
      Map<String, Object?> r = await run(
        r'query ($l: [Int!], $f: Filter) { ints(list: $l) filter(f: $f) }',
        variables: <String, Object?>{
          'l': <Object?>[2147483648],
          'f': <String, Object?>{'text': 'a', 'nope': 1},
        },
      );
      expect(messages(r), <String>[
        r'Variable "$l" got invalid value [2147483648] at "l[0]"; Int cannot represent non 32-bit signed integer value: 2147483648',
        r'Variable "$f" got invalid value {"text":"a","nope":1}; Field "nope" is not defined by type "Filter".',
      ]);
    });

    test('variable default', () async {
      expect(
        await run(r'query ($t: String = "dv") { echo(text: $t) }'),
        <String, Object?>{
          'data': <String, Object?>{'echo': 'dv'},
        },
      );
    });
  });

  group('operations', () {
    test('pick by name', () async {
      expect(
        await run(
          'query A { a: user } query B { b: user }',
          operationName: 'B',
        ),
        <String, Object?>{
          'data': <String, Object?>{'b': 'ann'},
        },
      );
    });

    test('name needed with many operations', () async {
      expect(messages(await run('query A { user } query B { user }')), <String>[
        'Must provide operation name if query contains multiple operations.',
      ]);
      expect(
        messages(await run('query A { user }', operationName: 'C')),
        <String>['Unknown operation named "C".'],
      );
    });

    test('syntax error', () async {
      Map<String, Object?> r = await run('{ user ');
      expect(r.containsKey('data'), isFalse);
      expect(messages(r).single, startsWith('Syntax Error:'));
    });

    test('query fields run side by side', () async {
      Ctx ctx = Ctx();
      await run('{ slow fast }', ctx: ctx);
      expect(ctx.log, <String>['slow start', 'fast', 'slow end']);
    });

    test('mutation fields run one after another', () async {
      Ctx ctx = Ctx();
      Map<String, Object?> r = await run(
        'mutation { first(wait: 30) second third(wait: 5) }',
        ctx: ctx,
      );
      expect(r['data'], <String, Object?>{
        'first': 'first',
        'second': 'second',
        'third': 'third',
      });
      expect(ctx.log, <String>[
        'first start',
        'first end',
        'second start',
        'second end',
        'third start',
        'third end',
      ]);
    });

    test('the typed context reaches resolvers', () async {
      expect(await run('{ user }', ctx: Ctx()..user = 'bob'), <String, Object?>{
        'data': <String, Object?>{'user': 'bob'},
      });
    });

    test('a map parent without resolver uses the key', () async {
      expect(await run('{ fromMap { a } }'), <String, Object?>{
        'data': <String, Object?>{
          'fromMap': <String, Object?>{'a': 1},
        },
      });
    });

    test('path in resolve info', () async {
      expect(await run('{ p: path }'), <String, Object?>{
        'data': <String, Object?>{'p': 'p'},
      });
    });
  });

  group('directives and fragments', () {
    test('@skip and @include with literals and variables', () async {
      expect(
        await run(
          r'''
          query ($yes: Boolean!) {
            a: user @skip(if: true)
            b: user @include(if: false)
            c: user @include(if: $yes)
            d: user @skip(if: $yes)
            ... on Query @skip(if: true) { e: user }
            ...F @include(if: $yes)
          }
          fragment F on Query { f: user }
          ''',
          variables: <String, Object?>{'yes': true},
        ),
        <String, Object?>{
          'data': <String, Object?>{'c': 'ann', 'f': 'ann'},
        },
      );
    });

    test('a null variable in @skip is an error, not a throw', () async {
      Map<String, Object?> r = await run(
        r'query ($b: Boolean = true) { user @skip(if: $b) }',
        variables: <String, Object?>{'b': null},
      );
      expect(r.containsKey('data'), isFalse);
      expect(messages(r), <String>[
        'Argument "if" of non-null type "Boolean!" must not be null.',
      ]);
    });

    test('fields of the same name are merged', () async {
      expect(
        await run('''
          { node { child { value } } node { child { child { value } } } }
        '''),
        <String, Object?>{
          'data': <String, Object?>{
            'node': <String, Object?>{
              'child': <String, Object?>{
                'value': 1,
                'child': <String, Object?>{'value': 2},
              },
            },
          },
        },
      );
    });
  });

  group('abstract types', () {
    test('isTypeOf from the Dart type, and __typename', () async {
      expect(
        await run('''
          { pets { __typename ... on Cat { name meows } ... on Dog { name barks } } }
        '''),
        <String, Object?>{
          'data': <String, Object?>{
            'pets': <Object?>[
              <String, Object?>{
                '__typename': 'Cat',
                'name': 'Tom',
                'meows': true,
              },
              <String, Object?>{
                '__typename': 'Dog',
                'name': 'Rex',
                'barks': true,
              },
            ],
          },
        },
      );
    });

    test('a map with __typename', () async {
      expect(await run('{ mapPet { __typename } }'), <String, Object?>{
        'data': <String, Object?>{
          'mapPet': <String, Object?>{'__typename': 'Dog'},
        },
      });
    });

    test('two Map types without a resolver cannot be told apart', () async {
      ObjectType<Map<String, Object?>, Ctx> mapDog =
          ObjectType<Map<String, Object?>, Ctx>(
            'MapDog',
            fields: () => <Field<Map<String, Object?>, Ctx>>[
              Field<Map<String, Object?>, Ctx>('name', graphqlString),
            ],
          );
      ObjectType<Map<String, Object?>, Ctx> mapCat =
          ObjectType<Map<String, Object?>, Ctx>(
            'MapCat',
            fields: () => <Field<Map<String, Object?>, Ctx>>[
              Field<Map<String, Object?>, Ctx>('name', graphqlString),
            ],
          );
      UnionType mapPet = UnionType('MapPet', <ObjectType<Object?, Object?>>[
        mapDog,
        mapCat,
      ]);
      Schema<Ctx> s = Schema<Ctx>(
        query: ObjectType<Object?, Ctx>(
          'Query',
          fields: () => <Field<Object?, Ctx>>[
            Field<Object?, Ctx>(
              'pet',
              mapPet,
              resolve: (Object? _, ResolveInfo<Ctx> i) => <String, Object?>{
                'name': 'Tom',
              },
            ),
          ],
        ),
      );
      GraphQLResponse r = await GraphQLExecutor<Ctx>(
        s,
      ).execute(const GraphQLRequest('{ pet { __typename } }'), context: Ctx());
      expect(r.data, <String, Object?>{'pet': null});
      expect(
        r.errors.single.message,
        startsWith('Abstract type "MapPet" must resolve to an Object type'),
      );
    });

    test('a value of no possible type is an error', () async {
      Map<String, Object?> r = await run('{ strangePet { __typename } }');
      expect(r['data'], <String, Object?>{'strangePet': null});
      expect(
        messages(r).single,
        startsWith('Abstract type "Pet" must resolve'),
      );
    });
  });

  group('null bubbling', () {
    test(
      'an error in a non-null field nulls the nearest nullable parent',
      () async {
        Map<String, Object?> r = await run('''
        { node { value child { value nonNullFail } } }
      ''');
        expect(r['data'], <String, Object?>{
          'node': <String, Object?>{'value': 0, 'child': null},
        });
        List<Object?> errors = r['errors'] as List<Object?>;
        expect(errors.single, <String, Object?>{
          'message': 'Internal server error',
          'locations': <Object?>[
            <String, int>{'line': 1, 'column': 38},
          ],
          'path': <Object>['node', 'child', 'nonNullFail'],
        });
      },
    );

    test('null in a non-null field', () async {
      Map<String, Object?> r = await run('{ node { child { nonNullNull } } }');
      expect(r['data'], <String, Object?>{
        'node': <String, Object?>{'child': null},
      });
      expect(messages(r), <String>[
        'Cannot return null for non-nullable field Node.nonNullNull.',
      ]);
    });

    test('bubbles through many non-null levels to the root', () async {
      Map<String, Object?> r = await run(
        '{ nonNullNode { nonNullChild { nonNullChild { nonNullFail } } } }',
      );
      expect(r['data'], isNull);
      expect(r.containsKey('data'), isTrue);
      expect((r['errors'] as List<Object?>).length, 1);
      expect(
        ((r['errors'] as List<Object?>).single as Map<String, Object?>)['path'],
        <Object>['nonNullNode', 'nonNullChild', 'nonNullChild', 'nonNullFail'],
      );
    });

    test('a sibling keeps its value', () async {
      Map<String, Object?> r = await run(
        '{ user node { nonNullChild { nonNullNull } } }',
      );
      expect(r['data'], <String, Object?>{'user': 'ann', 'node': null});
    });

    test('list items', () async {
      Map<String, Object?> r = await run(
        '{ node { items nullableItems notAList } }',
      );
      expect(r['data'], <String, Object?>{
        'node': <String, Object?>{
          'items': null,
          'nullableItems': <Object?>[1, null, null],
          'notAList': null,
        },
      });
      List<Object?> errors = r['errors'] as List<Object?>;
      expect(
        <Object?>[
          for (Object? e in errors) (e as Map<String, Object?>)['path'],
        ],
        <Object?>[
          <Object>['node', 'items', 1],
          <Object>['node', 'nullableItems', 2],
          <Object>['node', 'notAList'],
        ],
      );
      expect(messages(r)[1], 'Int cannot represent non-integer value: x');
    });

    test('original error is kept', () async {
      GraphQLResponse r = await executor.execute(
        const GraphQLRequest('{ node { child { nonNullFail } } }'),
        context: Ctx(),
      );
      expect(r.errors.single.originalError, isA<StateError>());
      expect(r.errors.single.stackTrace, isNotNull);
    });
  });

  group('request JSON', () {
    test('fromJson', () {
      GraphQLRequest r = GraphQLRequest.fromJson(<String, Object?>{
        'query': '{ user }',
        'operationName': null,
        'variables': <String, Object?>{'a': 1},
      });
      expect(r.query, '{ user }');
      expect(r.variables, <String, Object?>{'a': 1});
      expect(
        () => GraphQLRequest.fromJson(<String, Object?>{'query': 1}),
        throwsA(isA<GraphQLError>()),
      );
    });
  });
}
