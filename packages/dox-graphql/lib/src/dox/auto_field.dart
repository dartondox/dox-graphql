import '../schema.dart';
import '../types.dart';

/// A root field that `dox_graphql_builder` made for a model: the list and
/// find queries, and the create, update and delete mutations.
/// `GraphQLConfig(autoResolvers: false)` leaves these fields out.
class AutoField<S, C> extends Field<S, C> {
  AutoField(
    super.name,
    super.type, {
    super.description,
    super.args,
    super.deprecationReason,
    super.resolve,
    super.auth,
  });

  /// [schema] without the [AutoField]s of its query and mutation roots.
  /// The other types stay. A mutation root with no field left is dropped.
  static GraphQLSchema<C> leaveOut<C>(GraphQLSchema<C> schema) {
    ObjectType<Object?, C> query = schema.query;
    ObjectType<Object?, C>? mutation = schema.mutation;
    ObjectType<Object?, C>? newMutation;
    if (mutation != null && mutation.fields.any(_isCustom<C>)) {
      newMutation = _without(mutation);
    }
    return GraphQLSchema<C>(
      query: _without(query),
      mutation: newMutation,
      description: schema.description,
      types: <NamedType>[
        for (NamedType t in schema.typeMap.values)
          if (!identical(t, query) &&
              !identical(t, mutation) &&
              !t.name.startsWith('__'))
            t,
      ],
    );
  }

  static bool _isCustom<C>(Field<Object?, C> field) => field is! AutoField;

  static ObjectType<Object?, C> _without<C>(ObjectType<Object?, C> root) {
    return ObjectType<Object?, C>(
      root.name,
      description: root.description,
      fields: () => root.fields.where(_isCustom<C>).toList(),
    );
  }
}
