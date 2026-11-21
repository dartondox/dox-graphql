import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

/// Note has `filter: Ability.view`, and NotePolicy denies the note with
/// the title `hidden`. The filter is a rule of the type: every field that
/// gives a Note runs it, not only the generated ones. The user of
/// NotePolicy is a `User?`, so the requests run as a guest.
void main() {
  late DoxTestClient client;

  setUpAll(() async {
    await setUpDatabase();
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

  test('a @GraphQLField getter of a model', () async {
    Map<String, Object?> res = await run(
      client,
      '{ posts { title titleNote { title } } }',
      user: null,
    );
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'posts': <Object?>[
          <String, Object?>{
            'title': 'Hello GraphQL',
            'titleNote': <String, Object?>{'title': 'Hello GraphQL'},
          },
          <String, Object?>{'title': 'Second', 'titleNote': null},
          <String, Object?>{
            'title': 'Third',
            'titleNote': <String, Object?>{'title': 'Third'},
          },
        ],
      },
    });
  });

  test('the fields of a plain class', () async {
    Map<String, Object?> res = await run(
      client,
      '{ noteBox { first { title } notes { title } } }',
      user: null,
    );
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'noteBox': <String, Object?>{
          'first': null,
          'notes': <Object?>[
            <String, Object?>{'title': 'kept'},
          ],
        },
      },
    });
  });

  test('a custom @GraphQLQuery', () async {
    Map<String, Object?> res = await run(
      client,
      '{ madeNotes { title } hiddenNote { title } }',
      user: null,
    );
    expect(res, <String, Object?>{
      'data': <String, Object?>{
        'madeNotes': <Object?>[
          <String, Object?>{'title': 'kept'},
        ],
        'hiddenNote': null,
      },
    });
  });
}
