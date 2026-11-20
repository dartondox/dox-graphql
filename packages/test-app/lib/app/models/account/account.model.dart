import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../doc/doc.model.dart';

part 'account.model.g.dart';

/// `visibleFields` keeps only these fields. `docs` is a relation to a
/// model whose policy has `viewAny`.
@DoxModel(table: 'accounts')
@GraphQLType()
class Account extends AccountGenerator {
  @override
  List<String> get visibleFields => const <String>['id', 'name', 'docs'];

  @Column()
  String? name;

  @Column()
  String? email;

  @Column()
  String? secret;

  @HasMany(Doc)
  List<Doc>? docs;
}
