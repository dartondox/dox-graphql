import 'package:gql/ast.dart';
import 'package:source_span/source_span.dart';

/// A place in the query text. Line and column start at 1.
final class SourceLocation {
  const SourceLocation(this.line, this.column);

  final int line;
  final int column;

  Map<String, int> toJson() => <String, int>{'line': line, 'column': column};

  @override
  bool operator ==(Object other) =>
      other is SourceLocation && other.line == line && other.column == column;

  @override
  int get hashCode => Object.hash(line, column);

  @override
  String toString() => '$line:$column';
}

/// One step in the path of a response value.
sealed class PathSegment {
  const PathSegment();
}

/// A field name (or alias) in a response path.
final class PathKey extends PathSegment {
  const PathKey(this.key);

  final String key;

  @override
  bool operator ==(Object other) => other is PathKey && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

/// A list index in a response path.
final class PathIndex extends PathSegment {
  const PathIndex(this.index);

  final int index;

  @override
  bool operator ==(Object other) => other is PathIndex && other.index == index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => '$index';
}

/// An error in a GraphQL response.
///
/// Throw it from a resolver to send your own message and extensions.
/// Any other error a resolver throws is wrapped in a [GraphQLError] too,
/// and kept in [originalError].
class GraphQLError implements Exception {
  GraphQLError(
    this.message, {
    this.locations = const <SourceLocation>[],
    this.path,
    this.extensions,
    this.originalError,
    this.stackTrace,
  });

  /// An error that points at the given query nodes.
  GraphQLError.at(
    String message,
    List<Node> nodes, {
    Map<String, Object?>? extensions,
  }) : this(message, locations: locationsOf(nodes), extensions: extensions);

  final String message;
  final List<SourceLocation> locations;

  /// The path of the response field that failed. Null for errors that
  /// happen before execution (parse, validation, variables).
  final List<PathSegment>? path;

  /// Extra JSON data for the client, sent as `extensions`.
  final Map<String, Object?>? extensions;

  /// The error that the resolver threw, when it was not a [GraphQLError].
  /// Dart can throw any object, so this is not typed.
  final Object? originalError;
  final StackTrace? stackTrace;

  /// A copy with the given locations and path, when this error has none.
  GraphQLError locate(List<SourceLocation> locations, List<PathSegment> path) {
    return GraphQLError(
      message,
      locations: this.locations.isEmpty ? locations : this.locations,
      path: this.path ?? path,
      extensions: extensions,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  Map<String, Object?> toJson() {
    List<PathSegment>? path = this.path;
    return <String, Object?>{
      'message': message,
      if (locations.isNotEmpty)
        'locations': <Map<String, int>>[
          for (SourceLocation l in locations) l.toJson(),
        ],
      if (path != null)
        'path': <Object>[
          for (PathSegment s in path)
            switch (s) {
              PathKey(:String key) => key,
              PathIndex(:int index) => index,
            },
        ],
      if (extensions != null && extensions!.isNotEmpty)
        'extensions': extensions,
    };
  }

  @override
  String toString() => 'GraphQLError: $message';

  /// The locations of the given nodes in the query text.
  static List<SourceLocation> locationsOf(List<Node> nodes) {
    List<SourceLocation> out = <SourceLocation>[];
    for (Node node in nodes) {
      SourceLocation? l = locationOf(node);
      if (l != null) out.add(l);
    }
    return out;
  }

  /// The location of a node. The gql parser only keeps spans on names, so
  /// this uses the first name in the node.
  static SourceLocation? locationOf(Node node) {
    NameNode? name = _firstName(node);
    FileSpan? span = name?.span;
    if (span == null) return null;
    return SourceLocation(span.start.line + 1, span.start.column + 1);
  }

  static NameNode? _firstName(Node node) {
    return switch (node) {
      NameNode() => node,
      FieldNode() => node.alias ?? node.name,
      ArgumentNode() => node.name,
      FragmentSpreadNode() => node.name,
      FragmentDefinitionNode() => node.name,
      InlineFragmentNode() =>
        node.typeCondition?.on.name ?? _firstOf(node.selectionSet),
      OperationDefinitionNode() => node.name ?? _firstOf(node.selectionSet),
      VariableDefinitionNode() => node.variable.name,
      VariableNode() => node.name,
      DirectiveNode() => node.name,
      ObjectFieldNode() => node.name,
      EnumValueNode() => node.name,
      NamedTypeNode() => node.name,
      ListTypeNode() => _firstName(node.type),
      ListValueNode() =>
        node.values.isEmpty ? null : _firstName(node.values.first),
      ObjectValueNode() =>
        node.fields.isEmpty ? null : _firstName(node.fields.first),
      SelectionSetNode() => _firstOf(node),
      _ => null,
    };
  }

  static NameNode? _firstOf(SelectionSetNode set) =>
      set.selections.isEmpty ? null : _firstName(set.selections.first);
}

/// Thrown when a [Schema] is not valid. [problems] lists every problem.
class SchemaError implements Exception {
  SchemaError(this.problems);

  final List<String> problems;

  @override
  String toString() => 'SchemaError:\n  ${problems.join('\n  ')}';
}
