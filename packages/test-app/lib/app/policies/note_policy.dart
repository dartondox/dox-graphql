import 'package:dox_auth/dox_auth.dart' show Ability, Policy;

import '../models/note/note.model.dart';
import '../models/user/user.model.dart';

/// A real user (of the real AuthMiddleware) may change only their notes.
/// The user type is nullable: the policy does not stop a guest by itself,
/// so `guard: true` on update and delete must.
class NotePolicy extends Policy<User?, Note> {
  /// the title of a note that nobody may read
  static const String hidden = 'hidden';

  bool view(User? user, Note note) => note.title != hidden;

  bool update(User? user, Note note) => user != null && note.userId == user.id;

  @override
  Map<String, Function> get abilities => <String, Function>{
    Ability.view: view,
    Ability.update: update,
    Ability.delete: update,
  };
}
