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

void main() {
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
