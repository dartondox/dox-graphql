import 'package:dox_auth/dox_auth.dart' show Ability;
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../../dtos/create_post.dart';
import '../comment/comment.model.dart';
import '../image/image.model.dart';
import '../note/note.model.dart';
import '../tag/tag.model.dart';
import '../user/user.model.dart';

part 'post.model.g.dart';

enum PostStatus { draft, published }

@DoxModel(table: 'posts')
@GraphQL()
@GraphQLAll()
@GraphQLPaginate()
@GraphQLFind()
@GraphQLCreate(dto: CreatePostDto)
@GraphQLUpdate(dto: CreatePostDto, can: Ability.update)
@GraphQLDelete(can: Ability.delete)
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

  @ManyToMany(Tag, pivotTable: 'post_tag')
  List<Tag> tags = <Tag>[];

  @MorphMany(Image, 'imageable')
  List<Image> images = <Image>[];

  /// A note made from the title, not saved. Note has `filter:`, so the
  /// note of the post "Second" (title `hidden`) is null.
  @GraphQLField()
  Note get titleNote => Note()..title = title == 'Second' ? 'hidden' : title;

  /// The first 5 letters of the body.
  @GraphQLField()
  String get excerpt {
    String text = body ?? '';
    return text.length <= 5 ? text : text.substring(0, 5);
  }
}
