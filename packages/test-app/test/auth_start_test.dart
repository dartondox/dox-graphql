import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/generated/schema.g.dart';
import 'package:test/test.dart';

import 'helper.dart';

void main() {
  test('auth: true with no auth middleware fails at start', () async {
    await expectLater(
      startApp(GraphQLConfig(schema: graphqlSchema)),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('has auth: true, but GraphQLConfig.middleware has no auth'),
        ),
      ),
    );
  });
}
