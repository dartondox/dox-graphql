import 'package:dox_auth/dox_auth.dart' show Ability;
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../../dtos/article_dto.dart';
import '../../policies/policies.dart';
import '../user/user.model.dart';

part 'article.model.g.dart';

@DoxModel(table: 'articles', softDelete: true)
@GraphQL()
@GraphQLAll()
@GraphQLFind()
@GraphQLCreate(dto: ArticleDto)
@GraphQLUpdate(dto: ArticleDto, can: ArticlePolicy.edit)
@GraphQLDelete(can: Ability.delete)
class Article extends ArticleGenerator {
  @Column()
  String? title;

  @Column()
  int? userId;

  @GraphQLIgnore()
  @Column(name: 'deleted_at')
  DateTime? deletedAt;

  @BelongsTo(User)
  User? user;
}
