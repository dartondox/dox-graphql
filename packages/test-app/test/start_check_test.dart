import 'package:dox_auth/dox_auth.dart' show Ability, Gate, Policy;
import 'package:dox_core/testing.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/app/models/article/article.model.dart';
import 'package:dox_graphql_test_app/app/models/doc/doc.model.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'db.dart';
import 'helper.dart';

/// A policy of Doc with a typo: `veiw`, not `view`.
class TypoDocPolicy extends Policy<String, Doc> {
  bool yes(String user, [Doc? doc]) => true;

  @override
  Map<String, Function> get abilities => <String, Function>{
    Ability.viewAny: yes,
    'veiw': yes,
    Ability.create: yes,
    Ability.update: yes,
    Ability.delete: yes,
  };
}

/// When the app starts, every `can:` and `filter:` of the schema must be
/// an ability of the policy of its model, or a `Gate.define`.
void main() {
  GraphQLConfig config = GraphQLConfig(
    schema: graphqlSchema,
    middleware: <Object>[const FakeAuthMiddleware()],
  );

  setUpAll(setUpDatabase);
  tearDown(Gate.flush);

  Matcher stateError(String message) => throwsA(
    isA<StateError>().having((StateError e) => e.message, 'message', message),
  );

  test('a policy without the ability stops the start', () async {
    registerPolicies();
    Gate.policy<Doc>(TypoDocPolicy());
    await expectLater(
      startApp(config, policies: false),
      stateError(
        "@GraphQLType(filter: 'view') on Doc: TypoDocPolicy has no ability "
        "'view'. Available: viewAny, veiw, create, update, delete.",
      ),
    );
  });

  test('a model with no policy stops the start', () async {
    registerPolicies();
    Gate.flush();
    await expectLater(
      startApp(config, policies: false),
      stateError(
        "@GraphQLUpdate(can: 'update') on Article: Article has no policy and "
        "there is no Gate.define('update'). Register the policy with "
        'Gate.policy<Article>(...) in the setup() of a provider: the check '
        'runs in GraphQLProvider.boot(), after every setup().',
      ),
    );
  });

  test('a Gate.define does not hide a typo in a policy', () async {
    registerPolicies();
    Gate.policy<Doc>(TypoDocPolicy());
    Gate.define(Ability.view, (String user, Doc doc) => true);
    await expectLater(
      startApp(config, policies: false),
      stateError(
        "@GraphQLType(filter: 'view') on Doc: TypoDocPolicy has no ability "
        "'view'. Available: viewAny, veiw, create, update, delete.",
      ),
    );
  });

  test('a model with no policy may use a Gate.define', () async {
    // every policy but the one of Article, which uses update and delete
    registerPolicies(article: false);
    Gate.define(Ability.update, (String user, Article a) => true);
    Gate.define(Ability.delete, (String user, Article a) => true);
    DoxTestClient client = await startApp(config, policies: false);
    await client.close();
  });
}
