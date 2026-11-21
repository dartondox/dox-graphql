// Plain values are completed at once, values that wait give a Future.
// These tests mix both in one object and in one list.
import 'dart:async';

import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

Future<int> later(int value) => Future<int>.delayed(Duration.zero, () => value);

Future<int> laterFail(String message) =>
    Future<int>.delayed(Duration.zero, () => throw StateError(message));

Field<Object?, Object?> field(
  String name,
  GraphQLTypeRef type,
  FutureOr<Object?> Function() resolve,
) {
  return Field<Object?, Object?>(
    name,
    type,
    resolve: (Object? _, ResolveInfo<Object?> _) => resolve(),
  );
}

final ObjectType<Object?, Object?> box = ObjectType<Object?, Object?>(
  'Box',
  fields: () => <Field<Object?, Object?>>[
    field('a', graphqlInt, () => 1),
    field('b', graphqlInt, () => later(2)),
    field('c', graphqlInt, () => 3),
    field('syncFail', graphqlInt, () => throw StateError('sync')),
    field('asyncFail', graphqlInt, () => laterFail('async')),
    field('must', graphqlInt.nonNull, () => throw StateError('must')),
    field('mustAsync', graphqlInt.nonNull, () => laterFail('mustAsync')),
    field('inner', box, () => later(0)),
  ],
);

final GraphQLExecutor<Object?> executor = GraphQLExecutor<Object?>(
  GraphQLSchema<Object?>(
    query: ObjectType<Object?, Object?>(
      'Query',
      fields: () => <Field<Object?, Object?>>[
        field('box', box, () => 0),
        field('mixed', graphqlInt.list, () => <Object?>[1, later(2), 3]),
        field(
          'mixedFail',
          graphqlInt.list,
          () => <Object?>[1, laterFail('item'), 'x', later(4)],
        ),
        field(
          'strict',
          graphqlInt.nonNull.list,
          () => <Object?>[1, laterFail('item'), 'x'],
        ),
      ],
    ),
  ),
  showInternalErrors: true,
);

Future<Map<String, Object?>> run(String query) async {
  return (await executor.execute(
    GraphQLRequest(query),
    context: null,
  )).toJson();
}

List<Object?> paths(Map<String, Object?> r) => <Object?>[
  for (Object? e in r['errors'] as List<Object?>? ?? <Object?>[])
    (e as Map<String, Object?>)['path'],
];

Future<int> failAfter(int ms) => Future<int>.delayed(
  Duration(milliseconds: ms),
  () => throw StateError('late'),
);

final ObjectType<Object?, Object?> deep = ObjectType<Object?, Object?>(
  'Deep',
  fields: () => <Field<Object?, Object?>>[
    field('a', deep, () => 0),
    field(
      'slow',
      graphqlInt,
      () => Future<int>.delayed(const Duration(milliseconds: 20), () => 1),
    ),
    field('b', graphqlInt, () => 1),
    field(
      'must',
      graphqlInt.nonNull,
      () => Future<int>.microtask(() => throw StateError('must')),
    ),
    field(
      'big',
      graphqlInt.list,
      () => Future<List<int>>.delayed(
        const Duration(milliseconds: 1),
        () => List<int>.filled(50, 1),
      ),
    ),
  ],
);

GraphQLExecutor<Object?> limited({int maxNodes = 100000, int maxDepth = 64}) {
  return GraphQLExecutor<Object?>(
    GraphQLSchema<Object?>(
      query: ObjectType<Object?, Object?>(
        'Query',
        fields: () => <Field<Object?, Object?>>[
          field('deep', deep, () => 0),
          field(
            'failing',
            graphqlInt.list,
            () => <Object?>[for (int i = 0; i < 10; i++) failAfter(2)],
          ),
        ],
      ),
    ),
    maxNodes: maxNodes,
    maxDepth: maxDepth,
  );
}

List<String> messagesOf(GraphQLResponse r) => <String>[
  for (GraphQLError e in r.errors) e.message,
];

