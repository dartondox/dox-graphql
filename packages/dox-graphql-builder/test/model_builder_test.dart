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
@GraphQL()
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

const String _titleDto = '''
@Dto()
class CreatePostDto {
  CreatePostDto({required this.title});
  final String title;
}
''';

void main() {
  group('models |', () {
    test('the key, columns and relations', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel(table: 'posts')
@GraphQL()
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
            '_tUser.nonNull.list,',
          ),
        ),
      );
      expect(out, isNot(contains('internalNote')));
      expect(out, isNot(contains('notAColumn')));
    });

    test('every root field is nullable, the list items are not', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel()
@GraphQL()
@GraphQLAll()
@GraphQLPaginate()
@GraphQLCreate(dto: CreatePostDto)
@GraphQLUpdate(dto: CreatePostDto)
@GraphQLDelete()
class Post extends Model<Post> {
  @Column()
  String? title;
}
''', dto: _titleDto),
      );
      expect(out, matches(RegExp("\\('posts',_tPost.nonNull.list,")));
      expect(out, matches(RegExp("\\('postsPaginate',_pPost,")));
      expect(out, matches(RegExp("\\('createPost',_tPost,")));
      expect(out, matches(RegExp("\\('updatePost',_tPost,")));
      expect(out, matches(RegExp("\\('deletePost',graphqlBoolean,")));
    });

    test('no operation annotation: no root field', () async {
      String out = await _build('''
$_user
@DoxModel()
@GraphQL()
class Comment extends Model<Comment> {
  @Column()
  String? body;
}
''');
      expect(out, contains("'Comment'"));
      expect(out, isNot(contains("'comments'")));
      expect(out, isNot(contains("'comment'")));
      expect(out, isNot(contains("'users'")));
      expect(out, isNot(contains('mutation:')));
      // the schema still has a query
      expect(out, contains("'placeholder'"));
    });

    test('@GraphQLAll and @GraphQLFind', () async {
      String out = flat(
        await _build('''
@DoxModel(table: 'users')
@GraphQL()
@GraphQLAll()
@GraphQLFind()
class User extends Model<User> {}
'''),
      );
      expect(
        out,
        contains(
          flat(
            "Field<Object?, DoxGraphQLContext>('users', "
            '_tUser.nonNull.list, args: <Argument>['
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
            "Field<Object?, DoxGraphQLContext>('user', _tUser, "
            "args: <Argument>[Argument('id', graphqlId.nonNull)], "
            'resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => '
            'GraphQLOrm.find<i1.User>(i1.User(), '
            "int.tryParse(info.args.get<String>('id')!)))",
          ),
        ),
      );
      expect(out, isNot(contains('mutation:')));
      expect(out, isNot(contains('Gate')));
      expect(out, isNot(contains('startChecks')));
    });

    test('name: and description: on an operation', () async {
      String out = flat(
        await _build('''
@DoxModel(table: 'users')
@GraphQL()
@GraphQLAll(name: 'people', description: 'Everyone.')
@GraphQLPaginate(name: 'pagedPeople')
class User extends Model<User> {}
'''),
      );
      expect(
        out,
        contains(
          flat(
            "Field<Object?, DoxGraphQLContext>('people', _tUser.nonNull.list, "
            "description: 'Everyone.',",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat("Field<Object?, DoxGraphQLContext>('pagedPeople', _pUser,"),
        ),
      );
    });

    test('@GraphQLPaginate', () async {
      String out = flat(
        await _build('''
@DoxModel(table: 'users')
@GraphQL()
@GraphQLPaginate()
class User extends Model<User> {}
'''),
      );
      // the only list: it has the plural name
      expect(
        out,
        contains(
          flat(
            "Field<Object?, DoxGraphQLContext>('users', _pUser, "
            "args: <Argument>[Argument('first', graphqlInt, defaultValue: "
            "'20'),Argument('page', graphqlInt, defaultValue: '1'),], "
            'resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) => '
            'GraphQLOrm.paginate<i1.User>(i1.User(), info))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            'final ObjectType<Pagination<i1.User>, DoxGraphQLContext> _pUser '
            '= ObjectType<Pagination<i1.User>, DoxGraphQLContext>('
            "'UserPaginator',",
          ),
        ),
      );
      expect(out, contains(flat("('data', _tUser.nonNull.list.nonNull,")));
      expect(
        out,
        contains(flat("('paginatorInfo', GraphQLOrm.paginatorInfo.nonNull,")),
      );
      expect(out, contains(flat('_pUser, GraphQLOrm.paginatorInfo, ],')));
    });

    test('plural names', () async {
      String out = await _build('''
@DoxModel()
@GraphQL()
@GraphQLAll()
class Category extends Model<Category> {}
@DoxModel()
@GraphQL()
@GraphQLAll()
class Box extends Model<Box> {}
@DoxModel()
@GraphQL()
@GraphQLAll()
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
@GraphQL()
@GraphQLFind()
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

    test('writes with no can: ask no Gate', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel()
@GraphQL()
@GraphQLCreate(dto: CreatePostDto)
@GraphQLDelete()
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
      expect(out, contains(flat("('createPost',")));
      expect(out, contains(flat("('deletePost',")));
      expect(out, isNot(contains('updatePost')));
      expect(out, isNot(contains('UpdatePostInput')));
      expect(out, isNot(contains('Gate')));
      expect(
        out,
        contains(
          flat(
            'i1.Post? model = await GraphQLOrm.find<i1.Post>(i1.Post(), '
            "int.tryParse(info.args.get<String>('id')!)); if (model == null) "
            '{ return false; } await model.delete();',
          ),
        ),
      );
    });

    test('create, update and delete with can:', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel()
@GraphQL()
@GraphQLCreate(dto: CreatePostDto, can: 'create')
@GraphQLUpdate(dto: CreatePostDto, can: 'update')
@GraphQLDelete(can: 'delete')
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
            "Field<Object?, DoxGraphQLContext>('createPost', "
            "_tPost, args: <Argument>[Argument('input', "
            '_iCreatePostInput.nonNull)], resolve: (Object? _, '
            'ResolveInfo<DoxGraphQLContext> info) => _createPost(info))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "Field<Object?, DoxGraphQLContext>('updatePost', _tPost, "
            "args: <Argument>[Argument('id', graphqlId.nonNull), "
            "Argument('input', _iUpdatePostInput.nonNull)],",
          ),
        ),
      );
      expect(out, contains(flat("InputObjectType('UpdatePostInput',")));
      expect(
        out,
        contains(
          flat(
            'ResolveInfo<DoxGraphQLContext> info) async { '
            "await _allow(info, 'create', i1.Post);",
          ),
        ),
      );
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
            'GraphQLDto.validateSent<i1.CreatePostDto>(i1.\$CreatePostDtoDto, '
            "<String, Object?>{'title': model.title, 'user_id': "
            "model.userId, 'status': model.status?.name, 'at': "
            'model.at?.toIso8601String(), ...given}, info.context, '
            'sent: given.keys.toSet(), placeholders: const <String, Object?>{'
            "'title': '-', 'user_id': 0, 'status': 'draft', "
            "'at': '1970-01-01T00:00:00.000Z'},",
          ),
        ),
      );
      expect(
        out,
        contains(flat("if (input.has('userId')) model.userId = dto.userId;")),
      );
      expect(
        out,
        contains(
          flat("import 'package:dox_auth/dox_auth.dart' show Gate, Policy;"),
        ),
      );
      // a missing id is checked as a blank row
      expect(
        out,
        contains(
          flat(
            "if (model == null) { await _allowMissing(info, 'update', "
            "i1.Post()); return null; } await _allow(info, 'update', model);",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "if (model == null) { await _allowMissing(info, 'delete', "
            "i1.Post()); return false; } await _allow(info, 'delete', model); "
            'await model.delete();',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            'if (!await Gate.allows(user, ability, subject)) '
            'throw _denied(user);',
          ),
        ),
      );
      // any error of the policy on the blank row denies
      expect(out, contains(flat('} on Object { allowed = false; }')));
      // nothing is asked at run time to skip a check
      expect(out, isNot(contains('hasAbility')));
    });

    test('a create and an update DTO of their own', () async {
      String out = flat(
        await _build(
          '''
$_user
@DoxModel()
@GraphQL()
@GraphQLCreate(dto: CreatePostDto)
@GraphQLUpdate(dto: EditPostDto)
class Post extends Model<Post> {
  @Column()
  String? title;
}
''',
          dto:
              '''
$_titleDto
@Dto()
class EditPostDto {
  EditPostDto({this.title});
  final String? title;
}
''',
        ),
      );
      expect(out, contains(flat('GraphQLDto.validateSent<i1.EditPostDto>(')));
      expect(
        out,
        contains(flat('i1.CreatePostDto dto = await _vCreatePostInput(')),
      );
    });

    test('can: on the reads, and filter: on lists and relations', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel()
@GraphQL(filter: 'view')
@GraphQLAll(can: 'viewAny')
@GraphQLPaginate(can: 'viewAny')
@GraphQLFind(can: 'view')
class Post extends Model<Post> {
  @Column()
  String? title;
}

@DoxModel(table: 'blogs')
@GraphQL()
class Blog extends Model<Blog> {
  @HasMany(Post)
  List<Post> posts = <Post>[];
  @HasOne(Post)
  Post? top;
}
'''),
      );
      expect(
        out,
        contains(
          flat(
            "_allow(info, 'viewAny', i1.Post).then((_) => "
            "_filterList<i1.Post>(info, 'view', "
            'GraphQLOrm.list<i1.Post>(i1.Post(), info)))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "_allow(info, 'viewAny', i1.Post).then((_) => "
            "_filterPage<i1.Post>(info, 'view', "
            'GraphQLOrm.paginate<i1.Post>(i1.Post(), info)))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "await (model == null ? _allowMissing(info, 'view', "
            "i1.Post()) : _allow(info, 'view', model));",
          ),
        ),
      );
      // relations only filter: no viewAny; a list relation has the row cap
      expect(
        out,
        contains(
          flat(
            "_filterList<i1.Post>(info, 'view', "
            'GraphQLOrm.many<i1.Blog, i1.Post>(s, '
            "'posts', info.context, (i1.Blog p) => p.posts))",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "_filterOne<i1.Post>(info, 'view', "
            'GraphQLOrm.relation<i1.Blog, i1.Post?>('
            "s, 'top', info.context, (i1.Blog p) => p.top))",
          ),
        ),
      );
      // the abilities are checked when the app starts
      expect(
        out,
        contains(flat('startChecks: <void Function()>[_checkAbilities],')),
      );
      expect(
        out,
        contains(
          flat(
            '_checkAbility<i1.Post>(\'@GraphQL(filter: \\\'view\\\')\', '
            "'Post', 'view');",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            '_checkAbility<i1.Post>(\'@GraphQLFind(can: \\\'view\\\')\', '
            "'Post', 'view');",
          ),
        ),
      );
      expect(out, contains(flat('if (Gate.isDefined(ability)) return;')));
    });

    test('every relation is nullable, the list items are not', () async {
      String out = flat(
        await _build('''
@DoxModel(table: 'users')
@GraphQL()
class User extends Model<User> {
  @Column()
  String? name;
}

@DoxModel()
@GraphQL(filter: 'view')
class Post extends Model<Post> {
  @Column()
  String? title;
}

@DoxModel(table: 'comments')
@GraphQL(guard: true)
class Comment extends Model<Comment> {
  @Column()
  String? body;
}

@DoxModel(table: 'blogs')
@GraphQL()
class Blog extends Model<Blog> {
  @HasMany(Post)
  List<Post> posts = <Post>[];
  @BelongsTo(Post)
  late Post first;
  @HasMany(Comment)
  List<Comment> comments = <Comment>[];
  @HasMany(User)
  List<User> readers = <User>[];
  @BelongsTo(User)
  late User editor;
}
'''),
      );
      // a relation can also fail on the row cap or the database, so it is
      // always nullable. The items are not: a refused row is dropped.
      expect(out, contains(flat("'posts', _tPost.nonNull.list,")));
      expect(out, contains(flat("'first', _tPost,")));
      expect(out, contains(flat("'comments', _tComment.nonNull.list,")));
      // also to a public type with no filter
      expect(out, contains(flat("'readers', _tUser.nonNull.list,")));
      expect(out, contains(flat("'editor', _tUser,")));
    });
  });

  group('hidden and visibleFields |', () {
    test('a relation is guarded by its snake_case name', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel()
@GraphQL()
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

    test('a relation to a model with no @GraphQL', () async {
      await expectError('''
@DoxModel()
class Tag extends Model<Tag> {}
@DoxModel()
@GraphQL()
class Post extends Model<Post> {
  @HasMany(Tag)
  List<Tag> tags = <Tag>[];
}
''', 'Post.tags: the type List<Tag> can not be a GraphQL field.');
    });

    test('a column type GraphQL can not show', () async {
      await expectError('''
@DoxModel()
@GraphQL()
class Post extends Model<Post> {
  @Column()
  Map<String, dynamic>? meta;
}
''', 'Post.meta: the type Map<String, dynamic>? can not be a GraphQL field.');
    });

    test('a model query and a resolver with one name', () async {
      await expectError(
        '''
@DoxModel(table: 'users')
@GraphQL()
@GraphQLAll()
class User extends Model<User> {}
class R {
  @GraphQLQuery()
  List<User> users() => <User>[];
}
''',
        'R.users: the field "users" of Query is made twice: here and in '
            '@GraphQLAll on User. Rename one with `name:`.',
      );
    });

    test('dto: a DTO field that is not a column', () async {
      await expectError(
        '''
@DoxModel()
@GraphQL()
@GraphQLCreate(dto: CreatePostDto)
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
@GraphQL()
@GraphQLCreate(dto: CreatePostDto)
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
@GraphQL()
@GraphQLUpdate(dto: NotADto)
class Post extends Model<Post> {}
''', 'Post @GraphQLUpdate: `dto:` must be a class with @Dto(), not NotADto.');
    });

    test('owner: is not a column', () async {
      await expectError(
        '''
@DoxModel()
@GraphQL()
@GraphQLCreate(dto: CreatePostDto, owner: 'authorId')
class Post extends Model<Post> {
  @Column()
  String? title;
}
''',
        'Post: `owner:` must be a column of Post, but it has no @Column() '
            'field "authorId".',
        dto: _postDto,
      );
    });

    test('owner: is a field of the DTO', () async {
      await expectError(
        '''
@DoxModel()
@GraphQL()
@GraphQLCreate(dto: CreatePostDto, owner: 'userId')
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
''',
        'CreatePostDto.userId: "userId" is the `owner:` of Post, so it can '
            'not be in the `dto:` of @GraphQLCreate.',
        dto: _postDto,
      );
    });

    test('owner: is a field of the update DTO', () async {
      await expectError(
        '''
@DoxModel()
@GraphQL()
@GraphQLCreate(dto: TitleDto, owner: 'userId')
@GraphQLUpdate(dto: CreatePostDto)
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
''',
        'CreatePostDto.userId: "userId" is the `owner:` of Post, so it can '
            'not be in the `dto:` of @GraphQLUpdate.',
        dto:
            '''
$_postDto
@Dto()
class TitleDto {
  TitleDto({required this.title});
  final String title;
}
''',
      );
    });

    test('an operation on a plain class', () async {
      await expectError('''
@GraphQL()
@GraphQLAll()
class Plain {
  String? name;
}
''', 'Plain: @GraphQLAll() works only on a model of dox_orm.');
    });

    test('filter: on a plain class', () async {
      await expectError('''
@GraphQL(filter: 'view')
class Plain {
  String? name;
}
''', 'Plain: `filter:` works only on a model of dox_orm.');
    });

    test('an operation without @GraphQL', () async {
      await expectError('''
@DoxModel()
@GraphQLFind()
class Post extends Model<Post> {}
''', 'Post: @GraphQLFind() needs @GraphQL() on the model too.');
    });

    test('an empty can:', () async {
      await expectError('''
@DoxModel()
@GraphQL()
@GraphQLFind(can: '')
class Post extends Model<Post> {}
''', 'Post @GraphQLFind: `can:` can not be empty.');
    });

    test('owner: on a column that is not int or String', () async {
      await expectError(
        '''
@DoxModel()
@GraphQL()
@GraphQLCreate(dto: CreatePostDto, owner: 'at')
class Post extends Model<Post> {
  @Column()
  DateTime? at;
}
''',
        'Post: `owner:` "at" must be an int or String column',
        dto: _postDto,
      );
    });

    test('owner: sets the column in create and needs a login', () async {
      String out = flat(
        await _build(
          '''
$_user
@DoxModel(table: 'posts')
@GraphQL()
@GraphQLAll()
@GraphQLCreate(dto: TitleDto, owner: 'userId')
@GraphQLUpdate(dto: TitleDto, can: 'update')
@GraphQLDelete(can: 'delete', guard: true)
class Post extends Model<Post> {
  @Column()
  String? title;
  @Column()
  int? userId;
}
''',
          dto: '''
@Dto()
class TitleDto {
  TitleDto({required this.title});
  final String title;
}
''',
        ),
      );
      expect(
        out,
        contains(
          flat(
            'model.userId = await GraphQLAuth.ownerId<int>('
            "info.context, 'Post.userId');",
          ),
        ),
      );
      expect(out, matches(RegExp("\\('createPost',[^,]*,guard:true,")));
      // update has no guard: of its own, delete has one
      expect(out, isNot(matches(RegExp("\\('updatePost',[^,]*,guard:"))));
      expect(out, matches(RegExp("\\('deletePost',[^,]*,guard:true,")));
      expect(out, isNot(matches(RegExp("\\('posts',[^,]*,guard:"))));
    });

    test('update or delete with no can: and no guard: warns', () async {
      await _build('''
@DoxModel(table: 'posts')
@GraphQL()
@GraphQLUpdate(dto: CreatePostDto)
@GraphQLDelete(can: 'delete')
class Post extends Model<Post> {
  @Column()
  String? title;
}

@DoxModel(table: 'notes')
@GraphQL(guard: true)
@GraphQLDelete()
class Note extends Model<Note> {}

@DoxModel(table: 'tags')
@GraphQL()
@GraphQLDelete(name: 'dropTag', guard: true)
class Tag extends Model<Tag> {}
''', dto: _titleDto);
      expect(warnings, hasLength(1));
      expect(
        warnings.single,
        endsWith(
          'updatePost (@GraphQLUpdate on Post) has no can: and no guard: - '
          'anyone can call it.',
        ),
      );
    });

    test('filter: runs on every field that gives the model', () async {
      String out = flat(
        await _build('''
@DoxModel(table: 'posts')
@GraphQL(filter: 'view')
@GraphQLCreate(dto: CreatePostDto)
class Post extends Model<Post> {
  @Column()
  String? title;
}

@DoxModel(table: 'blogs')
@GraphQL()
class Blog extends Model<Blog> {
  @GraphQLField()
  Post get pinned => Post();
}

@GraphQL()
class Box {
  final List<Post> posts = <Post>[];
}

class R {
  @GraphQLQuery()
  Future<List<Post>> latest() async => <Post>[];
  @GraphQLResolveField()
  Post first(Box box) => Post();
}
''', dto: _titleDto),
      );
      expect(
        out,
        contains(
          flat(
            "'pinned', _tPost, resolve: (i1.Blog s, "
            'ResolveInfo<DoxGraphQLContext> info) => '
            "_filterOne<i1.Post>(info, 'view', Future<i1.Post?>.value(s.pinned))",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "'posts', _tPost.nonNull.list.nonNull, resolve: (i1.Box s, "
            'ResolveInfo<DoxGraphQLContext> info) => '
            "_filterList<i1.Post>(info, 'view', "
            'Future<List<i1.Post>?>.value(s.posts))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "_filterList<i1.Post>(info, 'view', "
            'Future<List<i1.Post>?>.value(i1.R().latest()))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "'first', _tPost, resolve: (i1.Box s, "
            'ResolveInfo<DoxGraphQLContext> info) => '
            "_filterOne<i1.Post>(info, 'view', "
            'Future<i1.Post?>.value(i1.R().first(s)))',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "_filterOne<i1.Post>(info, 'view', "
            'Future<i1.Post?>.value(_createPost(info)))',
          ),
        ),
      );
    });

    test('the guard of the type reaches the page and the delete', () async {
      String out = flat(
        await _build('''
@DoxModel(table: 'posts')
@GraphQL(guard: true, filter: 'view')
@GraphQLPaginate()
@GraphQLFind()
@GraphQLDelete()
class Post extends Model<Post> {
  @Column()
  String? title;
}
'''),
      );
      expect(
        out,
        contains(
          flat(
            "'PostPaginator', description: 'A page of Post rows.', "
            'guard: true,',
          ),
        ),
      );
      expect(out, matches(RegExp("\\('deletePost',[^,]*,guard:true,")));
      // the find with no can: still applies the filter
      expect(
        out,
        contains(
          flat(
            "return await _filterOne<i1.Post>(info, 'view', "
            'Future<i1.Post?>.value(model));',
          ),
        ),
      );
      expect(out, isNot(contains('_allowMissing(info,')));
    });

    test('guard: goes on each operation and the type', () async {
      String out = flat(
        await _build('''
$_user
@DoxModel(table: 'posts')
@GraphQL(guard: true)
@GraphQLAll(guard: true)
@GraphQLPaginate(guard: true)
@GraphQLFind(guard: true)
@GraphQLCreate(dto: CreatePostDto, guard: true)
@GraphQLUpdate(dto: CreatePostDto, guard: true)
@GraphQLDelete(guard: true)
class Post extends Model<Post> {
  @Column()
  String? title;
  @Column()
  int? userId;
  @Column()
  Status? status;
  @Column()
  DateTime? at;

  @GraphQLField(guard: true)
  String? get secret => title;
}
''', dto: _postDto),
      );
      for (String name in <String>[
        'posts',
        'postsPaginate',
        'post',
        'createPost',
        'updatePost',
        'deletePost',
      ]) {
        expect(out, matches(RegExp("\\('$name',[^,]*,guard:true,")));
      }
      expect(out, contains(flat("'secret', graphqlString, guard: true,")));
      expect(
        out,
        contains(
          flat("ObjectType<i1.Post, DoxGraphQLContext>('Post', guard: true,"),
        ),
      );
      expect(out, isNot(contains(flat("'title', graphqlString, guard:"))));
    });
  });
}
