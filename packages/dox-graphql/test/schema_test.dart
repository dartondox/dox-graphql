import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

ObjectType<Object?, Object?> _object(
  String name,
  List<Field<Object?, Object?>> fields, {
  List<InterfaceType> interfaces = const <InterfaceType>[],
}) => ObjectType<Object?, Object?>(
  name,
  fields: () => fields,
  interfaces: interfaces,
);

Field<Object?, Object?> _f(
  String name,
  GraphQLTypeRef type, {
  List<Argument> args = const <Argument>[],
}) => Field<Object?, Object?>(name, type, args: args);

List<String> problemsOf(
  ObjectType<Object?, Object?> query, {
  List<NamedType> types = const <NamedType>[],
}) {
  try {
    GraphQLSchema<Object?>(query: query, types: types);
    return <String>[];
  } on SchemaError catch (e) {
    return e.problems;
  }
}

void main() {
  test('a good schema builds', () {
    expect(
      problemsOf(
        _object('Query', <Field<Object?, Object?>>[_f('a', graphqlInt)]),
      ),
      isEmpty,
    );
  });

  test('bad names', () {
    expect(
      problemsOf(
        _object('Query', <Field<Object?, Object?>>[
          _f('bad-name', graphqlInt),
          _f('__reserved', graphqlInt),
        ]),
      ),
      <String>[
        'Field name "bad-name" must match /^[_a-zA-Z][_a-zA-Z0-9]*\$/.',
        'Field name "__reserved" must not begin with "__", which is reserved '
            'by GraphQL introspection.',
      ],
    );
  });

  test('two types with one name', () {
    expect(
      problemsOf(
        _object('Query', <Field<Object?, Object?>>[
          _f(
            'a',
            _object('Same', <Field<Object?, Object?>>[_f('x', graphqlInt)]),
          ),
          _f(
            'b',
            _object('Same', <Field<Object?, Object?>>[_f('y', graphqlInt)]),
          ),
        ]),
      ),
      <String>[
        'Schema must contain uniquely named types but contains multiple '
            'types named "Same".',
      ],
    );
  });

  test('fields: empty, duplicate, input type as output', () {
    InputObjectType input = InputObjectType(
      'In',
      fields: () => <InputField>[InputField('x', graphqlInt)],
    );
    expect(
      problemsOf(
        _object('Query', <Field<Object?, Object?>>[
          _f('a', _object('Empty', <Field<Object?, Object?>>[])),
          _f('b', graphqlInt),
          _f('b', graphqlInt),
          _f('c', input),
        ]),
      ),
      <String>[
        'Field Query.b can only be defined once.',
        'The type of Query.c must be Output Type but got: In.',
        'Type Empty must define one or more fields.',
      ],
    );
  });

  test('arguments: output type, bad default, required and deprecated', () {
    ObjectType<Object?, Object?> out = _object('Out', <Field<Object?, Object?>>[
      _f('x', graphqlInt),
    ]);
    expect(
      problemsOf(
        _object('Query', <Field<Object?, Object?>>[
          _f(
            'a',
            graphqlInt,
            args: <Argument>[
              Argument('o', out),
              Argument('d', graphqlInt, defaultValue: '"text"'),
              Argument('p', graphqlInt, defaultValue: 'not ( a literal'),
              Argument('r', graphqlInt.nonNull, deprecationReason: 'old'),
            ],
          ),
        ]),
      ),
      <String>[
        'The type of Query.a(o:) must be Input Type but got: Out.',
        'Default value of Query.a(d:) is not valid for type "Int": "text"',
        'Default value of Query.a(p:) is not a GraphQL literal: not ( a literal',
        'Required argument Query.a(r:) cannot be deprecated.',
      ],
    );
  });

  test('interfaces must be implemented in full', () {
    InterfaceType node = InterfaceType(
      'Node',
      fields: () => <Field<Object?, Object?>>[
        _f('id', graphqlId.nonNull),
        _f(
          'size',
          graphqlInt,
          args: <Argument>[Argument('unit', graphqlString)],
        ),
        _f('other', graphqlInt),
      ],
    );
    InterfaceType named = InterfaceType(
      'Named',
      interfaces: <InterfaceType>[node],
      fields: () => <Field<Object?, Object?>>[
        _f('id', graphqlId.nonNull),
        _f(
          'size',
          graphqlInt,
          args: <Argument>[Argument('unit', graphqlString)],
        ),
        _f('other', graphqlInt),
      ],
    );
    ObjectType<Object?, Object?> thing = _object(
      'Thing',
      <Field<Object?, Object?>>[
        _f('id', graphqlId),
        _f(
          'size',
          graphqlInt,
          args: <Argument>[
            Argument('unit', graphqlInt),
            Argument('extra', graphqlInt.nonNull),
          ],
        ),
      ],
      interfaces: <InterfaceType>[named],
    );
    expect(
      problemsOf(_object('Query', <Field<Object?, Object?>>[_f('t', thing)])),
      <String>[
        'Type Thing must implement Node because it is implemented by Named.',
        'Interface field Named.id expects type ID! but Thing.id is type ID.',
        'Interface field argument Named.size(unit:) expects type String but '
            'Thing.size(unit:) is type Int.',
        'Object field Thing.size includes required argument extra that is '
            'missing from the Interface field Named.size.',
        'Interface field Named.other expected but Thing does not provide it.',
      ],
    );
  });

  test('a covariant field type is allowed', () {
    late InterfaceType node;
    node = InterfaceType(
      'Node',
      fields: () => <Field<Object?, Object?>>[_f('self', node)],
    );
    late ObjectType<Object?, Object?> thing;
    thing = ObjectType<Object?, Object?>(
      'Thing',
      interfaces: <InterfaceType>[node],
      fields: () => <Field<Object?, Object?>>[_f('self', thing.nonNull)],
    );
    expect(
      problemsOf(_object('Query', <Field<Object?, Object?>>[_f('t', thing)])),
      isEmpty,
    );
  });

  test('unions and enums', () {
    ObjectType<Object?, Object?> a = _object('A', <Field<Object?, Object?>>[
      _f('x', graphqlInt),
    ]);
    expect(
      problemsOf(
        _object('Query', <Field<Object?, Object?>>[
          _f('u', UnionType('U', <ObjectType<Object?, Object?>>[a, a])),
          _f(
            'e',
            EnumType<int>('E', <EnumValue<int>>[EnumValue<int>('true', 1)]),
          ),
        ]),
      ),
      <String>[
        'Union type U can only include type A once.',
        'Enum type E cannot include value: true.',
      ],
    );
  });

  test('input objects cannot loop through non-null fields', () {
    late InputObjectType a;
    InputObjectType b = InputObjectType(
      'B',
      fields: () => <InputField>[InputField('a', a.nonNull)],
    );
    a = InputObjectType(
      'A',
      fields: () => <InputField>[InputField('b', b.nonNull)],
    );
    // A nullable or list link breaks the loop.
    late InputObjectType ok;
    ok = InputObjectType(
      'Ok',
      fields: () => <InputField>[
        InputField('self', ok),
        InputField('list', ok.nonNull.list.nonNull),
      ],
    );
    expect(
      problemsOf(
        _object('Query', <Field<Object?, Object?>>[
          _f(
            'x',
            graphqlInt,
            args: <Argument>[Argument('a', a), Argument('ok', ok)],
          ),
        ]),
      ),
      <String>[
        'Cannot reference Input Object "A" within itself through a series of '
            'non-null fields: "b.a".',
      ],
    );
  });

  test('extra types are in the schema', () {
    ObjectType<Object?, Object?> hidden = _object(
      'Hidden',
      <Field<Object?, Object?>>[_f('x', graphqlInt)],
    );
    GraphQLSchema<Object?> s = GraphQLSchema<Object?>(
      query: _object('Query', <Field<Object?, Object?>>[_f('a', graphqlInt)]),
      types: <NamedType>[hidden],
    );
    expect(s.type('Hidden'), same(hidden));
  });
}
