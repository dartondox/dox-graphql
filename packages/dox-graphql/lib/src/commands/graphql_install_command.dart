import 'dart:io';

import 'package:dox_annotation/command.dart';
import 'package:dox_annotation/install.dart';

/// `dox graphql:install [--no-orm]`. `dox add graphql` runs it. It sets up
/// GraphQL in an app: the packages, `lib/config/graphql.dart` and
/// `lib/providers/graphql_provider.dart`, then it runs build_runner. It
/// adds no resolver and changes no model. `--no-orm` leaves out
/// dox_graphql_orm, for an app that does not use models.
/// It never overwrites a file, so it is safe to run twice.
class GraphQLInstallCommand extends Command {
  /// [root] is the app folder (the current folder by default). [runner]
  /// runs `dart`, tests pass a fake one.
  GraphQLInstallCommand({this.root, this.runner});

  final Directory? root;
  final ProcessRunner? runner;

  @override
  String get name => 'graphql:install';

  @override
  String get description => 'Set up GraphQL in this app';

  @override
  String get usage => 'graphql:install [--no-orm]';

  @override
  Future<void> run(List<String> args) async {
    bool orm = !args.contains('--no-orm');
    if (args.any((String arg) => arg != '--no-orm')) {
      print('Unknown option. Use --no-orm to leave out dox_graphql_orm.');
      exitCode = 1;
      return;
    }
    Installer installer = Installer(root: root, runner: runner);
    String app = installer.appName;

    await installer.addDependency('dox_core');
    await installer.addDependency('dox_graphql');
    if (orm) await installer.addDependency('dox_graphql_orm');
    await installer.addDependency('dox_graphql_builder', dev: true);
    // dox_builder finds the provider, build_runner runs both builders
    await installer.addDependency('dox_builder', dev: true);
    await installer.addDependency('build_runner', dev: true);

    installer.writeFile('lib/config/graphql.dart', graphqlConfig(app));
    installer.writeFile(
      'lib/providers/graphql_provider.dart',
      graphqlProvider(app),
    );

    await installer.buildRunner();
    installer.printSummary(<String>[
      if (orm) ...<String>[
        'Add `@GraphQLType()` to a model. Add it to the models it relates '
            'to as well.',
        'Run `dart run build_runner build`.',
      ] else ...<String>[
        'Write a plain class and a resolver class with a `@GraphQLQuery()` '
            'method.',
        'Run `dart run build_runner build`.',
      ],
      'Start the app and open `/graphql`.',
    ]);
  }

  /// `lib/config/graphql.dart`
  static String graphqlConfig(String app) {
    return '''
import 'package:dox_graphql/dox_graphql.dart';
import 'package:$app/generated/schema.g.dart';

/// GraphQL settings
/// -------------------------------
/// `schema`: made by `dart run build_runner build` from your
/// `@GraphQLType`, `@GraphQLQuery` and `@GraphQLMutation` annotations.
/// `path`: the URL of the endpoint, `/graphql` by default.
/// `middleware`: run before the requests, for example an auth middleware.
GraphQLConfig graphqlConfig = GraphQLConfig(
  schema: graphqlSchema,
  // Without an auth middleware, every field of the API is public.
  // middleware: <Object>[AuthMiddleware()],
);
''';
  }

  /// `lib/providers/graphql_provider.dart`
  static String graphqlProvider(String app) {
    return '''
import 'package:dox_graphql/dox_graphql.dart';
import 'package:$app/config/graphql.dart';

/// GraphQL provider
/// --------------------------
/// Serves GraphQL at the path of the config.
/// If this project does not need GraphQL, delete this file
/// (Dox finds every DoxProvider class, see lib/generated/container.g.dart).
class AppGraphQLProvider extends GraphQLProvider {
  AppGraphQLProvider() : super(graphqlConfig);
}
''';
  }
}
