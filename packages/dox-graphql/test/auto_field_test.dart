import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

class Item {
  Item(this.at);

  final DateTime at;
}

final ObjectType<Item, Object?> itemType = ObjectType<Item, Object?>(
  'Item',
  fields: () => <Field<Item, Object?>>[
    Field<Item, Object?>(
      'at',
      graphqlDateTime.nonNull,
      resolve: (Item s, ResolveInfo<Object?> info) => s.at,
    ),
  ],
);

final ObjectType<Object?, Object?> onlyAuto = ObjectType<Object?, Object?>(
  'OnlyAuto',
  fields: () => <Field<Object?, Object?>>[
    Field<Object?, Object?>('x', graphqlInt),
  ],
);

GraphQLSchema<Object?> schemaWith({bool customMutation = true}) {
  return GraphQLSchema<Object?>(
    query: ObjectType<Object?, Object?>(
      'Query',
      fields: () => <Field<Object?, Object?>>[
        AutoField<Object?, Object?>(
          'items',
          itemType.nonNull.list.nonNull,
          resolve: (Object? _, ResolveInfo<Object?> info) => <Item>[
            Item(DateTime.utc(2026, 11, 20)),
          ],
        ),
        AutoField<Object?, Object?>('onlyAuto', onlyAuto),
        Field<Object?, Object?>(
          'local',
          graphqlDateTime,
          resolve: (Object? _, ResolveInfo<Object?> info) =>
              DateTime.utc(2026, 11, 20, 10).toLocal(),
        ),
        Field<Object?, Object?>(
          'echo',
          graphqlDateTime,
          args: <Argument>[Argument('at', graphqlDateTime.nonNull)],
          resolve: (Object? _, ResolveInfo<Object?> info) =>
              info.args.get<DateTime>('at')!.add(const Duration(days: 1)),
        ),
      ],
    ),
    mutation: ObjectType<Object?, Object?>(
      'Mutation',
      fields: () => <Field<Object?, Object?>>[
        AutoField<Object?, Object?>('deleteItem', graphqlBoolean),
        if (customMutation) Field<Object?, Object?>('ping', graphqlBoolean),
      ],
    ),
    types: <NamedType>[itemType],
  );
}

Future<Map<String, Object?>> run(GraphQLSchema<Object?> schema, String q) {
  GraphQLExecutor<Object?> executor = GraphQLExecutor<Object?>(schema);
  return executor
      .execute(GraphQLRequest(q), context: null)
      .then((GraphQLResponse r) => r.toJson());
}

void main() {
  group('AutoField.leaveOut |', () {
    test('keeps the custom fields and every type', () async {
      GraphQLSchema<Object?> schema = AutoField.leaveOut(schemaWith());
      expect(
        schema.query.fields.map((Field<Object?, Object?> f) => f.name),
        <String>['local', 'echo'],
      );
      expect(
        schema.mutation!.fields.map((Field<Object?, Object?> f) => f.name),
        <String>['ping'],
      );
      expect(schema.type('Item'), same(itemType));
      // a type only the auto fields used stays too, for custom resolvers
      expect(schema.type('OnlyAuto'), same(onlyAuto));
      Map<String, Object?> res = await run(schema, '{ items { at } }');
      expect(res['errors'], isNotEmpty);
    });

    test('drops a mutation root with only auto fields', () {
      GraphQLSchema<Object?> schema = AutoField.leaveOut(
        schemaWith(customMutation: false),
      );
      expect(schema.mutation, isNull);
    });

    test('the full schema has the auto fields', () async {
      Map<String, Object?> res = await run(schemaWith(), '{ items { at } }');
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'items': <Object?>[
            <String, Object?>{'at': '2026-11-20T00:00:00.000Z'},
          ],
        },
      });
    });
  });

  group('DateTime |', () {
    test('reads a literal and a variable, and sends ISO 8601 text', () async {
      Map<String, Object?> res = await run(
        schemaWith(),
        '{ echo(at: "2026-11-20T10:00:00Z") }',
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{'echo': '2026-11-21T10:00:00.000Z'},
      });
    });

    test('a local time is sent in UTC', () async {
      Map<String, Object?> res = await run(schemaWith(), '{ local }');
      expect(res, <String, Object?>{
        'data': <String, Object?>{'local': '2026-11-20T10:00:00.000Z'},
      });
    });

    test('a value that is not a date is an error', () async {
      Map<String, Object?> res = await run(schemaWith(), '{ echo(at: "x") }');
      expect(res['data'], isNull);
      expect(res['errors'], isNotEmpty);
    });
  });
}
