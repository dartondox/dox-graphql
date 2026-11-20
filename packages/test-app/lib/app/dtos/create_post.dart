import 'package:dox_core/dox_core.dart';

import '../models/post/post.model.dart';

part 'create_post.g.dart';

/// The fields a client may set on a post. `userId` is not here, so a
/// client can not set it.
@Dto()
class CreatePostDto {
  CreatePostDto({required this.title, this.body, this.status});

  @MinLength(3, message: 'The title is too short')
  final String title;

  final String? body;

  final PostStatus? status;
}
