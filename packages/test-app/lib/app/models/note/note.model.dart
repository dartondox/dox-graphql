import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../../dtos/note_dto.dart';
import '../../policies/note_policy.dart';

part 'note.model.g.dart';

/// Public to read, but `owner:` makes create need a login. The create
/// sets `userId` to the logged-in user.
@DoxModel(table: 'notes')
@GraphQLType(dto: NoteDto, policy: NotePolicy, auth: false, owner: 'userId')
class Note extends NoteGenerator {
  @Column()
  String? title;

  @Column()
  int? userId;
}
