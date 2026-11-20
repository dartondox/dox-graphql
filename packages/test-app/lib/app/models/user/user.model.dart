import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../post/post.model.dart';

part 'user.model.g.dart';

@DoxModel(table: 'users')
@GraphQLType()
class User extends UserGenerator {
  @override
  List<String> get hidden => <String>['password'];

  @Column()
  String? name;

  @Column()
  String? password;

  @HasMany(Post)
  List<Post> posts = <Post>[];
}
