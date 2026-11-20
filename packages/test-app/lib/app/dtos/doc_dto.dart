import 'package:dox_core/dox_core.dart';

part 'doc_dto.g.dart';

@Dto()
class DocDto {
  DocDto({required this.title});

  final String title;
}
