// GENERATED CODE - DO NOT MODIFY BY HAND
// Made by dox_builder. Run `dart run build_runner build`.
// ignore_for_file: type=lint

import 'package:dox_core/dox_core.dart';
import 'package:dox_graphql_test_app/app/repositories/repositories.dart' as i1;
import 'package:dox_graphql_test_app/app/services/post_service.dart' as i2;
import 'package:dox_graphql_test_app/app/models/account/account.model.dart'
    as i3;
import 'package:dox_graphql_test_app/app/models/article/article.model.dart'
    as i4;
import 'package:dox_graphql_test_app/app/models/comment/comment.model.dart'
    as i5;
import 'package:dox_graphql_test_app/app/models/image/image.model.dart' as i6;
import 'package:dox_graphql_test_app/app/models/member/member.model.dart' as i7;
import 'package:dox_graphql_test_app/app/models/note/note.model.dart' as i8;
import 'package:dox_graphql_test_app/app/models/post/post.model.dart' as i9;
import 'package:dox_graphql_test_app/app/models/profile/profile.model.dart'
    as i10;
import 'package:dox_graphql_test_app/app/models/tag/tag.model.dart' as i11;
import 'package:dox_graphql_test_app/app/models/user/user.model.dart' as i12;

/// Puts every class of the app into the container: the
/// `@Inject()` classes, routers, providers and model binders.
/// Use it in `AppConfig(container: registerContainer)`.
void registerContainer(IocContainer c) {
  c.singleton<i1.BookRepository>((IocContainer c) => i1.BookRepository());
  c.singleton<i1.AuthorRepository>((IocContainer c) => i1.AuthorRepository());
  c.singleton<i2.PostService>((IocContainer c) => i2.PostService());
  c.bindModel<i3.Account>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i3.Account().find(key);
  });
  c.bindModel<i4.Article>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i4.Article().find(key);
  });
  c.bindModel<i5.Comment>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i5.Comment().find(key);
  });
  c.bindModel<i6.Image>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i6.Image().find(key);
  });
  c.bindModel<i7.Member>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i7.Member().find(key);
  });
  c.bindModel<i8.Note>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i8.Note().find(key);
  });
  c.bindModel<i9.Post>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i9.Post().find(key);
  });
  c.bindModel<i10.Profile>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i10.Profile().find(key);
  });
  c.bindModel<i11.Tag>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i11.Tag().find(key);
  });
  c.bindModel<i12.User>((String id) {
    int? key = int.tryParse(id);
    if (key == null) return null;
    return i12.User().find(key);
  });
}
