import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dox_graphql_builder/dox_graphql_builder.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/// The real sources of the packages the test apps import, read once.
final Map<AssetId, List<int>> _packages = <AssetId, List<int>>{};

/// The libraries the test apps import. Every package they reach is
/// loaded.
const List<String> _roots = <String>[
  'package:dox_graphql/dox_graphql.dart',
  'package:dox_core/dox_core.dart',
  'package:dox_orm/dox_orm.dart',
  'package:dox_auth/dox_auth.dart',
];

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

Future<void> _load() async {
  if (_packages.isNotEmpty) return;
  PackageAssetReader reader = await PackageAssetReader.currentIsolate();
  Set<String> packages = <String>{};
  Set<AssetId> seen = <AssetId>{};
  List<AssetId> todo = <AssetId>[
    for (String uri in _roots) AssetId.resolve(Uri.parse(uri)),
  ];
  // follow the imports, to find the packages
  while (todo.isNotEmpty) {
    AssetId id = todo.removeLast();
    if (!seen.add(id) || !await reader.canRead(id)) continue;
    packages.add(id.package);
    String text = utf8.decode(await reader.readAsBytes(id));
    for (Match m in _directive.allMatches(text)) {
      Uri uri = Uri.parse(m[1]!);
      if (uri.scheme == 'dart') continue;
      todo.add(AssetId.resolve(uri, from: id));
    }
  }
  for (String package in packages) {
    await for (AssetId id in reader.findAssets(
      Glob('lib/**.dart'),
      package: package,
    )) {
      _packages[id] = await reader.readAsBytes(id);
    }
  }
}

/// The warnings of the last [generate].
final List<String> warnings = <String>[];

void _onLog(LogRecord record) {
  if (record.level == Level.WARNING) warnings.add(record.message);
}

/// Runs the builder on the files of package `a`. Gives the generated
/// file, `ERROR: ...` with the build errors, or `NONE` when no file was
/// written.
Future<String> generate(Map<String, String> app) async {
  await _load();
  warnings.clear();
  String output = 'NONE';
  Map<String, Object> sources = <String, Object>{
    for (MapEntry<AssetId, List<int>> e in _packages.entries)
      '${e.key.package}|${e.key.path}': e.value,
    for (MapEntry<String, String> e in app.entries) 'a|${e.key}': e.value,
  };
  TestBuilderResult result = await testBuilder(
    graphqlSchemaBuilder(BuilderOptions.empty),
    sources,
    rootPackage: 'a',
    isInput: _isApp,
    onLog: _onLog,
  );
  if (!result.succeeded) return 'ERROR: ${result.errors.join('\n')}';
  if (result.outputs.isEmpty) return output;
  await testBuilder(
    graphqlSchemaBuilder(BuilderOptions.empty),
    sources,
    rootPackage: 'a',
    isInput: _isApp,
    outputs: <String, Object>{
      // every package gets the empty schema: only the app counts
      for (String package in _packages.keys.map((AssetId id) => id.package))
        '$package|lib/generated/schema.g.dart': anything,
      'a|lib/generated/schema.g.dart': decodedMatches(
        predicate<String>((String s) {
          output = s;
          return true;
        }),
      ),
    },
  );
  return output;
}

bool _isApp(String id) => id.startsWith('a|');

/// [code] without white space and trailing commas, so formatting does not
/// matter.
String flat(String code) {
  return code
      .replaceAll(RegExp(r'\s'), '')
      .replaceAllMapped(RegExp(r',([)\]}])'), _closer)
      .replaceAll(RegExp(r',$'), '');
}

String _closer(Match m) => m[1]!;