void main() {
  group('a stopped request', () {
    test('items that are futures give no unhandled error', () async {
      List<Object> unhandled = <Object>[];
      late GraphQLResponse r;
      await runZonedGuarded(() async {
        r = await limited(maxNodes: 5)
            .execute(const GraphQLRequest('{ failing }'), context: null);
        // the items fail after the response is made
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (Object e, StackTrace _) => unhandled.add(e));
      expect(messagesOf(r).single, contains('too much data'));
      expect(unhandled, isEmpty);
    });

    test('a null that bubbles up does not hide the stop', () async {
      // `must` fails first, so `a` is null at once. Then `big` passes
      // maxNodes, while the request still waits for `slow`.
      GraphQLResponse r = await limited(maxNodes: 20).execute(
        const GraphQLRequest('{ deep { a { must big } slow } }'),
        context: null,
      );
      expect(r.data, isNull);
      expect(messagesOf(r).last, contains('too much data'));
    });

    test('a stack overflow is "nested too deep", not a field error', () async {
      const int depth = 2000;
      GraphQLResponse r = await limited(maxDepth: 1000000, maxNodes: 10000000)
          .execute(
            GraphQLRequest('{ deep { ${'a { ' * depth}b${' }' * depth} } }'),
            context: null,
          );
      // Deep enough here, or the query ran: both are right. A field error
      // with part of the data is not.
      if (r.errors.isNotEmpty) {
        expect(r.hasData, isFalse);
        expect(messagesOf(r).single, contains('nested too deep'));
      }
    });
  });

  test('fields keep the query order when some wait', () async {
    Map<String, Object?> r = await run('{ box { a b c inner { c b a } } }');
    Map<String, Object?> data =
        (r['data'] as Map<String, Object?>)['box'] as Map<String, Object?>;
    expect(data.keys.toList(), <String>['a', 'b', 'c', 'inner']);
    expect(data['inner'], <String, Object?>{'c': 3, 'b': 2, 'a': 1});
    expect((data['inner'] as Map<String, Object?>).keys.toList(), <String>[
      'c',
      'b',
      'a',
    ]);
    expect(r.containsKey('errors'), isFalse);
  });

  test('an object of plain values', () async {
    Map<String, Object?> r = await run('{ box { a c } }');
    expect(r['data'], <String, Object?>{
      'box': <String, Object?>{'a': 1, 'c': 3},
    });
  });

  test(
    'an error at once and an error that waits null only the field',
    () async {
      Map<String, Object?> r = await run(
        '{ box { a syncFail b asyncFail c } }',
      );
      expect(r['data'], <String, Object?>{
        'box': <String, Object?>{
          'a': 1,
          'syncFail': null,
          'b': 2,
          'asyncFail': null,
          'c': 3,
        },
      });
      expect(paths(r), <Object?>[
        <Object>['box', 'syncFail'],
        <Object>['box', 'asyncFail'],
      ]);
    },
  );

  test(
    'a non-null field fails at once: the fields that wait still run',
    () async {
      Map<String, Object?> r = await run('{ box { asyncFail must c } }');
      expect(r['data'], <String, Object?>{'box': null});
      expect(paths(r), <Object?>[
        <Object>['box', 'must'],
        <Object>['box', 'asyncFail'],
      ]);
    },
  );

  test('a non-null field that waits fails', () async {
    Map<String, Object?> r = await run('{ box { a mustAsync syncFail } }');
    expect(r['data'], <String, Object?>{'box': null});
    expect(paths(r), <Object?>[
      <Object>['box', 'syncFail'],
      <Object>['box', 'mustAsync'],
    ]);
  });

  test('a list with items that wait', () async {
    Map<String, Object?> r = await run('{ mixed mixedFail }');
    expect(r['data'], <String, Object?>{
      'mixed': <Object?>[1, 2, 3],
      'mixedFail': <Object?>[1, null, null, 4],
    });
    expect(paths(r), <Object?>[
      <Object>['mixedFail', 2],
      <Object>['mixedFail', 1],
    ]);
  });

  test('a non-null item fails: the list is null, each error is kept', () async {
    Map<String, Object?> r = await run('{ strict }');
    expect(r['data'], <String, Object?>{'strict': null});
    expect(paths(r), <Object?>[
      <Object>['strict', 2],
      <Object>['strict', 1],
    ]);
  });
}
