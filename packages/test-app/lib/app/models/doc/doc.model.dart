import 'package:dox_auth/dox_auth.dart' show Ability;
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../../dtos/doc_dto.dart';

part 'doc.model.g.dart';

/// Its policy (DocPolicy) has every ability. The lists and the relations
/// to Doc drop the rows that `view` denies. Find, update and delete need
/// a login, so a guest is stopped before the row lookup.
@DoxModel(table: 'docs')
@GraphQL(filter: Ability.view)
@GraphQLAll(can: Ability.viewAny)
@GraphQLPaginate(can: Ability.viewAny)
@GraphQLFind(can: Ability.view, guard: true)
@GraphQLCreate(dto: DocDto, can: Ability.create)
@GraphQLUpdate(dto: DocDto, can: Ability.update, guard: true)
@GraphQLDelete(can: Ability.delete, guard: true)
class Doc extends DocGenerator {
  @Column()
  String? title;

  @Column()
  String? owner;

  @Column()
  int? accountId;

  @Column()
  int? parentId;

  /// A single relation to a model with `filter:`. It is not
  /// nullable in Dart: only the field can be null, not the parent.
  @BelongsTo(Doc, foreignKey: 'parent_id')
  late Doc parent;

  /// The doc whose parent this one is: a HasOne relation.
  @HasOne(Doc, foreignKey: 'parent_id')
  Doc? child;
}
