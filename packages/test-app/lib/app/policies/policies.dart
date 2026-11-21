import 'package:dox_auth/dox_auth.dart' show Ability, Policy;

import '../models/article/article.model.dart';
import '../models/member/member.model.dart';
import '../models/post/post.model.dart';

// The user of the tests is a name (see FakeAuth). `intruder` may not
// change rows.

bool _owner(String user) => user != 'intruder';

class PostPolicy extends Policy<String, Post> {
  bool update(String user, Post post) => _owner(user);
  bool delete(String user, Post post) => _owner(user);

  @override
  Map<String, Function> get abilities => <String, Function>{
    Ability.update: update,
    Ability.delete: delete,
  };
}

class MemberPolicy extends Policy<String, Member> {
  bool update(String user, Member member) => _owner(user);
  bool delete(String user, Member member) => _owner(user);

  @override
  Map<String, Function> get abilities => <String, Function>{
    Ability.update: update,
    Ability.delete: delete,
  };
}

class ArticlePolicy extends Policy<String, Article> {
  /// A custom ability. Article reads it in `@GraphQLUpdate(can:)`, and this
  /// file imports Article: the builder reads the constant value.
  static const String edit = 'edit';

  bool update(String user, Article article) => _owner(user);
  bool delete(String user, Article article) => _owner(user);

  @override
  Map<String, Function> get abilities => <String, Function>{
    edit: update,
    Ability.delete: delete,
  };
}
