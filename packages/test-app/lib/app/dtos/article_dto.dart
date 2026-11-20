import 'package:dox_core/dox_core.dart';

part 'article_dto.g.dart';

@Dto()
class ArticleDto {
  ArticleDto({required this.title});

  final String title;
}
