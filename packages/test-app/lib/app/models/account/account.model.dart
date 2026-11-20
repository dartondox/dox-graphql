import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

part 'account.model.g.dart';

/// `visibleFields` keeps only these fields.
@DoxModel(table: 'accounts')
@GraphQLType()
class Account extends AccountGenerator {
  @override
  List<String> get visibleFields => const <String>['id', 'name'];

  @Column()
  String? name;

  @Column()
  String? email;

  @Column()
  String? secret;
}
