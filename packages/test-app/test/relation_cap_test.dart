import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:dox_orm/dox_orm.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

/// A list relation loads at most `GraphQLConfig.maxRelationRows` rows per
/// batch (all parents at one level). The query has a LIMIT, so a huge
/// relation is never read whole.
void main() {
  late DoxTestClient client;
  const int cap = 250;
  late int big;

  setUpAll(() async {
    await setUpDatabase();
    // 100 posts with 2 comments each: 200 rows in one batch, under the cap
    for (int i = 0; i < 100; i++) {
      int id = await _insertPost('bulk $i');
      await QueryBuilder.table('comments').insertMany(<Map<String, dynamic>>[
        <String, dynamic>{'body': 'a', 'post_id': id},
        <String, dynamic>{'body': 'b', 'post_id': id},
      ]);
    }
    // one post with more comments and tags than the cap
    big = await _insertPost('big');
    await QueryBuilder.table('comments').insertMany(<Map<String, dynamic>>[
      for (int i = 0; i < cap + 5; i++)
        <String, dynamic>{'body': 'c$i', 'post_id': big},
    ]);
    await QueryBuilder.table('post_tag').insertMany(<Map<String, dynamic>>[
      for (int i = 0; i < cap + 5; i++)
        <String, dynamic>{'post_id': big, 'tag_id': 1},
    ]);
    client = await startApp(
      GraphQLConfig(
        schema: graphqlSchema,
        middleware: <Object>[const FakeAuthMiddleware()],
        maxRelationRows: cap,
      ),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  tearDown(stopCounting);

  String message(String relation) =>
      'The relation $relation has more than $cap rows for this request '
      '(GraphQLConfig.maxRelationRows). Ask for fewer parents, or page it '
      'in a resolver.';

  test('many parents with a few children each load', () async {
    Map<String, Object?> res = await run(
      client,
      '{ posts(limit: 100) { comments { id } } }',
    );
    expect(res['errors'], isNull);
    List<Object?> posts =
        (res['data'] as Map<String, Object?>)['posts'] as List<Object?>;
    expect(posts, hasLength(100));
  });

  test('HasMany over the cap is an error, with a LIMIT', () async {
    startCounting();
    Map<String, Object?> res = await run(
      client,
      '{ post(id: "$big") { title comments { id } } }',
    );
    // only the relation is null: the parent keeps its other fields
    expect(res['data'], <String, Object?>{
      'post': <String, Object?>{'title': 'big', 'comments': null},
    });
    List<Object?> errors = res['errors'] as List<Object?>;
    expect(
      (errors.single as Map<String, Object?>)['message'],
      message('Post.comments'),
    );
    String sql = queries.singleWhere((String q) => q.contains('comments'));
    // the limit is a bound value: maxRelationRows + 1
    expect(sql.toUpperCase(), contains(' LIMIT '));
  });

  // Tag has no guard: and no filter: it never refuses, but the cap can
  // still fail the relation, so the field is nullable
  test('ManyToMany over the cap is an error', () async {
    Map<String, Object?> res = await run(
      client,
      '{ post(id: "$big") { tags { name } } }',
    );
    expect(res['data'], <String, Object?>{
      'post': <String, Object?>{'tags': null},
    });
    List<Object?> errors = res['errors'] as List<Object?>;
    expect(
      (errors.single as Map<String, Object?>)['message'],
      message('Post.tags'),
    );
  });
}

Future<int> _insertPost(String title) async {
  Map<String, dynamic> row = await QueryBuilder.table('posts')
      .insert(<String, dynamic>{'title': title});
  return row['id'] as int;
}
