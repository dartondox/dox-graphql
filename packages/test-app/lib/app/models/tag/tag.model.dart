import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

part 'tag.model.g.dart';

@DoxModel(table: 'tags')
@GraphQLType(queries: false)
class Tag extends TagGenerator {
  @Column()
  String? name;
}
