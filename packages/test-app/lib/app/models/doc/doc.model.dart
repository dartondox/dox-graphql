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
}
