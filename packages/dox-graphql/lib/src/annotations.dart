/// The annotations that `dox_graphql_builder` reads. The builder writes
/// `lib/generated/schema.g.dart` with `graphqlSchema` from them.
library;

/// Makes a GraphQL object type from a class.
///
/// On a model of dox_orm, the columns, `id` and the relations become
/// fields, and the model gets a list and a find query. On a plain Dart
/// class, the public fields become fields.
///
/// ```dart
/// @DoxModel()
/// @GraphQLType(dto: CreatePostDto)
/// class Post extends PostGenerator {}
/// ```
class GraphQLType {
  const GraphQLType({
    this.name,
    this.description,
    this.queries = true,
    this.dto,
  });

  /// The type name. Default: the class name.
  final String? name;

  /// The description, shown in GraphiQL. Default: the `///` comment of
  /// the class.
  final String? description;

  /// Models only: the list and find queries, like `posts` and `post`.
  /// False leaves them out, so the model is only reachable through
  /// relations and custom resolvers.
  final bool queries;

  /// Models only: a `@Dto` class. With it, the model gets the create,
  /// update and delete mutations, and a client can set only the fields
  /// of the DTO.
  final Type? dto;
}

/// Leaves a field out of the GraphQL type.
class GraphQLIgnore {
  const GraphQLIgnore();
}

/// Makes a getter a field of the GraphQL type: a computed field. On a
/// field, it sets another name or a description.
class GraphQLField {
  const GraphQLField({this.name, this.description, this.deprecationReason});

  /// The field name. Default: the Dart name.
  final String? name;
  final String? description;

  /// Marks the field as deprecated, with this reason.
  final String? deprecationReason;
}

/// Makes a method a root query field. The method name is the field name,
/// the parameters are the arguments, and the return type is the field
/// type.
///
/// It is not named `Query`: dox_core and dox_orm export a `Query`
/// annotation for OpenAPI, and a resolver file often imports them too.
class GraphQLQuery {
  const GraphQLQuery({this.name, this.description, this.deprecationReason});

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;
}

/// Makes a method a root mutation field. Take the input as a `@Dto`
/// class: its rules run before the method.
class GraphQLMutation {
  const GraphQLMutation({this.name, this.description, this.deprecationReason});

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;
}

/// Adds a field to the GraphQL type of the first parameter of the
/// method. The first parameter is the parent value.
///
/// ```dart
/// @ResolveField()
/// Future<User?> author(Post post, DoxGraphQLContext context) { ... }
/// ```
class ResolveField {
  const ResolveField({this.name, this.description, this.deprecationReason});

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;
}
