import 'dart:math';

import 'package:dox_auth/dox_auth.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';
import 'package:dox_graphql_test_app/app/models/note/note.model.dart';
import 'package:dox_graphql_test_app/app/models/user/user.model.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

/// The real `AuthMiddleware` of dox_auth, with JWT tokens and the users
/// table.
void main() {
  late DoxTestClient client;
  late String token;

  setUpAll(() async {
    await setUpDatabase();
    // a new key for each run: a fixed key in a public repo is public
    String secret = List<String>.generate(
      32,
      (int i) => Random.secure().nextInt(36).toRadixString(36),
    ).join();
    Auth.initialize(
      AuthConfig(
        defaultGuard: 'api',
        guards: <String, AuthGuard>{
          'api': AuthGuard(
            driver: JwtAuthDriver(secret: SecretKey(secret)),
            provider: AuthProvider(model: () => User()),
          ),
        },
      ),
    );
    User ada = (await User().find(1))!;
    token = Auth().login(ada)!;
    client = await startApp(
      GraphQLConfig(
        schema: graphqlSchema,
        middleware: <Object>[AuthMiddleware()],
      ),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  tearDown(stopCounting);

  Future<Map<String, Object?>> send(String query, {String? bearer}) {
    return run(
      client,
      query,
      user: null,
      headers: <String, String>{'authorization': 'Bearer ${bearer ?? ''}'},
    );
  }

  const String query = '{ post(id: "1") { title user { name } } }';

  test('a guest gets UNAUTHENTICATED on the protected field', () async {
    Map<String, Object?> res = await run(client, query, user: null);
    expect(res['data'], <String, Object?>{
      'post': <String, Object?>{'title': 'Hello GraphQL', 'user': null},
    });
    List<Object?> errors = res['errors'] as List<Object?>;
    expect(
      ((errors.single as Map<String, Object?>)['extensions']
          as Map<String, Object?>)['code'],
      'UNAUTHENTICATED',
    );
  });

  test('a valid token gets the data', () async {
    Map<String, Object?> res = await send(query, bearer: token);
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'post': <String, Object?>{
          'title': 'Hello GraphQL',
          'user': <String, Object?>{'name': 'Ada'},
        },
      },
    });
  });

  test('a bad token is a guest, not a failed request', () async {
    Map<String, Object?> res = await send(query, bearer: 'not-a-token');
    expect(res['data'], <String, Object?>{
      'post': <String, Object?>{'title': 'Hello GraphQL', 'user': null},
    });
    expect(res['errors'], hasLength(1));
  });

  test('a public request does no token lookup', () async {
    startCounting();
    Map<String, Object?> res = await send(
      '{ article(id: "1") { title } }',
      bearer: token,
    );
    expect(res['errors'], isNull);
    expect(queries.where((String sql) => sql.contains('users')), isEmpty);
    expect(queries, isNotEmpty);

    queries.clear();
    await send(query, bearer: token);
    expect(queries.where((String sql) => sql.contains('users')), isNotEmpty);
  });

  // Note has `auth: false` and `owner: 'userId'`
  group('owner: |', () {
    Object? code(Map<String, Object?> res) {
      List<Object?> errors = res['errors'] as List<Object?>;
      return ((errors.single as Map<String, Object?>)['extensions']
          as Map<String, Object?>?)?['code'];
    }

    Future<int> count() => QueryBuilder.table('notes').count();

    test('create sets the owner to the logged-in user', () async {
      Map<String, Object?> res = await send(
        'mutation { createNote(input: {title: "Mine"}) { id title userId } }',
        bearer: token,
      );
      expect(res['errors'], isNull);
      Map<String, Object?> note =
          (res['data'] as Map<String, Object?>)['createNote']
              as Map<String, Object?>;
      expect(note['title'], 'Mine');
      expect(note['userId'], 1);
      Note saved = (await Note().find(int.parse(note['id'] as String)))!;
      expect(saved.userId, 1);
    });

    test('a client can not send the owner', () async {
      int before = await count();
      Map<String, Object?> res = await send(
        'mutation { createNote(input: {title: "x", userId: 2}) { id } }',
        bearer: token,
      );
      expect(res['data'], isNull);
      expect(
        (res['errors'] as List<Object?>).toString(),
        contains('Field "userId" is not defined by type "CreateNoteInput".'),
      );
      expect(await count(), before);
    });

    test('a guest gets UNAUTHENTICATED, even with auth: false', () async {
      int before = await count();
      Map<String, Object?> res = await send(
        'mutation { createNote(input: {title: "Guest"}) { id } }',
      );
      expect(res['data'], isNull);
      expect(code(res), 'UNAUTHENTICATED');
      expect(await count(), before);
      // reading stays public
      Map<String, Object?> list = await send('{ notes { id } }');
      expect(list['errors'], isNull);
    });

    test('a guest update and delete stop before the row lookup', () async {
      for (String id in <String>['1', '99999']) {
        startCounting();
        for (String m in <String>[
          'updateNote(id: "$id", input: {title: "x"}) { id }',
          'deleteNote(id: "$id")',
        ]) {
          Map<String, Object?> res = await send('mutation { $m }');
          expect(code(res), 'UNAUTHENTICATED', reason: m);
        }
        expect(queries.where((String q) => q.contains('notes')), isEmpty);
      }
    });

    test('update does not change the owner', () async {
      Map<String, Object?> made = await send(
        'mutation { createNote(input: {title: "Old"}) { id } }',
        bearer: token,
      );
      String id =
          ((made['data'] as Map<String, Object?>)['createNote']
                  as Map<String, Object?>)['id']
              as String;
      Map<String, Object?> res = await send(
        'mutation { updateNote(id: "$id", input: {title: "New"}) '
        '{ title userId } }',
        bearer: token,
      );
      expect(res, <String, Object?>{
        'data': <String, Object?>{
          'updateNote': <String, Object?>{'title': 'New', 'userId': 1},
        },
      });
      Map<String, Object?> bad = await send(
        'mutation { updateNote(id: "$id", input: {userId: 2}) { id } }',
        bearer: token,
      );
      expect(bad['data'], isNull);
      expect(
        (bad['errors'] as List<Object?>).toString(),
        contains('Field "userId" is not defined by type "UpdateNoteInput".'),
      );
      expect((await Note().find(int.parse(id)))!.userId, 1);
    });
  });
}
