import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../../dtos/doc_dto.dart';
import '../../policies/doc_policy.dart';

part 'doc.model.g.dart';

/// Its policy has `viewAny`, `view` and `create`: the reads and the create
/// ask it too.
@DoxModel(table: 'docs')
@GraphQLType(dto: DocDto, policy: DocPolicy, auth: false)
class Doc extends DocGenerator {
  @Column()
  String? title;

  @Column()
  String? owner;

  @Column()
  int? accountId;

  @Column()
  int? parentId;

  /// A single relation to a model whose policy has `view`.
  @BelongsTo(Doc, foreignKey: 'parent_id')
  Doc? parent;

  /// The doc whose parent this one is: a HasOne relation.
  @HasOne(Doc, foreignKey: 'parent_id')
  Doc? child;
}
