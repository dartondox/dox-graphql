import 'package:dox_auth/dox_auth.dart' show Ability, Gate, Policy;
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/app/models/doc/doc.model.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

/// A policy of Doc whose `view` reads the `late` field `parent` when the
/// doc has no owner. The blank row of a missing id has no owner and no
/// parent set.
class LateDocPolicy extends Policy<String, Doc> {
  bool yes(String user, [Doc? doc]) => true;

  bool view(String user, Doc doc) {
    if (doc.owner != null) return doc.owner == user;
    return doc.parent.owner == user;
  }

  /// A blank row has no title: `int.parse('')` throws a FormatException.
  bool update(String user, Doc doc) {
    if (doc.owner != null) return doc.owner == user;
    return int.parse(doc.title ?? '') > 0;
  }

  /// A blank row has no owner: the empty list throws a RangeError.
  bool delete(String user, Doc doc) {
    if (doc.owner != null) return doc.owner == user;
    return <String>[][0] == user;
  }

  @override
  Map<String, Function> get abilities => <String, Function>{
    Ability.viewAny: yes,
    Ability.view: view,
    Ability.create: yes,
    Ability.update: update,
    Ability.delete: delete,
  };
}

/// The `can:` check of a missing id reads a blank row. A policy that
/// throws on it (an unset `late` field, a FormatException, a RangeError)
/// denies, so a missing id gets the same answer as an id the user may not
/// see.
void main() {
  late DoxTestClient client;

  setUpAll(() async {
    await setUpDatabase();
    registerPolicies();
    Gate.policy<Doc>(LateDocPolicy());
    client = await startApp(
      GraphQLConfig(
        schema: graphqlSchema,
        middleware: <Object>[const FakeAuthMiddleware()],
      ),
      policies: false,
    );
  });

  tearDownAll(() async {
    await client.close();
  });

  test('a missing id and a denied id give the same answer', () async {
    Map<String, Object?> denied = await run(
      client,
      '{ doc(id: "2") { title } }',
      user: 'ann',
    );
    Map<String, Object?> missing = await run(
      client,
      '{ doc(id: "99999") { title } }',
      user: 'ann',
    );
    expect(denied['data'], <String, Object?>{'doc': null});
    expect(
      (((denied['errors'] as List<Object?>).single
              as Map<String, Object?>)['extensions']
          as Map<String, Object?>)['code'],
      'FORBIDDEN',
    );
    expect(missing, denied);
  });
  test('a policy that throws on the blank row denies', () async {
    for (String q in <String>[
      'mutation { updateDoc(id: "ID", input: {title: "x"}) { id } }',
      'mutation { deleteDoc(id: "ID") }',
    ]) {
      Map<String, Object?> denied = await run(
        client,
        q.replaceAll('ID', '2'),
        user: 'ann',
      );
      Map<String, Object?> missing = await run(
        client,
        q.replaceAll('ID', '99999'),
        user: 'ann',
      );
      expect(
        (((denied['errors'] as List<Object?>).single
                as Map<String, Object?>)['extensions']
            as Map<String, Object?>)['code'],
        'FORBIDDEN',
        reason: q,
      );
      expect(missing, denied, reason: q);
    }
  });
}
