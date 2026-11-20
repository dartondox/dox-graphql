import 'package:test/test.dart';

import 'build_helper.dart';

const String _imports = '''
import 'package:dox_core/dox_core.dart';
import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';
''';

/// A model library. The generated part is not there: the builder does not
/// need it.
Future<String> _build(String code, {String dto = ''}) {
  return generate(<String, String>{
    'lib/models.dart':
        '''
$_imports
part 'models.g.dart';

$dto

$code
''',
  });
}

const String _user = '''
@DoxModel(table: 'users')
@GraphQLType()
class User extends Model<User> {
  @Column()
  String? name;
}
''';

const String _postDto = '''
enum Status { draft, published }

@Dto()
class CreatePostDto {
  CreatePostDto({required this.title, this.userId, this.status, this.at});
  final String title;
  final int? userId;
  final Status? status;
  final DateTime? at;
}
''';

void main() {
  group('models |', () {
    test('the key, columns and relations', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel(table: 'posts')
@GraphQLType()
class Post extends Model<Post> {
  @Column()
  String? title;

  @Column(name: 'body')
  String? text;

  @GraphQLIgnore()
  @Column()
  String? internalNote;

  @BelongsTo(User)
  User? user;

  @HasMany(User)
  List<User> readers = <User>[];

  String? notAColumn;
}
'''),
      );
      expect(
        out,
        contains(
          flat("import 'package:dox_graphql_orm/dox_graphql_orm.dart';"),
        ),
      );
      expect(
        out,
        contains(
          flat(
            'fields: () { i1.Post model = i1.Post(); '
            'List<String> hidden = model.hidden; '
            'List<String> visible = model.visibleFields; '
            'bool show(String name) => !hidden.contains(name) && '
            '(visible.isEmpty || visible.contains(name)); '
            'return <Field<i1.Post, DoxGraphQLContext>>['
            "if (show('id')) Field<i1.Post, DoxGraphQLContext>("
            "'id', graphqlId.nonNull, resolve: (i1.Post s, "
            'ResolveInfo<DoxGraphQLContext> info) => s.id),'
            "if (show('title')) Field<i1.Post, DoxGraphQLContext>("
            "'title', graphqlString,",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat("if (show('body')) Field<i1.Post, DoxGraphQLContext>('text',"),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "if (show('user')) Field<i1.Post, DoxGraphQLContext>('user', "
            '_tUser, resolve: '
            '(i1.Post s, ResolveInfo<DoxGraphQLContext> info) => '
            "GraphQLOrm.relation<i1.Post, i1.User?>(s, 'user', info.context, "
            '(i1.Post p) => p.user))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "if (show('readers')) Field<i1.Post, DoxGraphQLContext>('readers', "
            '_tUser.nonNull.list.nonNull,',
          ),
        ),
      );
      expect(out, isNot(contains('internalNote')));
      expect(out, isNot(contains('notAColumn')));
    });

    test('the list and find queries', () async {
      String out = flat(await _build(_user));
      expect(
        out,
        contains(
          flat(
            "AutoField<Object?, DoxGraphQLContext>('users', "
            '_tUser.nonNull.list.nonNull, args: <Argument>['
            "Argument('limit', graphqlInt, defaultValue: '20'),"
            "Argument('offset', graphqlInt, defaultValue: '0'),], "
            'resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => '
            'GraphQLOrm.list<i1.User>(i1.User(), info))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "AutoField<Object?, DoxGraphQLContext>('user', _tUser, "
            "args: <Argument>[Argument('id', graphqlId.nonNull)], "
            'resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => '
            'GraphQLOrm.find<i1.User>(i1.User(), '
            "int.tryParse(info.args.get<String>('id')!)))",
          ),
        ),
      );
      expect(out, isNot(contains('mutation:')));
    });

    test('plural names', () async {
      String out = await _build('''
@DoxModel()
@GraphQLType()
class Category extends Model<Category> {}
@DoxModel()
@GraphQLType()
class Box extends Model<Box> {}
@DoxModel()
@GraphQLType()
class Day extends Model<Day> {}
''');
      expect(out, contains("'categories'"));
      expect(out, contains("'boxes'"));
      expect(out, contains("'days'"));
    });

    test('a text key, and another key column', () async {
      String out = flat(
        await _build('''
@DoxModel(primaryKey: 'uid', primaryKeyType: String)
@GraphQLType()
class Doc extends Model<Doc> {}
'''),
      );
      expect(out, contains(flat("'uid', graphqlId.nonNull")));
      expect(out, contains(flat('=> s.uid')));
      expect(
        out,
        contains(
          flat(
            "GraphQLOrm.find<i1.Doc>(i1.Doc(), info.args.get<String>('id')!)",
          ),
        ),
      );
    });

    test('queries: false', () async {
      String out = await _build('''
$_user
@DoxModel()
@GraphQLType(queries: false)
class Comment extends Model<Comment> {
  @Column()
  String? body;
}
''');
      expect(out, contains("'Comment'"));
      expect(out, isNot(contains("'comments'")));
      expect(out, isNot(contains("'comment'")));
    });

    test('dto: gives create, update and delete', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel()
@GraphQLType(dto: CreatePostDto)
class Post extends Model<Post> {
  @Column()
  String? title;
  @Column()
  int? userId;
  @Column()
  Status? status;
  @Column()
  DateTime? at;
}
''', dto: _postDto),
      );
      expect(
        out,
        contains(
          flat(
            "AutoField<Object?, DoxGraphQLContext>('createPost', "
            "_tPost.nonNull, args: <Argument>[Argument('input', "
            '_iCreatePostInput.nonNull)], resolve: (Object? _, '
            'ResolveInfo<DoxGraphQLContext> info) => _createPost(info))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "AutoField<Object?, DoxGraphQLContext>('updatePost', _tPost, "
            "args: <Argument>[Argument('id', graphqlId.nonNull), "
            "Argument('input', _iUpdatePostInput.nonNull)],",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "AutoField<Object?, DoxGraphQLContext>('deletePost', "
            'graphqlBoolean.nonNull,',
          ),
        ),
      );
      expect(out, contains(flat("InputObjectType('UpdatePostInput',")));
      expect(
        out,
        contains(
          flat(
            'i1.Post model = i1.Post()..title = dto.title..userId = '
            'dto.userId..status = dto.status..at = dto.at;',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "<String, Object?>{'title': model.title, 'user_id': "
            "model.userId, 'status': model.status?.name, 'at': "
            'model.at?.toIso8601String(), ...given}',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            'GraphQLDto.validateSent<i1.CreatePostDto>(i1.\$CreatePostDtoDto, '
            "<String, Object?>{'title': model.title, 'user_id': "
            "model.userId, 'status': model.status?.name, 'at': "
            'model.at?.toIso8601String(), ...given}, info.context, '
            'sent: given.keys.toSet(), placeholders: const <String, Object?>{'
            "'title': '', 'user_id': 0, 'status': 'draft', "
            "'at': '1970-01-01T00:00:00.000Z'},",
          ),
        ),
      );
      expect(
        out,
        contains(flat("if (input.has('userId')) model.userId = dto.userId;")),
      );
    });
  });

  group('hidden and visibleFields |', () {
    test('a relation is guarded by its snake_case name', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel()
@GraphQLType()
class Member extends Model<Member> {
  @HasOne(User)
  User? mainUser;
}
'''),
      );
      expect(
        out,
        contains(
          flat("if (show('main_user')) Field<i1.Member, DoxGraphQLContext>("),
        ),
      );
    });
  });

  group('model build errors |', () {
    Future<void> expectError(
      String code,
      String message, {
      String dto = '',
    }) async {
      String out = await _build(code, dto: dto);
      expect(out, startsWith('ERROR:'));
      expect(out, contains(message));
    }

    test('a relation to a model with no @GraphQLType', () async {
      await expectError('''
@DoxModel()
class Tag extends Model<Tag> {}
@DoxModel()
@GraphQLType()
class Post extends Model<Post> {
  @HasMany(Tag)
  List<Tag> tags = <Tag>[];
}
''', 'Post.tags: the type List<Tag> can not be a GraphQL field.');
    });

    test('a column type GraphQL can not show', () async {
      await expectError('''
@DoxModel()
@GraphQLType()
class Post extends Model<Post> {
  @Column()
  Map<String, dynamic>? meta;
}
''', 'Post.meta: the type Map<String, dynamic>? can not be a GraphQL field.');
    });

    test('an auto query and a resolver with one name', () async {
      await expectError(
        '''
$_user
class R {
  @GraphQLQuery()
  List<User> users() => <User>[];
}
''',
        'R.users: the field "users" of Query is made twice: here and in User '
            '(made for the model). Turn it off with @GraphQLType(queries: false)',
      );
    });

    test('dto: a DTO field that is not a column', () async {
      await expectError(
        '''
@DoxModel()
@GraphQLType(dto: CreatePostDto)
class Post extends Model<Post> {
  @Column()
  String? title;
}
''',
        'CreatePostDto.userId: Post has no @Column() field "userId".',
        dto: _postDto,
      );
    });

    test('dto: a type that does not fit the column', () async {
      await expectError(
        '''
@DoxModel()
@GraphQLType(dto: CreatePostDto)
class Post extends Model<Post> {
  @Column()
  int? title;
  @Column()
  int? userId;
  @Column()
  Status? status;
  @Column()
  DateTime? at;
}
''',
        'CreatePostDto.title: the type String can not be set on Post.title (int?).',
        dto: _postDto,
      );
    });

    test('dto: a class with no @Dto', () async {
      await expectError('''
class NotADto {}
@DoxModel()
@GraphQLType(dto: NotADto)
class Post extends Model<Post> {}
''', 'Post: `dto:` must be a class with @Dto(), not NotADto.');
    });
  });
}
