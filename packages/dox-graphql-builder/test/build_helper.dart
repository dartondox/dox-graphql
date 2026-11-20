import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dox_graphql_builder/dox_graphql_builder.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

/// The real sources of the packages the test apps import, read once.
final Map<AssetId, List<int>> _packages = <AssetId, List<int>>{};

/// The packages a test app can import.
const List<String> _wanted = <String>[
  'dox_graphql',
  'dox_core',
  'dox_annotation',
  'dox_validation',
  'dox_cache',
  'dox_http_native',
  'dox_openapi',
  'gql',
  'meta',
  'source_span',
  'collection',
  'path',
  'term_glyph',
  'crypto',
  'typed_data',
  'mime',
  'string_scanner',
  'uuid',
  'bcrypt',
  'matcher',
  'stack_trace',
  'ffi',
  'hooks',
  'code_assets',
  'logging',
  'pub_semver',
  'yaml',
  'fixnum',
  'random_x',
];

Future<void> _load() async {
  if (_packages.isNotEmpty) return;
  PackageAssetReader reader = await PackageAssetReader.currentIsolate();
  for (String package in _wanted) {
    if (reader.packageConfig[package] == null) continue;
    await for (AssetId id in reader.findAssets(
      Glob('lib/**.dart'),
      package: package,
    )) {
      _packages[id] = await reader.readAsBytes(id);
    }
  }
}

/// Runs the builder on the files of package `a`. Gives the generated
/// file, `ERROR: ...` with the build errors, or `NONE` when no file was
/// written.
Future<String> generate(Map<String, String> app) async {
  await _load();
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
  );
  if (!result.succeeded) return 'ERROR: ${result.errors.join('\n')}';
  if (result.outputs.isEmpty) return output;
  await testBuilder(
    graphqlSchemaBuilder(BuilderOptions.empty),
    sources,
    rootPackage: 'a',
    isInput: _isApp,
    outputs: <String, Object>{
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
