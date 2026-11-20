import 'package:dox_auth/dox_auth.dart' show Policy;

import '../models/doc/doc.model.dart';

// The user of the tests is a name (see FakeAuth). A doc is seen and
// changed only by its owner. `blind` may not list docs, `intruder` may
// not create one. A guest is denied (the user type is not nullable).
class DocPolicy extends Policy<String, Doc> {
  bool viewAny(String user) => user != 'blind';
  bool view(String user, Doc doc) => doc.owner == user;
  bool create(String user) => user != 'intruder';
  bool update(String user, Doc doc) => doc.owner == user;
  bool delete(String user, Doc doc) => doc.owner == user;

  @override
  Map<String, Function> get abilities => <String, Function>{
    'viewAny': viewAny,
    'view': view,
    'create': create,
    'update': update,
    'delete': delete,
  };
}
