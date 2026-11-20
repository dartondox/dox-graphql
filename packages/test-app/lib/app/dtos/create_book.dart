import 'package:dox_core/dox_core.dart';

import '../graphql/types.dart';

part 'create_book.g.dart';

@Dto()
class CreateBook {
  CreateBook({required this.title, required this.authorId, this.genre});

  @MinLength(3, message: 'The title is too short')
  final String title;

  final int authorId;

  final Genre? genre;
}
