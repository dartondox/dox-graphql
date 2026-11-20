import 'dart:io';

import 'package:dox_annotation/install.dart';
import 'package:dox_graphql/commands.dart';
import 'package:test/test.dart';

/// records the `dart` commands, runs nothing
class FakeRunner extends ProcessRunner {
  final List<String> calls = <String>[];

  @override
  Future<int> run(String executable, List<String> args, String folder) async {
    calls.add(args.join(' '));
    return 0;
  }
}

void main() {
  late Directory root;
  late FakeRunner runner;

  setUp(() {
    root = Directory.systemTemp.createTempSync('dox_graphql_install_');
    File(
      '${root.path}/pubspec.yaml',
    ).writeAsStringSync('name: my_app\n\ndependencies:\n  dox_core: ^3.2.0\n');
    runner = FakeRunner();
    exitCode = 0;
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  String read(String path) => File('${root.path}/$path').readAsStringSync();

  Future<void> install(List<String> args) {
    return GraphQLInstallCommand(root: root, runner: runner).run(args);
  }

  /// every file of the app and its text
  Map<String, String> snapshot() {
    Map<String, String> files = <String, String>{};
    for (FileSystemEntity f in root.listSync(recursive: true)) {
      if (f is File) files[f.path] = f.readAsStringSync();
    }
    return files;
  }

  test('is the command of dox add graphql', () {
    expect(commands.single.name, 'graphql:install');
  });

  test('adds the packages and writes the config and the provider', () async {
    await install(<String>[]);
    expect(exitCode, 0);
    expect(runner.calls, contains('pub add dox_graphql'));
    expect(runner.calls, contains('pub add dox_graphql_orm'));
    expect(runner.calls, contains('pub add --dev dox_graphql_builder'));
    expect(runner.calls, contains('pub add --dev dox_builder'));
    expect(runner.calls, contains('pub add --dev build_runner'));
    expect(runner.calls, isNot(contains('pub add dox_core')));
    expect(runner.calls.last, 'run build_runner build');
    expect(
      read('lib/config/graphql.dart'),
      allOf(
        contains("import 'package:my_app/generated/schema.g.dart';"),
        contains('GraphQLConfig(schema: graphqlSchema)'),
      ),
    );
    expect(
      read('lib/providers/graphql_provider.dart'),
      allOf(
        contains("import 'package:my_app/config/graphql.dart';"),
        contains('AppGraphQLProvider extends GraphQLProvider'),
        contains('super(graphqlConfig)'),
      ),
    );
    // no resolver and no model changes
    expect(Directory('${root.path}/lib/app').existsSync(), isFalse);
  });

  test('--no-orm leaves out dox_graphql_orm', () async {
    await install(<String>['--no-orm']);
    expect(exitCode, 0);
    expect(runner.calls, contains('pub add dox_graphql'));
    expect(runner.calls, isNot(contains('pub add dox_graphql_orm')));
    expect(runner.calls, contains('pub add --dev dox_graphql_builder'));
    expect(read('lib/config/graphql.dart'), contains('graphqlSchema'));
  });

  test('a second run changes nothing', () async {
    await install(<String>[]);
    File('${root.path}/lib/config/graphql.dart').writeAsStringSync('mine');
    Map<String, String> before = snapshot();
    await install(<String>[]);
    expect(snapshot(), before);
    expect(read('lib/config/graphql.dart'), 'mine');
  });

  test('a bad option stops with exit code 1 and writes nothing', () async {
    for (List<String> args in <List<String>>[
      <String>['--orm'],
      <String>['--no-orm', 'x'],
      <String>['graphql'],
    ]) {
      Map<String, String> before = snapshot();
      await install(args);
      expect(exitCode, 1, reason: '$args');
      expect(runner.calls, isEmpty, reason: '$args');
      expect(snapshot(), before, reason: '$args');
      exitCode = 0;
    }
  });
}
