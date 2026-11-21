import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

part 'image.model.g.dart';

@DoxModel(table: 'images')
@GraphQL()
class Image extends ImageGenerator {
  @Column()
  String? url;

  @GraphQLIgnore()
  @Column()
  int? imageableId;

  @GraphQLIgnore()
  @Column()
  String? imageableType;
}
