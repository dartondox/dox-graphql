import 'package:dox_auth/dox_auth.dart' show Ability;
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

import '../../dtos/member_dto.dart';
import '../profile/profile.model.dart';

part 'member.model.g.dart';

/// `hidden` leaves out a column and a relation.
@DoxModel(table: 'members')
@GraphQL(guard: true)
@GraphQLAll()
@GraphQLFind()
@GraphQLCreate(dto: MemberDto)
@GraphQLUpdate(dto: MemberDto, can: Ability.update)
@GraphQLDelete(can: Ability.delete)
class Member extends MemberGenerator {
  @override
  List<String> get hidden => <String>['secret', 'profile'];

  @Column()
  String? name;

  @Column()
  String? email;

  @Column()
  String? secret;

  @HasOne(Profile, foreignKey: 'member_id')
  Profile? profile;
}
