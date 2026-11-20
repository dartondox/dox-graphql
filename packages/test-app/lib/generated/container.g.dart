// GENERATED CODE - DO NOT MODIFY BY HAND
// Made by dox_builder. Run `dart run build_runner build`.
// ignore_for_file: type=lint

import 'package:dox_core/dox_core.dart';
import 'package:dox_graphql_test_app/app/repositories/repositories.dart' as i1;
import 'package:dox_graphql_test_app/app/services/post_service.dart' as i2;
import 'package:dox_graphql_test_app/app/models/comment/comment.model.dart'
    as i3;
import 'package:dox_graphql_test_app/app/models/post/post.model.dart' as i4;
import 'package:dox_graphql_test_app/app/models/user/user.model.dart' as i5;

/// Puts every class of the app into the container: the
/// `@Inject()` classes, routers, providers and model binders.
/// Use it in `AppConfig(container: registerContainer)`.
void registerContainer(IocContainer c) {
  c.singleton<i1.BookRepository>((IocContainer c) => i1.BookRepository());
  c.singleton<i1.AuthorRepository>((IocContainer c) => i1.AuthorRepository());
  c.singleton<i2.PostService>((IocContainer c) => i2.PostService());
  c.bindModel<i3.Comment>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i3.Comment().find(key);
  });
  c.bindModel<i4.Post>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i4.Post().find(key);
  });
  c.bindModel<i5.User>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i5.User().find(key);
  });
}
