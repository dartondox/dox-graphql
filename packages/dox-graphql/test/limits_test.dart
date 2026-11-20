import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

// A type that points at itself, so queries can nest without end.
final ObjectType<int, Object?> nodeType = ObjectType<int, Object?>(
  'Node',
  fields: () => <Field<int, Object?>>[
    Field<int, Object?>(
      'a',
      nodeType,
      resolve: (int n, ResolveInfo<Object?> i) => n + 1,
    ),
    Field<int, Object?>(
      'b',
      graphqlInt,
      resolve: (int n, ResolveInfo<Object?> i) => n,
    ),
  ],
);

final Schema<Object?> schema = Schema<Object?>(
  query: ObjectType<Object?, Object?>(
    'Query',
    fields: () => <Field<Object?, Object?>>[
      Field<Object?, Object?>(
        'a',
        nodeType,
        resolve: (Object? _, ResolveInfo<Object?> i) => 0,
      ),
      Field<Object?, Object?>(
        'b',
        graphqlInt,
        resolve: (Object? _, ResolveInfo<Object?> i) => 1,
      ),
    ],
  ),
);

final GraphQLExecutor<Object?> executor = GraphQLExecutor<Object?>(schema);

/// `{ a { a { ... { b } } } }` with [depth] levels of `a`.
String nested(int depth) => '{ ${'a { ' * depth}b${' }' * depth} }';

Future<GraphQLResponse> run(String query, [GraphQLExecutor<Object?>? e]) =>
    (e ?? executor).execute(GraphQLRequest(query), context: null);

void expectTooDeep(GraphQLResponse r, [int limit = 64]) {
  expect(r.hasData, isFalse);
  expect(
    r.errors.single.message,
    'The query is nested too deep: the limit '
    'is $limit.',
  );
}

/// Runs [body] and checks that it takes less than [limit].
Future<void> fast(Future<void> Function() body, Duration limit) async {
  Stopwatch watch = Stopwatch()..start();
  await body();
  expect(watch.elapsed, lessThan(limit));
}

void main() {
  group('depth', () {
    test('a query within the limit runs', () async {
      GraphQLResponse r = await run(nested(60));
      expect(r.errors, isEmpty);
    });

    test('a 1000 deep query is an error, not a crash', () async {
      expectTooDeep(await run(nested(1000)));
    });

    test('very deep broken text is an error, not a throw', () async {
      expectTooDeep(await run('{${'a{' * 2000}'));
      expectTooDeep(await run('{${'a{' * 5000}b${'}' * 5000}}'));
      expectTooDeep(await run('{ b(x: ${'[' * 3000}) }'));
    });

    test('a fragment chain counts with its fragments', () async {
      // Each fragment adds one level, so the text itself is flat.
      StringBuffer q = StringBuffer('{ ...F0 }\n');
      for (int i = 0; i < 100; i++) {
        q.writeln(
          'fragment F$i on ${i == 0 ? 'Query' : 'Node'} { a { ...F${i + 1} } }',
        );
      }
      q.writeln('fragment F100 on Node { b }');
      expectTooDeep(await run(q.toString()));
    });

    test('braces in strings and comments do not count', () async {
      GraphQLResponse r = await run('# ${'{' * 100}\n{ b @skip(if: false) }');
      expect(r.errors, isEmpty);
      GraphQLResponse s = await run('{ b(x: "${'{' * 100}") }');
      // Unknown argument, but not too deep.
      expect(
        s.errors.single.message,
        'Unknown argument "x" on field "Query.b".',
      );
    });

    test('the limit is configurable', () async {
      GraphQLExecutor<Object?> strict = GraphQLExecutor<Object?>(
        schema,
        maxDepth: 3,
      );
      expect((await run(nested(1), strict)).errors, isEmpty);
      expectTooDeep(await run(nested(3), strict), 3);
    });

    test('a too long query is an error', () async {
      GraphQLExecutor<Object?> small = GraphQLExecutor<Object?>(
        schema,
        maxQueryLength: 10,
      );
      GraphQLResponse r = await run('{ b b b b b }', small);
      expect(
        r.errors.single.message,
        'The query is too long: the limit is 10 characters.',
      );
    });
  });

  group('overlap check is fast', () {
    Duration limit = const Duration(seconds: 2);

    test('5000 copies of one field', () async {
      await fast(() async {
        GraphQLResponse r = await run('{ ${'b ' * 5000}}');
        expect(r.errors, isEmpty);
        expect(r.data, <String, Object?>{'b': 1});
      }, limit);
    });

    test('5000 copies of a nested field', () async {
      await fast(() async {
        GraphQLResponse r = await run('{ ${'a { b } ' * 5000}}');
        expect(r.errors, isEmpty);
      }, limit);
    });

    test('a 1000 fragment chain', () async {
      await fast(() async {
        StringBuffer q = StringBuffer('{ ...F0 }\n');
        for (int i = 0; i < 1000; i++) {
          q.writeln('fragment F$i on Query { b ...F${i + 1} }');
        }
        q.writeln('fragment F1000 on Query { b }');
        GraphQLResponse r = await run(q.toString());
        expect(r.errors, isEmpty);
      }, limit);
    });

    test('5000 spreads', () async {
      await fast(() async {
        GraphQLResponse r = await run(
          '{ ${'...F ' * 5000}} fragment F on Query { b a { b } }',
        );
        expect(r.errors, isEmpty);
      }, limit);
    });

    test('a conflict is still found among many fields', () async {
      GraphQLResponse r = await run('{ ${'b ' * 2000}b: a { b } }');
      expect(r.errors.single.message, startsWith('Fields "b" conflict'));
    });

    test('a hostile query hits the work budget', () async {
      // 100 fields with one name, each with a set of 2000 fields: the
      // sub sets must be compared, which is too much work.
      String inner = 'b ' * 2000;
      await fast(() async {
        GraphQLResponse r = await run('{ ${'a { $inner} ' * 100}}');
        expect(
          r.errors.single.message,
          'The query is too complex to validate.',
        );
      }, limit);
    });
  });

  group('error messages', () {
    Schema<Object?> failing = Schema<Object?>(
      query: ObjectType<Object?, Object?>(
        'Query',
        fields: () => <Field<Object?, Object?>>[
          Field<Object?, Object?>(
            'dart',
            graphqlInt,
            resolve: (Object? _, ResolveInfo<Object?> i) =>
                throw StateError('secret path /etc'),
          ),
          Field<Object?, Object?>(
            'own',
            graphqlInt,
            resolve: (Object? _, ResolveInfo<Object?> i) =>
                throw GraphQLError('Not allowed.'),
          ),
        ],
      ),
    );

    test('Dart errors are hidden by default', () async {
      GraphQLResponse r = await GraphQLExecutor<Object?>(failing)
          .execute(const GraphQLRequest('{ dart own }'), context: null);
      expect(
        <String>[for (GraphQLError e in r.errors) e.message],
        <String>['Internal server error', 'Not allowed.'],
      );
      expect(r.errors.first.originalError, isA<StateError>());
    });

    test('showInternalErrors shows the real message', () async {
      GraphQLResponse r = await GraphQLExecutor<Object?>(
        failing,
        showInternalErrors: true,
      ).execute(const GraphQLRequest('{ dart }'), context: null);
      expect(r.errors.single.message, 'Bad state: secret path /etc');
    });
  });
}
