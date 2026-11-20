import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

import 'app.dart';

void main() {
  late DoxTestClient client;

  setUpAll(() async {
    Env().env = <String, String>{};
    client = await startApp(
      GraphQLConfig(
        schema: schema,
        path: '/api/graphql',
        middleware: <Object>[const FakeAuthMiddleware()],
        introspection: true,
        graphiql: true,
        maxDepth: 3,
      ),
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  Future<TestResponse> post(
    Object? body, {
    Map<String, String> headers = acceptNew,
  }) {
    return client.post('/api/graphql', body: body, headers: headers);
  }

  Future<TestResponse> get(
    Map<String, String> params, {
    Map<String, String> headers = acceptNew,
  }) {
    String query = Uri(queryParameters: params).query;
    return client.get('/api/graphql?$query', headers: headers);
  }

  group('POST', () {
    test('runs a query with variables', () async {
      TestResponse res = await post(<String, Object?>{
        'query': r'query Q($t: String) { hello echo(text: $t) }',
        'variables': <String, Object?>{'t': 'hi'},
        'operationName': 'Q',
        'extensions': <String, Object?>{'any': 1},
      });
      res
          .expectStatus(200)
          .expectHeader(
            'content-type',
            'application/graphql-response+json; charset=utf-8',
          )
          .expectJson(<String, Object?>{
            'data': <String, Object?>{'hello': 'world', 'echo': 'hi'},
          });
    });

    test('runs a mutation', () async {
      TestResponse res = await post(<String, Object?>{
        'query': 'mutation { double(n: 21) }',
      });
      res.expectStatus(200).expectJson(<String, Object?>{
        'data': <String, Object?>{'double': 42},
      });
    });

    test('sends application/json when the client does not ask for the '
        'new type', () async {
      TestResponse res = await post(<String, Object?>{
        'query': '{ hello }',
      }, headers: acceptJson);
      res
          .expectStatus(200)
          .expectHeader('content-type', 'application/json; charset=utf-8');
    });

    test('a validation error is 400 with the new type', () async {
      TestResponse res = await post(<String, Object?>{'query': '{ nope }'});
      res.expectStatus(400);
      expect(res.json['data'], isNull);
      expect(res.json['errors'][0]['message'], contains('nope'));
    });

    test('a validation error is 200 with application/json', () async {
      TestResponse res = await post(<String, Object?>{
        'query': '{ nope }',
      }, headers: acceptJson);
      res.expectStatus(200);
      expect(res.json['errors'], hasLength(1));
    });

    test('a syntax error is 400', () async {
      TestResponse res = await post(<String, Object?>{'query': '{ hello '});
      res.expectStatus(400);
      expect(res.json['errors'][0]['message'], startsWith('Syntax Error'));
    });

    test('bad JSON gives a clean 400', () async {
      TestResponse res = await client.post(
        '/api/graphql',
        body: '{"query": ',
        headers: <String, String>{
          ...acceptNew,
          'content-type': 'application/json',
        },
      );
      res.expectStatus(400).expectJson(<String, Object?>{
        'errors': <Object?>[
          <String, Object?>{'message': 'The body is not valid JSON.'},
        ],
      });
    });

    test('a body that is not an object is 400', () async {
      TestResponse res = await post(<Object?>[1, 2]);
      res.expectStatus(400);
      expect(
        res.json['errors'][0]['message'],
        'The body must be a JSON object.',
      );
    });

    test('a missing query is 400', () async {
      TestResponse res = await post(<String, Object?>{'variables': null});
      res.expectStatus(400);
      expect(res.json['errors'][0]['message'], 'The request has no "query".');
    });

    test('wrong types in the body are 400', () async {
      TestResponse res = await post(<String, Object?>{
        'query': '{ hello }',
        'extensions': 'x',
      });
      res.expectStatus(400);
      expect(
        res.json['errors'][0]['message'],
        'The "extensions" must be an object.',
      );
    });

    test('a body that is not JSON is 415', () async {
      TestResponse res = await client.post(
        '/api/graphql',
        body: 'query={hello}',
        headers: <String, String>{
          ...acceptNew,
          'content-type': 'application/x-www-form-urlencoded',
        },
      );
      res.expectStatus(415);
      expect(res.json['errors'][0]['message'], contains('application/json'));
    });
  });

  group('GET', () {
    test('runs a query from the URL', () async {
      TestResponse res = await get(<String, String>{
        'query': r'query Q($t: String) { echo(text: $t) }',
        'variables': '{"t": "from get"}',
        'operationName': 'Q',
      });
      res.expectStatus(200).expectJson(<String, Object?>{
        'data': <String, Object?>{'echo': 'from get'},
      });
    });

    test('a mutation is 405 with Allow: POST, and does not run', () async {
      TestResponse res = await get(<String, String>{
        'query': 'mutation { double(n: 1) }',
      });
      res.expectStatus(405).expectHeader('allow', 'POST');
      expect(res.json['data'], isNull);
      expect(
        res.json['errors'][0]['message'],
        'Mutations must be sent with POST.',
      );
    });

    test('bad variables JSON is 400', () async {
      TestResponse res = await get(<String, String>{
        'query': '{ hello }',
        'variables': '{bad',
      });
      res.expectStatus(400);
      expect(
        res.json['errors'][0]['message'],
        'The "variables" are not valid JSON.',
      );
    });

    test('no query is 400', () async {
      TestResponse res = await get(<String, String>{});
      res.expectStatus(400);
    });
  });

  group('context', () {
    test('has the request and the user', () async {
      TestResponse res = await post(
        <String, Object?>{'query': '{ me path }'},
        headers: <String, String>{...acceptNew, 'x-user': 'ann'},
      );
      res.expectJson(<String, Object?>{
        'data': <String, Object?>{'me': 'ann', 'path': '/api/graphql'},
      });
    });

    test('a guest has no user', () async {
      TestResponse res = await post(<String, Object?>{'query': '{ me }'});
      res.expectJson(<String, Object?>{
        'data': <String, Object?>{'me': null},
      });
    });

    test('makes services from the Dox container', () async {
      TestResponse res = await post(<String, Object?>{'query': '{ greet }'});
      res.expectJson(<String, Object?>{
        'data': <String, Object?>{'greet': 'hello ann'},
      });
    });

    test('a DataLoader lives for one request', () async {
      batches.clear();
      String query = '{ a: name(id: 1) b: name(id: 2) c: name(id: 1) }';
      TestResponse first = await post(<String, Object?>{'query': query});
      first.expectJson(<String, Object?>{
        'data': <String, Object?>{'a': 'user1', 'b': 'user2', 'c': 'user1'},
      });
      // one batch for the whole request
      expect(batches, <List<int>>[
        <int>[1, 2],
      ]);
      // a new request does not see the cache of the first one
      await post(<String, Object?>{'query': query});
      expect(batches, <List<int>>[
        <int>[1, 2],
        <int>[1, 2],
      ]);
    });
  });

  group('errors', () {
    test('an internal error is hidden and reported', () async {
      RecordingHandler.reported.clear();
      TestResponse res = await post(<String, Object?>{'query': '{ boom }'});
      res.expectStatus(200);
      expect(res.json['data'], <String, Object?>{'boom': null});
      expect(res.json['errors'][0]['message'], 'Internal server error');
      expect(res.body, isNot(contains('secret')));
      expect(RecordingHandler.reported, hasLength(1));
      expect('${RecordingHandler.reported.single}', contains('secret'));
    });
  });

  group('config', () {
    test('maxDepth comes from the config', () async {
      TestResponse res = await post(<String, Object?>{
        'query': '{ __schema { types { fields { name } } } }',
      });
      res.expectStatus(400);
      expect(res.json['errors'][0]['message'], contains('nested too deep'));
    });

    test('introspection is on when the config says so', () async {
      TestResponse res = await post(<String, Object?>{
        'query': '{ __schema { queryType { name } } }',
      });
      res.expectStatus(200).expectJson(<String, Object?>{
        'data': <String, Object?>{
          '__schema': <String, Object?>{
            'queryType': <String, Object?>{'name': 'Query'},
          },
        },
      });
    });

    test('the executor is in the container', () {
      expect(Dox().ioc.has<GraphQLExecutor<DoxGraphQLContext>>(), isTrue);
    });
  });

  group('GraphiQL', () {
    test('a browser gets the page', () async {
      TestResponse res = await client.get('/api/graphql', headers: acceptHtml);
      res.expectStatus(200);
      expect(res.header('content-type'), startsWith('text/html'));
      expect(res.body, contains('graphiql@4.1.2'));
      expect(res.body, contains('integrity="sha384-'));
      expect(res.body, contains('url: "/api/graphql"'));
    });

    test('a browser GET with a query runs the query', () async {
      TestResponse res = await get(<String, String>{
        'query': '{ hello }',
      }, headers: acceptHtml);
      res.expectStatus(200);
      expect(res.json['data'], <String, Object?>{'hello': 'world'});
    });
  });
}
