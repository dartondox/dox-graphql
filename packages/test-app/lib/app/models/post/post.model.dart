import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../../dtos/create_post.dart';
import '../comment/comment.model.dart';
import '../user/user.model.dart';

part 'post.model.g.dart';

enum PostStatus { draft, published }

@DoxModel(table: 'posts')
@GraphQLType(dto: CreatePostDto)
class Post extends PostGenerator {
  @override
  List<String> get fillable => <String>['title', 'body', 'user_id'];

  @Column()
  String? title;

  @Column()
  String? body;

  @Column()
  int? userId;

  @Column()
  PostStatus? status;

  @GraphQLIgnore()
  @Column()
  String? internalNote;

  @BelongsTo(User)
  User? user;

  @HasMany(Comment)
  List<Comment> comments = <Comment>[];

  /// The first 5 letters of the body.
  @GraphQLField()
  String get excerpt {
    String text = body ?? '';
    return text.length <= 5 ? text : text.substring(0, 5);
  }
}
