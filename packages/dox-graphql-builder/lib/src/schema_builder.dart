import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';

import 'schema_model.dart';
import 'schema_reader.dart';
import 'schema_writer.dart';

/// Writes `lib/generated/schema.g.dart` with `graphqlSchema`: the GraphQL
/// schema of the app. Give it to `GraphQLConfig(schema: graphqlSchema)`.
///
/// It reads every library in `lib/` and finds:
/// - classes with `@GraphQLType()`: the object types,
/// - classes with `@GraphQLQuery()`, `@GraphQLMutation()` or `@ResolveField()` methods:
///   the resolvers.
///
/// A type that GraphQL can not show stops the build with an error that
/// names the class and the member. When the package has none of these
/// classes, the schema has one placeholder query, so it is still valid.
class GraphQLSchemaBuilder implements Builder {
  const GraphQLSchemaBuilder();

  static const String output = 'lib/generated/schema.g.dart';

  @override
  Map<String, List<String>> get buildExtensions {
    return const <String, List<String>>{
      r'$lib$': <String>['generated/schema.g.dart'],
    };
  }

  /// A library with none of these words has no GraphQL class.
  static const List<String> _words = <String>[
    'graphql',
    'query',
    'mutation',
    'resolvefield',
  ];

  @override
  Future<void> build(BuildStep buildStep) async {
    Resolver resolver = buildStep.resolver;
    List<ClassElement> types = <ClassElement>[];
    List<ClassElement> resolvers = <ClassElement>[];
    List<AssetId> ids = await buildStep
        .findAssets(Glob('lib/**.dart'))
        .toList();
    ids.sort(_byPath);
    for (AssetId id in ids) {
      // files that a builder made, like lib/generated/
      if (id.path.endsWith('.g.dart')) continue;
      // resolving is slow: first a quick look at the text
      String text = (await buildStep.readAsString(id)).toLowerCase();
      if (!_words.any(text.contains)) continue;
      if (!await resolver.isLibrary(id)) continue;
      LibraryElement library = await resolver.libraryFor(id);
      for (ClassElement element in library.classes) {
        if (SchemaReader.annotation(element, 'GraphQLType') != null) {
          types.add(element);
        }
        if (SchemaReader.isResolver(element)) resolvers.add(element);
      }
    }

    SchemaReader reader = SchemaReader(Imports());
    if (types.isEmpty && resolvers.isEmpty) {
      // The app has nothing yet (`dox add graphql` just ran). A schema needs
      // one query field, so it gets a placeholder. It goes away with the
      // first real query.
      reader.query.add(_placeholder);
    }
    for (ClassElement element in types) {
      reader.addType(element);
    }
    reader.readTypes();
    for (ClassElement element in resolvers) {
      reader.readResolver(element);
    }
    if (reader.query.isEmpty) {
      throw StateError(
        'The GraphQL schema has no query. Add @GraphQLQuery() to a method of a '
        'resolver class.',
      );
    }
    String code = SchemaWriter(reader).write();
    DartFormatter formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, output),
      formatter.format(code),
    );
  }

  static final FieldSpec _placeholder = FieldSpec(
    name: 'placeholder',
    type: 'graphqlBoolean.nonNull',
    resolve: 'true',
    where: 'Query.placeholder',
    description:
        'A placeholder, there is no other query yet. Add @GraphQLQuery() '
        'to a method or @GraphQLType() to a model, then run the builder.',
  );

  static int _byPath(AssetId a, AssetId b) => a.path.compareTo(b.path);
}
