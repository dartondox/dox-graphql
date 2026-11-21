import 'package:dox_auth/dox_auth.dart' show Ability;
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../../dtos/note_dto.dart';

part 'note.model.g.dart';

/// Public to read, but `owner:` makes create need a login. The create
/// sets `userId` to the logged-in user. Only @GraphQLPaginate, so the
/// paged list is `notes`. A note with the title `hidden` is left out of
/// every read (`filter:`), also of the find with no `can:`.
@DoxModel(table: 'notes')
@GraphQL(filter: Ability.view)
@GraphQLPaginate()
@GraphQLFind()
@GraphQLCreate(dto: NoteDto, owner: 'userId')
@GraphQLUpdate(dto: NoteDto, can: Ability.update, guard: true)
@GraphQLDelete(can: Ability.delete, guard: true)
class Note extends NoteGenerator {
  @Column()
  String? title;

  @Column()
  int? userId;
}
