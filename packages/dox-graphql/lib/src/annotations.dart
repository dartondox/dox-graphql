/// The annotations that `dox_graphql_builder` reads. The builder writes
/// `lib/generated/schema.g.dart` with `graphqlSchema` from them.
///
/// A model shows what it gives in its annotations. A query or mutation
/// exists only when its annotation is there:
///
/// ```dart
/// @DoxModel(table: 'posts')
/// @GraphQLType(filter: Ability.view)
/// @GraphQLAll(can: Ability.viewAny)
/// @GraphQLFind(can: Ability.view)
/// @GraphQLCreate(dto: PostInput, can: Ability.create, guard: true, owner: 'userId')
/// @GraphQLUpdate(dto: PostInput, can: Ability.update, guard: true)
/// @GraphQLDelete(can: Ability.delete, guard: true)
/// class Post extends PostGenerator {}
/// ```
///
/// `can:` is an ability of the policy of the model (or of
/// `Gate.define`). The generated resolver asks `Gate.allows` before it
/// gives or writes data. A denied guest gets "Unauthenticated", a denied
/// user "Forbidden". With no `can:`, nothing is asked.
///
/// `guard: true` needs a logged-in user. The default is public.
///
/// When the app starts, every `can:` and `filter:` is checked: an
/// ability that the policy of the model does not have (a typo) stops the
/// start with an error.
library;

/// Makes a GraphQL object type from a class.
///
/// On a model of dox_orm, the columns, `id` and the relations become
/// fields. On a plain Dart class, the public fields become fields. The
/// type gets no query by itself: add `@GraphQLAll`, `@GraphQLFind` and
/// the other operation annotations to a model.
class GraphQLType {
  const GraphQLType({
    this.name,
    this.description,
    this.guard = false,
    this.filter,
  });

  /// The type name. Default: the class name.
  final String? name;

  /// The description, shown in GraphiQL. Default: the `///` comment of
  /// the class.
  final String? description;

  /// True: every field that gives this type needs a logged-in user: the
  /// queries, the relations and the custom resolvers too. Also an
  /// interface or union field that picks this type for its value.
  final bool guard;

  /// Models only: an ability, like `Ability.view`. The lists
  /// (`@GraphQLAll`, `@GraphQLPaginate`) and the relations to this model
  /// leave out each row that `Gate.allows(user, filter, row)` denies, with
  /// no error. A single relation gives null. So a list can have fewer
  /// rows than its limit. A hand-written resolver that gives the model
  /// does not filter.
  final String? filter;
}

/// The list query of a model: `posts(limit: Int = 20, offset: Int = 0)`.
/// A `limit` above 100 is an error.
class GraphQLAll {
  const GraphQLAll({this.name, this.description, this.can, this.guard = false});

  /// The field name. Default: the plural of the type name, like `posts`.
  final String? name;
  final String? description;

  /// The ability to ask on the model type, like `Ability.viewAny`, before
  /// the query runs.
  final String? can;

  /// True: the query needs a logged-in user.
  final bool guard;
}

/// The paged list query of a model:
/// `posts(first: Int = 20, page: Int = 1): PostPaginator`, with `data`
/// and `paginatorInfo`. A `first` above 100 is an error.
///
/// The field name is the plural of the type name, like `posts`. When the
/// model has `@GraphQLAll` too, it is `postsPaginate`.
class GraphQLPaginate {
  const GraphQLPaginate({
    this.name,
    this.description,
    this.can,
    this.guard = false,
  });

  /// The field name. Default: see the class.
  final String? name;
  final String? description;

  /// The ability to ask on the model type, like `Ability.viewAny`, before
  /// the query runs.
  final String? can;

  /// True: the query needs a logged-in user.
  final bool guard;
}

/// The find query of a model: `post(id: ID!)`. A missing id gives null.
class GraphQLFind {
  const GraphQLFind({
    this.name,
    this.description,
    this.can,
    this.guard = false,
  });

