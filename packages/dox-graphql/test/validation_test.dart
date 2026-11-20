import 'package:dox_graphql/dox_graphql.dart';
import 'package:gql/language.dart';
import 'package:test/test.dart';

// The test schema of the spec validation examples.
final InterfaceType pet = InterfaceType(
  'Pet',
  fields: () => <Field<Object?, Object?>>[
    Field<Object?, Object?>('name', graphqlString),
  ],
);

final EnumType<String> dogCommand = EnumType<String>(
  'DogCommand',
  <EnumValue<String>>[
    EnumValue<String>('SIT', 'SIT'),
    EnumValue<String>('HEEL', 'HEEL'),
    EnumValue<String>('DOWN', 'DOWN'),
  ],
);

final ObjectType<Object?, Object?> dog = ObjectType<Object?, Object?>(
  'Dog',
  interfaces: <InterfaceType>[pet],
  fields: () => <Field<Object?, Object?>>[
    Field<Object?, Object?>('name', graphqlString),
    Field<Object?, Object?>('nickname', graphqlString),
    Field<Object?, Object?>('barkVolume', graphqlInt),
    Field<Object?, Object?>('barks', graphqlBoolean),
    Field<Object?, Object?>(
      'doesKnowCommand',
      graphqlBoolean,
      args: <Argument>[Argument('dogCommand', dogCommand.nonNull)],
    ),
    Field<Object?, Object?>(
      'isHouseTrained',
      graphqlBoolean,
      args: <Argument>[
        Argument('atOtherHomes', graphqlBoolean, defaultValue: 'true'),
      ],
    ),
    Field<Object?, Object?>('owner', human),
  ],
);

final ObjectType<Object?, Object?> cat = ObjectType<Object?, Object?>(
  'Cat',
  interfaces: <InterfaceType>[pet],
  fields: () => <Field<Object?, Object?>>[
    Field<Object?, Object?>('name', graphqlString),
    Field<Object?, Object?>('meows', graphqlBoolean),
    Field<Object?, Object?>('meowVolume', graphqlInt),
  ],
);

final ObjectType<Object?, Object?> human = ObjectType<Object?, Object?>(
  'Human',
  fields: () => <Field<Object?, Object?>>[
    Field<Object?, Object?>('name', graphqlString),
    Field<Object?, Object?>('pets', pet.list),
    Field<Object?, Object?>('relatives', human.list),
  ],
);

final UnionType catOrDog = UnionType('CatOrDog', <ObjectType<Object?, Object?>>[
  cat,
  dog,
]);
final UnionType dogOrHuman = UnionType(
  'DogOrHuman',
  <ObjectType<Object?, Object?>>[dog, human],
);

final InputObjectType complexInput = InputObjectType(
  'ComplexInput',
  fields: () => <InputField>[
    InputField('requiredField', graphqlBoolean.nonNull),
    InputField('nonNullField', graphqlBoolean.nonNull, defaultValue: 'false'),
    InputField('intField', graphqlInt),
    InputField('stringField', graphqlString),
  ],
);

final ObjectType<Object?, Object?> complicatedArgs =
    ObjectType<Object?, Object?>(
      'ComplicatedArgs',
      fields: () => <Field<Object?, Object?>>[
        Field<Object?, Object?>(
          'intArgField',
          graphqlString,
          args: <Argument>[Argument('intArg', graphqlInt)],
        ),
        Field<Object?, Object?>(
          'nonNullIntArgField',
          graphqlString,
          args: <Argument>[Argument('nonNullIntArg', graphqlInt.nonNull)],
        ),
        Field<Object?, Object?>(
          'stringListArgField',
          graphqlString,
          args: <Argument>[Argument('stringListArg', graphqlString.list)],
        ),
        Field<Object?, Object?>(
          'complexArgField',
          graphqlString,
          args: <Argument>[Argument('complexArg', complexInput)],
        ),
        Field<Object?, Object?>(
          'multipleReqs',
          graphqlString,
          args: <Argument>[
            Argument('req1', graphqlInt.nonNull),
            Argument('req2', graphqlInt.nonNull),
          ],
        ),
        Field<Object?, Object?>(
          'withDefault',
          graphqlString,
          args: <Argument>[
            Argument('opt', graphqlInt.nonNull, defaultValue: '0'),
          ],
        ),
        Field<Object?, Object?>(
          'booleanArgField',
          graphqlString,
          args: <Argument>[Argument('booleanArg', graphqlBoolean)],
        ),
      ],
    );

