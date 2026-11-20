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
    this.auth,
    this.policy,
    this.owner,
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

  /// Models only: a `@Dto` class. With it, the model gets the create
  /// mutation (and with [policy] the update and delete mutations), and a
  /// client can set only the fields of the DTO.
  final Type? dto;

  /// True: every field that gives this type needs a logged-in user:
  /// the model queries, relations and custom resolvers too. False: those
  /// fields are public. Null (default): they need a login only when
  /// `GraphQLConfig.middleware` has the auth middleware. On a model, it
  /// also sets the login rule of the delete mutation.
  final bool? auth;

  /// Models only: a `Policy` of dox_auth for the model, like `PostPolicy`.
  /// With it and [dto], the model gets the update and delete mutations.
  /// They load the row and ask the policy (`update`, `delete`) before
  /// they write. A denied write fails with "Forbidden" (code
  /// `FORBIDDEN`). Register the policy with `Gate.policy<Post>(...)` as
  /// usual. Without it, the model gets only the create mutation.
  ///
  /// When the registered policy lists the ability `viewAny`, `view` or
  /// `create` in `abilities` (checked at run time with
  /// `Gate.hasAbility`), the list query asks `viewAny`, the find query asks `view`,
  /// a relation to the model asks `viewAny`, and the create mutation asks
  /// `create`. The list query and the relations drop the rows that `view`
  /// denies, so a list can have fewer rows than `limit`. A
  /// denied guest gets "Unauthenticated", a denied user "Forbidden". A
  /// missing id is checked as a blank row, so a denied user gets the same
  /// error for an id that exists and one that does not.
  ///
  /// Only the generated fields and relations run these checks. A
  /// hand-written `@GraphQLQuery`, `@ResolveField` or plain-class getter
  /// that gives a model must call `Gate` itself.
  final Type? policy;

  /// Models only: the column of the owner, like `'userId'`. The create
  /// mutation sets it to the id of the logged-in user, so a client can
  /// not send or change it. It is not in the input, and the update
  /// mutation never changes it. Create then always needs a login, even
  /// with `auth: false`. It needs [dto], and the column must not be a
  /// field of the DTO.
  ///
  /// ```dart
  /// @GraphQLType(dto: CreatePostDto, owner: 'userId')
  /// ```
  final String? owner;
}

/// Leaves a field out of the GraphQL type.
class GraphQLIgnore {
  const GraphQLIgnore();
}

/// Makes a getter a field of the GraphQL type: a computed field. On a
/// field, it sets another name or a description.
class GraphQLField {
  const GraphQLField({
    this.name,
    this.description,
    this.deprecationReason,
    this.auth,
  });

  /// The field name. Default: the Dart name.
  final String? name;
  final String? description;

  /// Marks the field as deprecated, with this reason.
  final String? deprecationReason;

  /// The default of a field of this type is public, so only true
  /// matters: the field needs a logged-in user, even when the root field
  /// above it is public.
  final bool? auth;
}

/// Makes a method a root query field. The method name is the field name,
/// the parameters are the arguments, and the return type is the field
/// type.
///
/// It is not named `Query`: dox_core and dox_orm export a `Query`
/// annotation for OpenAPI, and a resolver file often imports them too.
class GraphQLQuery {
  const GraphQLQuery({
    this.name,
    this.description,
    this.deprecationReason,
    this.auth,
  });

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;

  /// True: the field needs a logged-in user. False: the field is public.
  /// Null (default): it needs a login only when `GraphQLConfig.middleware`
  /// has the auth middleware.
  final bool? auth;
}

/// Makes a method a root mutation field. Take the input as a `@Dto`
/// class: its rules run before the method.
class GraphQLMutation {
  const GraphQLMutation({
    this.name,
    this.description,
    this.deprecationReason,
    this.auth,
  });

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;

  /// True: the field needs a logged-in user. False: the field is public.
  /// Null (default): it needs a login only when `GraphQLConfig.middleware`
  /// has the auth middleware.
  final bool? auth;
}

/// Adds a field to the GraphQL type of the first parameter of the
/// method. The first parameter is the parent value.
///
/// ```dart
/// @ResolveField()
/// Future<User?> author(Post post, DoxGraphQLContext context) { ... }
/// ```
class ResolveField {
  const ResolveField({
    this.name,
    this.description,
    this.deprecationReason,
    this.auth,
  });

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;

  /// The default of a field of this type is public, so only true
  /// matters: the field needs a logged-in user, even when the root field
  /// above it is public.
  final bool? auth;
}
