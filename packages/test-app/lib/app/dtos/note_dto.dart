import 'package:dox_core/dox_core.dart';

part 'note_dto.g.dart';

@Dto()
class NoteDto {
  NoteDto({required this.title});

  final String title;
}
