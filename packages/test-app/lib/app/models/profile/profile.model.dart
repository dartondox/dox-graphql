import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

part 'profile.model.g.dart';

@DoxModel(table: 'profiles')
@GraphQLType()
class Profile extends ProfileGenerator {
  @Column()
  String? bio;

  @Column()
  int? userId;

  @Column()
  int? memberId;
}
