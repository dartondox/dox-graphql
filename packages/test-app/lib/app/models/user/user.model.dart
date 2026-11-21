import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../article/article.model.dart';
import '../post/post.model.dart';
import '../profile/profile.model.dart';

part 'user.model.g.dart';

/// Every field that gives a User needs a login, also `post.user`.
@DoxModel(table: 'users')
@GraphQLType(guard: true)
@GraphQLAll()
@GraphQLPaginate()
@GraphQLFind()
class User extends UserGenerator {
  @override
  List<String> get hidden => <String>['password'];

  @Column()
  String? name;

  @Column()
  String? password;

  @HasMany(Post)
  List<Post> posts = <Post>[];

  @HasOne(Profile)
  Profile? profile;

  @HasMany(Article)
  List<Article> articles = <Article>[];
}
