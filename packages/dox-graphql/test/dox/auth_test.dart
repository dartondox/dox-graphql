import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

import 'app.dart';
import 'auth_app.dart';

const Map<String, String> good = <String, String>{
  'accept': 'application/json',
  'authorization': 'Bearer good-ann',
};

void main() {
  late DoxTestClient client;

  setUpAll(() async {
    Env().env = <String, String>{};
    client = await startApp(
      GraphQLConfig(
        schema: authSchema,
        middleware: const <Object>[FakeLoginMiddleware()],
      ),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  Future<TestResponse> send(
    String query, [
    Map<String, String> headers = acceptJson,
  ]) {
    return client.post(
      '/graphql',
      body: <String, Object?>{'query': query},
      headers: headers,
    );
  }

  Map<String, Object?> unauthenticated(String field) => <String, Object?>{
    'message': 'Unauthenticated',
    'locations': <Object?>[
      <String, Object?>{'line': 1, 'column': 3},
    ],
    'path': <Object?>[field],
    'extensions': <String, Object?>{'code': 'UNAUTHENTICATED'},
  };

  test('a guest gets UNAUTHENTICATED on a default field, with 200', () async {
    TestResponse res = await send('{ me }');
    expect(res.status, 200);
    expect(res.json, <String, Object?>{
      'errors': <Object?>[unauthenticated('me')],
      'data': <String, Object?>{'me': null},
    });
  });

  test('a logged-in user gets the data', () async {
    TestResponse res = await send('{ me count }', good);
    expect(res.json, <String, Object?>{
      'data': <String, Object?>{'me': 'ann', 'count': 1},
    });
  });

  test('auth: false is public, also on an AutoField', () async {
    TestResponse res = await send('{ open autoOpen }');
    expect(res.json, <String, Object?>{
      'data': <String, Object?>{'open': 'hi', 'autoOpen': 'a'},
    });
  });

  test('a bad token does not stop the request', () async {
    TestResponse res = await send('{ open me }', <String, String>{
      ...acceptJson,
      'authorization': 'Bearer bad',
    });
    expect(res.status, 200);
    expect(res.json['data'], <String, Object?>{'open': 'hi', 'me': null});
    expect(res.json['errors'][0]['extensions'], <String, Object?>{
      'code': 'UNAUTHENTICATED',
    });
  });

  test('a protected non-null field makes data null', () async {
    TestResponse res = await send('{ open count }');
    expect(res.json['data'], isNull);
    expect(res.json['errors'], hasLength(1));
  });

  test('a guest mutation does not run the resolver', () async {
    int before = writes;
    TestResponse res = await send('mutation { write }');
    expect(res.json['errors'][0]['message'], 'Unauthenticated');
    expect(writes, before);
    res = await send('mutation { write }', good);
    expect(res.json['data'], <String, Object?>{'write': before + 1});
  });

  test('a field of a type is public unless auth: true', () async {
    TestResponse res = await send('{ note { title secretBody } }');
    expect(res.json['data'], <String, Object?>{
      'note': <String, Object?>{'title': 't', 'secretBody': null},
    });
    expect(res.json['errors'][0]['path'], <Object?>['note', 'secretBody']);
    res = await send('{ note { title secretBody } }', good);
    expect(res.json['data'], <String, Object?>{
      'note': <String, Object?>{'title': 't', 'secretBody': 'b'},
    });
  });

  test('__typename needs no login', () async {
    TestResponse res = await send('{ __typename }');
    expect(res.json, <String, Object?>{
      'data': <String, Object?>{'__typename': 'Query'},
    });
  });
}
