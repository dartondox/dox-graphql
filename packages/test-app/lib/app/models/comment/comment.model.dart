import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../post/post.model.dart';

part 'comment.model.g.dart';

/// Only reachable through `post.comments`.
@DoxModel(table: 'comments')
@GraphQLType(queries: false)
class Comment extends CommentGenerator {
  @Column()
  String? body;

  @Column()
  int? postId;

  @BelongsTo(Post)
  Post? post;
}
