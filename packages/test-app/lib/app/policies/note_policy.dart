import 'package:dox_auth/dox_auth.dart' show Policy;

import '../models/note/note.model.dart';
import '../models/user/user.model.dart';

/// A real user (of the real AuthMiddleware) may change only their notes.
/// The user type is nullable: the policy does not stop a guest by itself,
/// so the `owner:` login check must.
class NotePolicy extends Policy<User?, Note> {
  bool update(User? user, Note note) => user != null && note.userId == user.id;

  @override
  Map<String, Function> get abilities => <String, Function>{'update': update};
}