final GraphQLSchema<Object?> schema = GraphQLSchema<Object?>(
  query: ObjectType<Object?, Object?>(
    'Query',
    fields: () => <Field<Object?, Object?>>[
      Field<Object?, Object?>('dog', dog),
      Field<Object?, Object?>('cat', cat),
      Field<Object?, Object?>('pet', pet),
      Field<Object?, Object?>('catOrDog', catOrDog),
      Field<Object?, Object?>('dogOrHuman', dogOrHuman),
      Field<Object?, Object?>(
        'human',
        human,
        args: <Argument>[Argument('id', graphqlId)],
      ),
      Field<Object?, Object?>('complicatedArgs', complicatedArgs),
    ],
  ),
);

final GraphQLExecutor<Object?> executor = GraphQLExecutor<Object?>(schema);

List<String> errorsOf(String query, [GraphQLExecutor<Object?>? e]) => <String>[
  for (GraphQLError err in (e ?? executor).validate(parseString(query)))
    err.message,
];

void valid(String query) => expect(errorsOf(query), isEmpty, reason: query);

void invalid(String query, List<String> messages) =>
    expect(errorsOf(query), messages, reason: query);

void main() {
  test('executable definitions', () {
    invalid('{ dog { name } } type Cow { name: String }', <String>[
      'The "Cow" definition is not executable.',
    ]);
  });

  test('operation names and anonymous operations', () {
    valid('query A { dog { name } } query B { cat { name } }');
    invalid('query A { dog { name } } query A { cat { name } }', <String>[
      'There can be only one operation named "A".',
    ]);
    invalid('{ dog { name } } query B { cat { name } }', <String>[
      'This anonymous operation must be the only defined operation.',
    ]);
    invalid('mutation { dog }', <String>[
      'Schema is not configured for mutations.',
    ]);
  });

  test('fields on correct type', () {
    valid('{ dog { name __typename } catOrDog { __typename } }');
    invalid('{ dog { meowVolume } }', <String>[
      'Cannot query field "meowVolume" on type "Dog".',
    ]);
    invalid('{ catOrDog { name } }', <String>[
      'Cannot query field "name" on type "CatOrDog".',
    ]);
    invalid('{ dog { __schema { types { name } } } }', <String>[
      'Cannot query field "__schema" on type "Dog".',
    ]);
  });

  test('leaf field selections', () {
    invalid('{ dog { barks { sinceWhen } } }', <String>[
      'Field "barks" must not have a selection since type "Boolean" has no '
          'subfields.',
    ]);
    invalid('{ human }', <String>[
      'Field "human" of type "Human" must have a selection of subfields. '
          'Did you mean "human { ... }"?',
    ]);
  });

  test('arguments: known, unique, required', () {
    valid('{ dog { doesKnowCommand(dogCommand: SIT) } }');
    valid('{ dog { isHouseTrained } }');
    valid('{ complicatedArgs { withDefault } }');
    invalid(
      '{ dog { doesKnowCommand(command: SIT, dogCommand: SIT) } }',
      <String>['Unknown argument "command" on field "Dog.doesKnowCommand".'],
    );
    invalid(
      '{ dog { doesKnowCommand(dogCommand: SIT, dogCommand: HEEL) } }',
      <String>['There can be only one argument named "dogCommand".'],
    );
    invalid('{ complicatedArgs { multipleReqs(req1: 1) } }', <String>[
      'Field "multipleReqs" argument "req2" of type "Int!" is required, but '
          'it was not provided.',
    ]);
    invalid('{ dog { name @include } }', <String>[
      'Directive "@include" argument "if" of type "Boolean!" is required, '
          'but it was not provided.',
    ]);
  });

  test('fragments: unique, known, used, on composite types', () {
    invalid(
      '{ dog { ...F } } fragment F on Dog { name } fragment F on Dog { name }',
      <String>['There can be only one fragment named "F".'],
    );
    invalid('{ dog { ...Nope } }', <String>['Unknown fragment "Nope".']);
    invalid('{ dog { name } } fragment F on Dog { name }', <String>[
      'Fragment "F" is never used.',
    ]);
    invalid('{ dog { ...F } } fragment F on NotInSchema { name }', <String>[
      'Unknown type "NotInSchema".',
    ]);
    invalid('{ dog { ... on Boolean { x } } }', <String>[
      'Fragment cannot condition on non composite type "Boolean".',
    ]);
    invalid('{ dog { ...F } } fragment F on Int { x }', <String>[
      'Fragment "F" cannot condition on non composite type "Int".',
    ]);
  });

  test('fragment cycles', () {
    invalid(
      '{ dog { ...A } } fragment A on Dog { ...B } fragment B on Dog { ...A }',
      <String>['Cannot spread fragment "A" within itself via B.'],
    );
    invalid(
      '{ dog { ...A } } fragment A on Dog { owner { pets { ...P } } ...A } '
      'fragment P on Pet { name }',
      <String>['Cannot spread fragment "A" within itself.'],
    );
  });

  test('possible fragment spreads', () {
    valid('{ pet { ... on Dog { barks } ... on CatOrDog { __typename } } }');
    valid('{ dogOrHuman { ... on Pet { name } } }');
    invalid('{ dog { ... on Cat { meows } } }', <String>[
      'Fragment cannot be spread here as objects of type "Dog" can never be '
          'of type "Cat".',
    ]);
    invalid('{ human { ...P } } fragment P on Pet { name }', <String>[
      'Fragment "P" cannot be spread here as objects of type "Human" can '
          'never be of type "Pet".',
    ]);
    invalid(
      '{ catOrDog { ... on DogOrHuman { __typename } } cat { ... on DogOrHuman { __typename } } }',
      <String>[
        'Fragment cannot be spread here as objects of type "Cat" can never be '
            'of type "DogOrHuman".',
      ],
    );
  });

  test('values of correct type', () {
    valid('{ complicatedArgs { intArgField(intArg: 2) } }');
    valid('{ complicatedArgs { stringListArgField(stringListArg: "one") } }');
    valid(
      '{ complicatedArgs { complexArgField(complexArg: {requiredField: true}) } }',
    );
    invalid('{ complicatedArgs { intArgField(intArg: "3") } }', <String>[
      'Expected value of type "Int", found "3"; Int cannot represent '
          'non-integer value: "3"',
    ]);
    invalid('{ complicatedArgs { intArgField(intArg: 3000000000) } }', <String>[
      'Expected value of type "Int", found 3000000000; Int cannot represent '
          'non 32-bit signed integer value: 3000000000',
    ]);
    invalid(
      '{ complicatedArgs { nonNullIntArgField(nonNullIntArg: null) } }',
      <String>['Expected value of type "Int!", found null.'],
    );
    invalid('{ dog { doesKnowCommand(dogCommand: JUMP) } }', <String>[
      'Value "JUMP" does not exist in "DogCommand" enum.',
    ]);
    invalid('{ dog { doesKnowCommand(dogCommand: "SIT") } }', <String>[
      'Enum "DogCommand" cannot represent non-enum value: "SIT".',
    ]);
    invalid(
      '{ complicatedArgs { complexArgField(complexArg: {intField: 4}) } }',
      <String>[
        'Field "ComplexInput.requiredField" of required type "Boolean!" was '
            'not provided.',
      ],
    );
    invalid(
      '{ complicatedArgs { complexArgField(complexArg: {requiredField: true, nope: 1}) } }',
      <String>['Field "nope" is not defined by type "ComplexInput".'],
    );
    invalid(
      '{ complicatedArgs { complexArgField(complexArg: {requiredField: true, requiredField: false}) } }',
      <String>['There can be only one input field named "requiredField".'],
    );
  });

  test('directives', () {
    valid('{ dog { name @skip(if: true) } }');
    invalid('{ dog { name @nope } }', <String>['Unknown directive "@nope".']);
    invalid('query @skip(if: true) { dog { name } }', <String>[
      'Directive "@skip" may not be used on QUERY.',
    ]);
    invalid('{ dog { name @skip(if: true) @skip(if: false) } }', <String>[
      'The directive "@skip" can only be used once at this location.',
    ]);
  });

  test('variables: unique, input types, defined, used', () {
    invalid(
      r'query ($a: Int, $a: Int) { complicatedArgs { intArgField(intArg: $a) } }',
      <String>[r'There can be only one variable named "$a".'],
    );
    invalid(r'query ($a: Dog) { dog { name } }', <String>[
      r'Variable "$a" cannot be non-input type "Dog".',
      r'Variable "$a" is never used.',
    ]);
    invalid(r'query ($a: Nope) { dog { name } }', <String>[
      'Unknown type "Nope".',
      r'Variable "$a" is never used.',
    ]);
    invalid(
      r'query Q { complicatedArgs { intArgField(intArg: $x) } }',
      <String>[r'Variable "$x" is not defined by operation "Q".'],
    );
    invalid(r'query Q($x: Int) { dog { name } }', <String>[
      r'Variable "$x" is never used in operation "Q".',
    ]);
    // A variable used only in a fragment counts.
    valid(r'''
      query Q($x: Int) { complicatedArgs { ...F } }
      fragment F on ComplicatedArgs { intArgField(intArg: $x) }
    ''');
    invalid(
      r'''
      query A($x: Int) { complicatedArgs { ...F } }
      query B { complicatedArgs { ...F } }
      fragment F on ComplicatedArgs { intArgField(intArg: $x) }
    ''',
      <String>[r'Variable "$x" is not defined by operation "B".'],
    );
  });

  test('variables in allowed positions', () {
    valid(
      r'query ($b: Boolean!) { complicatedArgs { booleanArgField(booleanArg: $b) } }',
    );
    valid(
      r'query ($i: Int = 1) { complicatedArgs { nonNullIntArgField(nonNullIntArg: $i) } }',
    );
    valid(r'query ($i: Int) { complicatedArgs { withDefault(opt: $i) } }');
    valid(
      r'query ($s: String) { complicatedArgs { stringListArgField(stringListArg: [$s]) } }',
    );
    invalid(
      r'query ($i: Int) { complicatedArgs { nonNullIntArgField(nonNullIntArg: $i) } }',
      <String>[
        r'Variable "$i" of type "Int" used in position expecting type "Int!".',
      ],
    );
    invalid(
      r'query ($s: String) { complicatedArgs { intArgField(intArg: $s) } }',
      <String>[
        r'Variable "$s" of type "String" used in position expecting type "Int".',
      ],
    );
    invalid(
      r'query ($s: [String]) { complicatedArgs { stringListArgField(stringListArg: [$s]) } }',
      <String>[
        r'Variable "$s" of type "[String]" used in position expecting type "String".',
      ],
    );
    invalid(r'query ($b: Boolean) { dog { name @skip(if: $b) } }', <String>[
      r'Variable "$b" of type "Boolean" used in position expecting type "Boolean!".',
    ]);
  });

  test('overlapping fields can be merged', () {
    valid('{ dog { name name } }');
    valid('{ dog { n: name ...F } } fragment F on Dog { n: name }');
    valid(
      '{ dog { doesKnowCommand(dogCommand: SIT) doesKnowCommand(dogCommand: SIT) } }',
    );
    // Different object parents can never be the same value.
    valid(
      '{ pet { ... on Dog { x: barkVolume } ... on Cat { x: meowVolume } } }',
    );
    invalid('{ dog { x: name x: nickname } }', <String>[
      'Fields "x" conflict because "name" and "nickname" are different '
          'fields. Use different aliases on the fields to fetch both if this '
          'was intentional.',
    ]);
    invalid(
      '{ dog { doesKnowCommand(dogCommand: SIT) doesKnowCommand(dogCommand: HEEL) } }',
      <String>[
        'Fields "doesKnowCommand" conflict because they have differing '
            'arguments. Use different aliases on the fields to fetch both if '
            'this was intentional.',
      ],
    );
    invalid(
      '{ pet { ... on Dog { x: barkVolume } ... on Cat { x: meows } } }',
      <String>[
        'Fields "x" conflict because they return conflicting types "Int" and '
            '"Boolean". Use different aliases on the fields to fetch both if '
            'this was intentional.',
      ],
    );
    invalid(
      '{ dog { owner { x: name } owner { x: relatives { name } } } }',
      <String>[
        'Fields "x" conflict because "name" and "relatives" are different '
            'fields. Use different aliases on the fields to fetch both if this '
            'was intentional.',
      ],
    );
    invalid(
      '{ dog { ...F name: nickname } } fragment F on Dog { name }',
      <String>[
        'Fields "name" conflict because "name" and "nickname" are different '
            'fields. Use different aliases on the fields to fetch both if this '
            'was intentional.',
      ],
    );
  });

  test('overlapping fields: conflicts deep between non-first fields', () {
    String conflict =
        'Fields "b" conflict because "name" and "__typename" are different '
        'fields. Use different aliases on the fields to fetch both if this '
        'was intentional.';
    invalid(
      '{ dog { a: name } dog { owner { b: name } } dog { owner { b: __typename } } }',
      <String>[conflict],
    );
    invalid(
      '''
      fragment F on Dog { owner { b: name } }
      fragment G on Dog { owner { b: __typename } }
      { dog { a: name } dog { ...F } dog { ...G } }
    ''',
      <String>[conflict],
    );
    valid(
      '{ dog { a: name } dog { owner { b: name } } dog { owner { b: name } } }',
    );
  });

  test('a rule that throws does not make execute throw', () async {
    GraphQLExecutor<Object?> e = GraphQLExecutor<Object?>(
      schema,
      rules: <ValidationRule>[const _ThrowingRule()],
    );
    GraphQLResponse r = await e.execute(
      const GraphQLRequest('{ dog { name } }'),
      context: null,
    );
    expect(r.hasData, isFalse);
    expect(r.errors.single.message, 'Internal server error');
    expect(r.errors.single.originalError, isA<StateError>());
  });

  test('validation stops after maxErrors', () {
    String tooMany =
        'Too many validation errors, error limit reached. Validation aborted.';
    StringBuffer fields = StringBuffer();
    for (int i = 0; i < 1000; i++) {
      fields.write('u$i ');
    }
    List<String> errors = errorsOf('{ dog { $fields} }');
    expect(errors, hasLength(101));
    expect(errors.first, 'Cannot query field "u0" on type "Dog".');
    expect(errors.last, tooMany);

    StringBuffer vars = StringBuffer();
    for (int i = 0; i < 1000; i++) {
      vars.write(r'$a: Int ');
    }
    expect(errorsOf('query ($vars) { dog { name } }').last, tooMany);

    GraphQLExecutor<Object?> few = GraphQLExecutor<Object?>(
      schema,
      maxErrors: 3,
    );
    expect(errorsOf('{ dog { $fields} }', few), hasLength(4));
  });

  test('each bad variable use is its own error, with its own location', () {
    List<GraphQLError> errors(String q) => executor.validate(parseString(q));
    List<GraphQLError> undefined = errors(
      'query Q { human(id: \$b) { name } dog { name @skip(if: \$b) } }',
    );
    expect(
      <String>[for (GraphQLError e in undefined) e.message],
      <String>[
        r'Variable "$b" is not defined by operation "Q".',
        r'Variable "$b" is not defined by operation "Q".',
      ],
    );
    expect(undefined[0].locations.first, const SourceLocation(1, 22));
    expect(undefined[1].locations.first, const SourceLocation(1, 56));

    List<GraphQLError> wrongType = errors('''
query (\$a: String) {
  complicatedArgs { intArgField(intArg: \$a) }
  c2: complicatedArgs { intArgField(intArg: \$a) }
}''');
    expect(wrongType, hasLength(2));
    expect(wrongType[0].locations.last, const SourceLocation(2, 42));
    expect(wrongType[1].locations.last, const SourceLocation(3, 46));

    // The same through two fragments.
    List<GraphQLError> viaFragments = errors('''
query (\$a: String) { complicatedArgs { ...F ...G } }
fragment F on ComplicatedArgs { intArgField(intArg: \$a) }
fragment G on ComplicatedArgs { i2: intArgField(intArg: \$a) }''');
    expect(viaFragments, hasLength(2));
    expect(viaFragments[0].locations.last.line, 2);
    expect(viaFragments[1].locations.last.line, 3);
  });

  test('a bad literal value points at its argument or input field', () {
    List<GraphQLError> errors = executor.validate(
      parseString('{ complicatedArgs { intArgField(intArg: 2147483648) } }'),
    );
    expect(errors.single.locations, <SourceLocation>[
      const SourceLocation(1, 33),
    ]);
    errors = executor.validate(
      parseString(
        '{ complicatedArgs { complexArgField(complexArg: {requiredField: true, intField: "x"}) } }',
      ),
    );
    expect(errors.single.locations, <SourceLocation>[
      const SourceLocation(1, 71),
    ]);
    errors = executor.validate(
      parseString(
        '{ complicatedArgs { stringListArgField(stringListArg: [1, null]) } }',
      ),
    );
    expect(errors.single.locations, <SourceLocation>[
      const SourceLocation(1, 40),
    ]);
  });

  test('extra rules run after the spec rules', () {
    GraphQLExecutor<Object?> e = GraphQLExecutor<Object?>(
      schema,
      rules: <ValidationRule>[const _MaxTopFields(1)],
    );
    expect(errorsOf('{ dog { name } }', e), isEmpty);
    expect(errorsOf('{ dog { name } cat { name } }', e), <String>[
      'Too many fields.',
    ]);
    // Not run when the spec rules fail.
    expect(errorsOf('{ dog { nope } cat { name } }', e), <String>[
      'Cannot query field "nope" on type "Dog".',
    ]);
  });

  test('introspection switch', () {
    GraphQLExecutor<Object?> off = GraphQLExecutor<Object?>(
      schema,
      introspection: false,
    );
    expect(errorsOf('{ __schema { types { name } } }', off), <String>[
      'GraphQL introspection has been disabled, but the requested query '
          'contained the field "__schema".',
    ]);
    expect(errorsOf('{ dog { __typename } }', off), isEmpty);
  });
}

class _MaxTopFields implements ValidationRule {
  const _MaxTopFields(this.max);

  final int max;

  @override
  List<GraphQLError> validate(ValidationContext context) => <GraphQLError>[
    for (OperationDefinitionNode op in context.operations)
      if (op.selectionSet.selections.length > max)
        GraphQLError.at('Too many fields.', <Node>[op]),
  ];
}

class _ThrowingRule implements ValidationRule {
  const _ThrowingRule();

  @override
  List<GraphQLError> validate(ValidationContext context) =>
      throw StateError('rule bug');
}
