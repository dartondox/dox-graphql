import 'package:dox_core/dox_core.dart';
import 'package:dox_orm/dox_orm.dart' show Unique;

part 'member_dto.g.dart';

/// `@Unique` has no `ignoreParam`: an update that does not send `name`
/// must not check it.
@Dto()
class MemberDto {
  MemberDto({required this.name, this.email});

  @MinLength(3, message: 'The name is too short')
  @Unique('members', column: 'name', message: 'The name is taken')
  final String name;

  @Trim()
  @MinLength(5, message: 'The email is too short')
  final String? email;
}