  /// The field name. Default: the type name, like `post`.
  final String? name;
  final String? description;

  /// The ability to ask on the row, like `Ability.view`. A missing id is
  /// asked as a blank row, so a denied user gets the same error for an id
  /// that exists and one that does not.
  final String? can;

  /// True: the query needs a logged-in user.
  final bool guard;
}

/// The create mutation of a model: `createPost(input: CreatePostInput!)`.
/// The input is the `@Dto` class [dto]: its rules run before the save,
/// and a client can set only its fields.
class GraphQLCreate {
  const GraphQLCreate({
    required this.dto,
    this.name,
    this.description,
    this.can,
    this.guard = false,
    this.owner,
  });

  /// A `@Dto` class. Its fields must be columns of the model.
  final Type dto;

  /// The field name. Default: `create` and the type name.
  final String? name;
  final String? description;

  /// The ability to ask on the model type, like `Ability.create`, before
  /// the input is read.
  final String? can;

  /// True: the mutation needs a logged-in user.
  final bool guard;

  /// The column of the owner, like `'userId'`. The mutation sets it to
  /// the id of the logged-in user, so it needs a login. The column must
  /// not be a field of [dto]. `@GraphQLUpdate` never changes it.
  final String? owner;
}

/// The update mutation of a model:
/// `updatePost(id: ID!, input: UpdatePostInput!)`. It sets only the
/// fields that the client sends. A missing id gives null.
///
/// Without [can], anyone who may call it can change any row.
class GraphQLUpdate {
  const GraphQLUpdate({
    required this.dto,
    this.name,
    this.description,
    this.can,
    this.guard = false,
  });

  /// A `@Dto` class. Its fields must be columns of the model.
  final Type dto;

  /// The field name. Default: `update` and the type name.
  final String? name;
  final String? description;

  /// The ability to ask on the row, like `Ability.update`, before the
  /// write. A missing id is asked as a blank row.
  final String? can;

  /// True: the mutation needs a logged-in user.
  final bool guard;
}

/// The delete mutation of a model: `deletePost(id: ID!): Boolean`. False
/// for a missing id.
///
/// Without [can], anyone who may call it can delete any row.
class GraphQLDelete {
  const GraphQLDelete({
    this.name,
    this.description,
    this.can,
    this.guard = false,
  });

  /// The field name. Default: `delete` and the type name.
  final String? name;
  final String? description;

  /// The ability to ask on the row, like `Ability.delete`, before the
  /// delete. A missing id is asked as a blank row.
  final String? can;

  /// True: the mutation needs a logged-in user.
  final bool guard;
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
    this.guard = false,
  });

  /// The field name. Default: the Dart name.
  final String? name;
  final String? description;

  /// Marks the field as deprecated, with this reason.
  final String? deprecationReason;

  /// True: the field needs a logged-in user.
  final bool guard;
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
    this.guard = false,
  });

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;

  /// True: the field needs a logged-in user.
  final bool guard;
}

/// Makes a method a root mutation field. Take the input as a `@Dto`
/// class: its rules run before the method.
class GraphQLMutation {
  const GraphQLMutation({
    this.name,
    this.description,
    this.deprecationReason,
    this.guard = false,
  });

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;

  /// True: the field needs a logged-in user.
  final bool guard;
}

/// Adds a field to the GraphQL type of the first parameter of the
/// method. The first parameter is the parent value.
///
/// ```dart
/// @GraphQLResolveField()
/// Future<User?> author(Post post, DoxGraphQLContext context) { ... }
/// ```
class GraphQLResolveField {
  const GraphQLResolveField({
    this.name,
    this.description,
    this.deprecationReason,
    this.guard = false,
  });

  /// The field name. Default: the method name.
  final String? name;
  final String? description;
  final String? deprecationReason;

  /// True: the field needs a logged-in user.
  final bool guard;
}
