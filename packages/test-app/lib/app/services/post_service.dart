import 'package:dox_core/dox_core.dart';

import '../models/post/post.model.dart';

@Inject()
class PostService {
  /// The posts with their users, preloaded by the ORM.
  Future<List<Post>> withUsers() async {
    return await Post().preload('user').orderBy('id').get();
  }
}
