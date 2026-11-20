import 'package:dox_core/dox_core.dart';
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/app/repositories/repositories.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'helper.dart';

void main() {
  late DoxTestClient client;

  setUpAll(() async {
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

  test('a query of a resolver, with plain class types', () async {
    Map<String, Object?> res = await run(
      client,
      '{ books(limit: 2) { id title genre shout publishedAt } }',
    );
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'books': <Object?>[
          <String, Object?>{
            'id': 1,
            'title': 'Dune',
            'genre': 'novel',
            'shout': 'DUNE',
            'publishedAt': null,
          },
          <String, Object?>{
            'id': 2,
            'title': 'Odes',
            'genre': 'poetry',
            'shout': 'ODES',
            'publishedAt': null,
          },
        ],
      },
    });
  });

  test('an argument with no default is required', () async {
    Map<String, Object?> res = await run(client, '{ book { id } }');
    expect(res['errors'], isNotEmpty);
    res = await run(client, '{ book(id: 3) { title } }');
    expect(res['data'], <String, Object?>{
      'book': <String, Object?>{'title': 'Emma'},
    });
  });

  test('an ignored field is not in the type', () async {
    Map<String, Object?> res = await run(client, '{ books { authorId } }');
    expect(res['errors'], isNotEmpty);
  });

  test('the context is given, not an argument', () async {
    Map<String, Object?> res = await run(
      client,
      '{ me }',
      headers: <String, String>{'x-user': 'ann'},
    );
    expect(res['data'], <String, Object?>{'me': 'ann'});
  });

  test('a @ResolveField with a DataLoader loads in one batch', () async {
    AuthorRepository authors = Dox().ioc.get<AuthorRepository>();
    authors.batches.clear();
    Map<String, Object?> res = await run(
      client,
      '{ books(limit: 3) { title author { name } } }',
    );
    expect(res['data'], <String, Object?>{
      'books': <Object?>[
        <String, Object?>{
          'title': 'Dune',
          'author': <String, Object?>{'name': 'author1'},
        },
        <String, Object?>{
          'title': 'Odes',
          'author': <String, Object?>{'name': 'author2'},
        },
        <String, Object?>{
          'title': 'Emma',
          'author': <String, Object?>{'name': 'author1'},
        },
      ],
    });
    expect(authors.batches, <List<int>>[
      <int>[1, 2],
    ]);
  });

  group('a @Mutation with a DTO |', () {
    test('runs the DTO rules first', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { createBook(input: {title: "No", authorId: 1}) { id } }',
      );
      expect(res['data'], null);
      expect(res['errors'], <Object?>[
        <String, Object?>{
          'message': 'Validation failed',
          'locations': <Object?>[
            <String, Object?>{'line': 1, 'column': 12},
          ],
          'path': <Object?>['createBook'],
          'extensions': <String, Object?>{
            'code': 'VALIDATION_FAILED',
            'fields': <String, Object?>{'title': 'The title is too short'},
          },
        },
      ]);
    });

    test('names a field with another key by its GraphQL name', () async {
      Map<String, Object?> res = await run(
        client,
        'mutation { createBook(input: {title: "Long title"}) { id } }',
      );
      List<Object?> errors = res['errors'] as List<Object?>;
      expect(
        ((errors.single as Map<String, Object?>)['extensions']
            as Map<String, Object?>)['fields'],
        <String, Object?>{'authorId': 'The author_id is required'},
      );
    });

    test('gives the DTO to the method', () async {
      Map<String, Object?> res = await run(
        client,
        r'mutation M($in: CreateBookInput!) { createBook(input: $in) '
        '{ title genre author { name } } }',
        variables: <String, Object?>{
          'in': <String, Object?>{
            'title': 'Ulysses',
            'authorId': 7,
            'genre': 'poetry',
          },
        },
      );
      expect(res['data'], <String, Object?>{
        'createBook': <String, Object?>{
          'title': 'Ulysses',
          'genre': 'poetry',
          'author': <String, Object?>{'name': 'author7'},
        },
      });
    });
  });
}
