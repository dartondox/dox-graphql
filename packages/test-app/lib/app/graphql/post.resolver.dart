import 'package:dox_graphql/dox_graphql.dart';

import '../models/post/post.model.dart';
import '../services/post_service.dart';

class PostResolver {
  PostResolver(this.postService);

  final PostService postService;

  @GraphQLQuery(description: 'The posts, with their users preloaded.')
  Future<List<Post>> postsWithUsers() => postService.withUsers();
}
