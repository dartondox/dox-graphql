import 'package:test/test.dart';

import 'build_helper.dart';

const String _imports = '''
import 'package:dox_auth/dox_auth.dart' show Policy;
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

    test('dto: without policy: gives only create', () async {
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
      expect(out, contains(flat("('createPost',")));
      expect(out, isNot(contains('updatePost')));
      expect(out, isNot(contains('deletePost')));
      expect(out, isNot(contains('UpdatePostInput')));
      expect(out, isNot(contains('Gate')));
    });

    test('dto: and policy: give create, update and delete', () async {
      String out = flat(
        await _build('''
$_user
class PostPolicy extends Policy<User, Post> {
  @override
  Map<String, Function> get abilities => <String, Function>{};
}

@DoxModel()
@GraphQLType(dto: CreatePostDto, policy: PostPolicy)
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
        contains(flat("import 'package:dox_auth/dox_auth.dart' show Gate;")),
      );
      // a guest can never pass a Policy<User, ...>: stopped before the
      // lookup. A missing id is checked as a blank row.
      expect(
        out,
        contains(
          flat(
            'ResolveInfo<DoxGraphQLContext> info) async { await _login(info); '
            'i1.Post? model',
          ),
        ),
      );
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
      // a database error on the blank row is not turned into FORBIDDEN
      expect(out, contains(flat('} on TypeError { allowed = false; }')));
      expect(out, isNot(contains('catch (_)')));
      // the read and create checks are decided at run time by the
      // abilities of the registered policy, not by method names
      expect(
        out,
        contains(
          flat(
            'if (Gate.hasAbility<T>(ability)) await _allow(info, ability, T);',
          ),
        ),
      );
      expect(
        out,
        contains(flat("bool view = Gate.hasAbility<i1.Post>('view');")),
      );
      // a guest can never pass a Policy<User, ...>
      expect(out, contains(flat('if (view) await _login(info);')));
    });

    test('policy: the reads, create and relations ask Gate', () async {
      String out = flat(
        await _build('''
$_user
class PostPolicy extends Policy<User?, Post> {
  @override
  Map<String, Function> get abilities => <String, Function>{};
}

@DoxModel()
@GraphQLType(dto: CreatePostDto, policy: PostPolicy)
class Post extends Model<Post> {
  @Column()
  String? title;
}

@DoxModel(table: 'blogs')
@GraphQLType()
class Blog extends Model<Blog> {
  @HasMany(Post)
  List<Post> posts = <Post>[];
  @HasOne(Post)
  Post? top;
}
''', dto: _titleDto),
      );
      expect(
        out,
        contains(
          flat(
            "_allowIf<i1.Post>(info, 'viewAny').then((_) => "
            '_viewList<i1.Post>(info, GraphQLOrm.list<i1.Post>(i1.Post(), '
            'info)))',
          ),
        ),
      );
      // a nullable user type lets a guest reach the policy: no _login
      expect(
        out,
        contains(
          flat(
            'Future<i1.Post?> _findPost(ResolveInfo<DoxGraphQLContext> info) '
            "async { bool view = Gate.hasAbility<i1.Post>('view'); "
            'i1.Post? model',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "if (view) { await (model == null ? _allowMissing(info, 'view', "
            "i1.Post()) : _allow(info, 'view', model)); }",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            'ResolveInfo<DoxGraphQLContext> info) async { '
            "await _allowIf<i1.Post>(info, 'create');",
          ),
        ),
      );
      // relations to Post ask viewAny; a list relation has the row cap
      expect(
        out,
        contains(
          flat(
            "_allowIf<i1.Post>(info, 'viewAny').then((_) => "
            '_viewList<i1.Post>(info, GraphQLOrm.many<i1.Blog, i1.Post>(s, '
            "'posts', info.context, (i1.Blog p) => p.posts)))",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "_allowIf<i1.Post>(info, 'viewAny').then((_) => "
            '_viewOne<i1.Post>(info, GraphQLOrm.relation<i1.Blog, i1.Post?>('
            "s, 'top', info.context, (i1.Blog p) => p.top)))",
          ),
        ),
      );
    });

    test('policy: must be a Policy of the model', () async {
      String out = await _build('''
class OtherPolicy {}
@DoxModel()
@GraphQLType(dto: CreatePostDto, policy: OtherPolicy)
class Post extends Model<Post> {
  @Column()
  String? title;
}
''', dto: _postDto);
      expect(out, startsWith('ERROR:'));
      expect(
        out,
        contains('Post: `policy:` must be a Policy of dox_auth for Post'),
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

    test('owner: is not a column', () async {
      await expectError(
        '''
@DoxModel()
@GraphQLType(dto: CreatePostDto, owner: 'authorId')
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
@GraphQLType(dto: CreatePostDto, owner: 'userId')
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
            'not be in the `dto:`.',
        dto: _postDto,
      );
    });

    test('owner: without dto:', () async {
      await expectError('''
@DoxModel()
@GraphQLType(owner: 'userId')
class Post extends Model<Post> {
  @Column()
  int? userId;
}
''', 'Post: `owner:` needs `dto:`');
    });

    test('owner: on a column that is not int or String', () async {
      await expectError(
        '''
@DoxModel()
@GraphQLType(dto: CreatePostDto, owner: 'at')
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
@GraphQLType(dto: TitleDto, auth: false, owner: 'userId')
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
      expect(out, matches(RegExp("\\('createPost',[^,]*,auth:true,")));
      expect(out, matches(RegExp("\\('posts',[^,]*,auth:false,")));
    });

    test('auth: goes on the model queries and writes', () async {
      String out = flat(
        await _build('''
$_user
class PostPolicy extends Policy<User, Post> {
  @override
  Map<String, Function> get abilities => <String, Function>{};
}

@DoxModel(table: 'posts')
@GraphQLType(dto: CreatePostDto, auth: false, policy: PostPolicy)
class Post extends Model<Post> {
  @Column()
  String? title;
  @Column()
  int? userId;
  @Column()
  Status? status;
  @Column()
  DateTime? at;

  @GraphQLField(auth: true)
  String? get secret => title;
}
''', dto: _postDto),
      );
      for (String name in <String>[
        'posts',
        'post',
        'createPost',
        'updatePost',
        'deletePost',
      ]) {
        expect(out, contains("AutoField<Object?,DoxGraphQLContext>('$name',"));
        expect(out, matches(RegExp("\\('$name',[^,]*,auth:false,")));
      }
      expect(out, contains(flat("'secret', graphqlString, auth: true,")));
      expect(
        out,
        contains(
          flat("ObjectType<i1.Post, DoxGraphQLContext>('Post', auth: false,"),
        ),
      );
      expect(out, isNot(contains(flat("'title', graphqlString, auth:"))));
    });
  });
}
