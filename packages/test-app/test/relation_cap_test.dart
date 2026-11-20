import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_orm/dox_graphql_orm.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:dox_orm/dox_orm.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

/// A list relation loads at most GraphQLOrm.maxRelationRows rows per
/// batch. The query has a LIMIT, so a huge relation is never read whole.
void main() {
  late DoxTestClient client;

  setUpAll(() async {
    await setUpDatabase();
    int over = GraphQLOrm.maxRelationRows + 5;
    await QueryBuilder.table('comments').insertMany(<Map<String, dynamic>>[
      for (int i = 0; i < over; i++)
        <String, dynamic>{'body': 'c$i', 'post_id': 1},
    ]);
    client = await startApp(
      GraphQLConfig(
        schema: graphqlSchema,
        middleware: <Object>[const FakeAuthMiddleware()],
      ),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  tearDown(stopCounting);

  test('a relation over the cap is an error, with a LIMIT', () async {
    startCounting();
    Map<String, Object?> res = await run(
      client,
      '{ post(id: "1") { title comments { id } } }',
    );
    expect(res['data'], <String, Object?>{'post': null});
    List<Object?> errors = res['errors'] as List<Object?>;
    expect(
      (errors.single as Map<String, Object?>)['message'],
      'The relation Post.comments has more than '
      '${GraphQLOrm.maxRelationRows} rows for this request. Ask for fewer '
      'parents, or page it in a resolver.',
    );
    String sql = queries.singleWhere((String q) => q.contains('comments'));
    // the limit is a bound value: maxRelationRows + 1
    expect(sql.toUpperCase(), contains(' LIMIT '));
  });

  test('a relation under the cap loads', () async {
    Map<String, Object?> res = await run(
      client,
      '{ post(id: "2") { comments { body } } }',
    );
    expect(res['errors'], isNull);
  });
}
