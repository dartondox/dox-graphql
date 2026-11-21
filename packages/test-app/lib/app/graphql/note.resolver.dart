import 'package:dox_graphql/dox_graphql.dart';

import '../models/note/note.model.dart';
import 'types.dart';

/// Notes that are not saved, to show that `filter:` of Note runs on every
/// field that gives a Note.
class NoteResolver {
  static List<Note> _make() => <Note>[
    Note()..title = 'hidden',
    Note()..title = 'kept',
  ];

  @GraphQLQuery()
  List<Note> madeNotes() => _make();

  @GraphQLQuery()
  Note hiddenNote() => _make().first;

  @GraphQLQuery()
  NoteBox noteBox() => NoteBox(_make());
}
