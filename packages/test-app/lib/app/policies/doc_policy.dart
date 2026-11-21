import 'package:dox_auth/dox_auth.dart' show Ability, Policy;

import '../models/doc/doc.model.dart';

// The user of the tests is a name (see FakeAuth). A doc is seen and
// changed only by its owner. `blind` may not list docs, `intruder` may
// not create one. A guest is denied (the user type is not nullable).
// `view` is a method with another name and `viewAny` is a function
// literal: GraphQL asks the abilities that Gate has, not method names.
class DocPolicy extends Policy<String, Doc> {
  bool canSee(String user, Doc doc) => doc.owner == user;
  bool create(String user) => user != 'intruder';
  bool update(String user, Doc doc) => doc.owner == user;
  bool delete(String user, Doc doc) => doc.owner == user;

  @override
  Map<String, Function> get abilities => <String, Function>{
    Ability.viewAny: (String user) => user != 'blind',
    Ability.view: canSee,
    Ability.create: create,
    Ability.update: update,
    Ability.delete: delete,
  };
}
