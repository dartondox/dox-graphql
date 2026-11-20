import 'package:test/test.dart';

import 'build_helper.dart';

const String _imports = '''
import 'package:dox_core/dox_core.dart';
import 'package:dox_graphql/dox_graphql.dart';
''';

/// A resolver with one query, so a schema is valid.
const String _hello = '''
class HelloResolver {
  @GraphQLQuery()
  String hello() => 'hi';
}
''';

Future<String> _build(String code) {
  return generate(<String, String>{'lib/app.dart': '$_imports\n$code'});
}

void main() {
  group('types |', () {
    test('public fields of a plain class, by their Dart types', () async {
      String out = flat(
        await _build('''
$_hello
enum Genre { novel, poetry }

/// A book.
@GraphQLType()
class Book {
  Book(this.id, this.title, this.genre, this.tags, this.at, this.price);
  final int id;
  final String? title;
  final Genre genre;
  final List<String?> tags;
  final DateTime at;
  final double price;
  static int count = 0;
  final String _secret = '';
}
'''),
      );
      expect(out, contains(flat("import 'package:a/app.dart' as i1;")));
      expect(
        out,
        contains(
          flat(
            "ObjectType<i1.Book, DoxGraphQLContext>('Book', "
            "description: 'A book.',",
          ),
        ),
      );
      expect(out, contains(flat("'id', graphqlInt.nonNull")));
      expect(out, contains(flat("'title', graphqlString,")));
      expect(out, contains(flat("'genre', _eGenre.nonNull")));
      expect(out, contains(flat("'tags', graphqlString.list.nonNull")));
      expect(out, contains(flat("'at', graphqlDateTime.nonNull")));
      expect(out, contains(flat("'price', graphqlFloat.nonNull")));
      expect(out, contains(flat('=> s.title')));
      expect(out, isNot(contains('count')));
      expect(out, isNot(contains('secret')));
      expect(
        out,
        contains(
          flat(
            "EnumType<i1.Genre>('Genre', <EnumValue<i1.Genre>>["
            "EnumValue<i1.Genre>('novel', i1.Genre.novel),",
          ),
        ),
      );
      expect(out, contains(flat('types: <NamedType>[_tBook]')));
    });

    test('@GraphQLType(name:, description:)', () async {
      String out = flat(
        await _build('''
$_hello
/// Not this.
@GraphQLType(name: 'Article', description: 'An article.')
class Post {
  final int id = 1;
}
'''),
      );
      expect(
        out,
        contains(
          flat(
            'final ObjectType<i1.Post, DoxGraphQLContext> _tArticle = '
            "ObjectType<i1.Post, DoxGraphQLContext>('Article', "
            "description: 'An article.',",
          ),
        ),
      );
    });

    test('@GraphQLIgnore leaves a field out', () async {
      String out = await _build('''
$_hello
@GraphQLType()
class Post {
  final int id = 1;
  @GraphQLIgnore()
  final String password = '';
}
''');
      expect(out, isNot(contains('password')));
    });

    test('@GraphQLField on a getter is a computed field', () async {
      String out = flat(
        await _build('''
$_hello
@GraphQLType()
class Post {
  final String body = '';

  /// The start of the body.
  @GraphQLField()
  String get excerpt => body;

  @GraphQLField(name: 'size', deprecationReason: 'Use length.')
  Future<int> get bodySize async => body.length;

  String get notAField => '';
}
'''),
      );
      expect(
        out,
        contains(
          flat(
            "'excerpt', graphqlString.nonNull, "
            "description: 'The start of the body.',",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat("'size', graphqlInt.nonNull, deprecationReason: 'Use length.',"),
        ),
      );
      expect(out, contains(flat('=> s.bodySize')));
      expect(out, isNot(contains('notAField')));
    });

    test('fields of a superclass, with its type arguments', () async {
      String out = flat(
        await _build('''
$_hello
class Base<T> {
  Base(this.value, this.name);
  final T value;
  final String name;
  String _secret = '';

  @GraphQLField()
  String get shout => name;
}

@GraphQLType()
class Item extends Base<int> {
  Item(super.value, super.name, this.extra);
  final bool extra;

  @override
  final String name = 'item';
}
'''),
      );
      expect(out, contains(flat("'extra', graphqlBoolean.nonNull")));
      expect(out, contains(flat("'name', graphqlString.nonNull")));
      expect(out, contains(flat("'value', graphqlInt.nonNull")));
      expect(out, contains(flat("'shout', graphqlString.nonNull")));
      expect(out, isNot(contains('secret')));
      // the override in Item is read once
      expect(RegExp("'name'").allMatches(out), hasLength(1));
    });

    test('a nested list argument is cast at each level', () async {
      String out = flat(
        await _build('''
class R {
  @GraphQLQuery()
  int sum(List<List<int>> rows, {List<String?>? tags}) => 1;
}
'''),
      );
      expect(
        out,
        contains(
          flat(
            "Argument('rows', graphqlInt.nonNull.list.nonNull.list.nonNull)",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "(switch (info.args.get<Object?>('rows')) { List<Object?> l1 => "
            '<List<int>>[for (Object? x1 in l1) (switch (x1) { '
            'List<Object?> l2 => <int>[for (Object? x2 in l2) (x2 as int)], '
            '_ => null })!], _ => null })!',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "tags: (switch (info.args.get<Object?>('tags')) { List<Object?> "
            'l1 => <String?>[for (Object? x1 in l1) (x1 as String?)], '
            '_ => null })',
          ),
        ),
      );
    });

    test('a type points at another type', () async {
      String out = flat(
        await _build('''
$_hello
@GraphQLType()
class User {
  final String name = '';
  final List<Post> posts = <Post>[];
}

@GraphQLType()
class Post {
  final User? author = null;
}
'''),
      );
      expect(out, contains(flat("'posts', _tPost.nonNull.list.nonNull")));
      expect(out, contains(flat("'author', _tUser,")));
    });
  });

  group('resolvers |', () {
    test('@Query: the parameters are the arguments', () async {
      String out = flat(
        await _build('''
@Inject()
class PostService {}

enum Sort { newest, oldest }

class PostResolver {
  PostResolver(this.service, {required this.other, this.optional});
  final PostService service;
  final PostService other;
  final PostService? optional;

  /// The posts.
  @GraphQLQuery()
  Future<List<String>> posts(
    int id,
    DoxGraphQLContext context, {
    int limit = 10,
    String? search,
    Sort sort = Sort.newest,
    List<int> tags = const <int>[1, 2],
    String title = 'a "b"',
    bool on = true,
    double? ratio = 0.5,
  }) async => <String>[];
}
'''),
      );
      expect(
        out,
        contains(
          flat(
            "Field<Object?, DoxGraphQLContext>('posts', "
            "graphqlString.nonNull.list.nonNull, description: 'The posts.', "
            'args: <Argument>['
            "Argument('id', graphqlInt.nonNull),"
            "Argument('limit', graphqlInt.nonNull, defaultValue: '10'),"
            "Argument('search', graphqlString),"
            "Argument('sort', _eSort.nonNull, defaultValue: 'newest'),"
            "Argument('tags', graphqlInt.nonNull.list.nonNull, "
            "defaultValue: '[1, 2]'),"
            "Argument('title', graphqlString.nonNull, "
            "defaultValue: '\"a \\\\\"b\\\\\"\"'),"
            "Argument('on', graphqlBoolean.nonNull, defaultValue: 'true'),"
            "Argument('ratio', graphqlFloat, defaultValue: '0.5'),"
            '],',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            'i1.PostResolver(info.context.make<i1.PostService>(), '
            'other: info.context.make<i1.PostService>()).posts('
            "info.args.get<int>('id')!, info.context, "
            "limit: info.args.get<int>('limit')!, "
            "search: info.args.get<String>('search'), "
            "sort: info.args.get<i1.Sort>('sort')!, "
            "tags: (switch (info.args.get<Object?>('tags')) { "
            'List<Object?> l1 => <int>[for (Object? x1 in l1) (x1 as int)], '
            '_ => null })!, '
            "title: info.args.get<String>('title')!, "
            "on: info.args.get<bool>('on')!, "
            "ratio: info.args.get<double>('ratio'))",
          ),
        ),
      );
    });

    test('@GraphQLQuery(name:) and a mutation root only when needed', () async {
      String out = flat(
        await _build('''
class R {
  @GraphQLQuery(name: 'greeting', description: 'Says hi.')
  String hello() => 'hi';
}
'''),
      );
      expect(
        out,
        contains(
          flat("'greeting', graphqlString.nonNull, description: 'Says hi.',"),
        ),
      );
      expect(out, isNot(contains('mutation:')));
    });

    test('@Mutation with a @Dto: an input type, checked first', () async {
      String out = flat(
        await generate(<String, String>{
          'lib/dto.dart':
              '''
$_imports
part 'dto.g.dart';

enum Kind { a, b }

@Dto()
class Line {
  Line({required this.name});
  final String name;
}

@Dto()
class CreatePostDto {
  CreatePostDto({
    required this.title,
    this.userId,
    this.kind,
    this.at,
    this.lines = const <Line>[],
    this.main,
  });
  final String title;
  final int? userId;
  final Kind? kind;
  final DateTime? at;
  final List<Line> lines;
  final Line? main;
}
''',
          'lib/resolver.dart':
              '''
$_imports
import 'dto.dart';
$_hello
class PostResolver {
  @GraphQLMutation()
  Future<int> createPost(CreatePostDto input, {CreatePostDto? other}) async => 1;
}
''',
        }),
      );
      expect(
        out,
        contains(
          flat(
            "Argument('input', _iCreatePostInput.nonNull),"
            "Argument('other', _iCreatePostInput),",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            '(Object? _, ResolveInfo<DoxGraphQLContext> info) async => '
            'i1.PostResolver().createPost(await _vCreatePostInput('
            "info.args.input('input')!, info.context), "
            "other: info.args.input('other') == null ? null : "
            "await _vCreatePostInput(info.args.input('other')!, info.context))",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "InputObjectType('CreatePostInput', fields: () => <InputField>["
            "InputField('title', graphqlString),"
            "InputField('userId', graphqlInt),"
            "InputField('kind', _eKind),"
            "InputField('at', graphqlDateTime),"
            "InputField('lines', _iLineInput.list),"
            "InputField('main', _iLineInput),",
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            "if (v.has('userId')) 'user_id': v.get<Object?>('userId'),"
            "if (v.has('kind')) 'kind': switch (v.get<Object?>('kind')) "
            '{ i2.Kind e1 => e1.name, _ => null },'
            "if (v.has('at')) 'at': switch (v.get<Object?>('at')) "
            '{ DateTime d1 => d1.toIso8601String(), _ => null },'
            "if (v.has('lines')) 'lines': switch (v.get<Object?>('lines')) "
            '{ List<Object?> l1 => <Object?>[for (Object? y1 in l1) '
            'switch (y1) { InputValues n2 => _mLineInput(n2), _ => null }], '
            '_ => null },',
          ),
        ),
      );
      expect(
        out,
        contains(
          flat(
            'return GraphQLDto.validate<i2.CreatePostDto>('
            r'i2.$CreatePostDtoDto, _mCreatePostInput(v), context, '
            "names: const <String, String>{'user_id': 'userId'})",
          ),
        ),
      );
    });

    test('@ResolveField adds a field to the type of its parent', () async {
      String out = flat(
        await _build('''
$_hello
@GraphQLType()
class Post {
  final int authorId = 1;
}

class PostResolver {
  @ResolveField(description: 'Who wrote it.')
  Future<String?> author(Post post, DoxGraphQLContext context, {int size = 1}) async => null;
}
'''),
      );
      expect(
        out,
        contains(
          flat(
            "Field<i1.Post, DoxGraphQLContext>('author', graphqlString, "
            "description: 'Who wrote it.', args: <Argument>["
            "Argument('size', graphqlInt.nonNull, defaultValue: '1'),], "
            'resolve: (i1.Post s, ResolveInfo<DoxGraphQLContext> info) => '
            "i1.PostResolver().author(s, info.context, size: info.args.get<int>('size')!))",
          ),
        ),
      );
    });

    test('no GraphQL class: a schema with a placeholder query', () async {
      String out = flat(await _build('class A {}'));
      expect(out, contains(flat("'placeholder', graphqlBoolean.nonNull,")));
      expect(out, contains('=>true)'));
      expect(out, isNot(contains('dox_graphql_orm')));
      expect(out, isNot(contains('mutation:')));
    });

    test('a real query: no placeholder', () async {
      expect(await _build(_hello), isNot(contains('placeholder')));
    });
  });

  group('build errors |', () {
    Future<void> expectError(String code, String message) async {
      String out = await _build(code);
      expect(out, startsWith('ERROR:'));
      expect(out, contains(message));
    }

    test('a field type GraphQL can not show', () async {
      await expectError('''
$_hello
@GraphQLType()
class Post {
  final Map<String, int> meta = <String, int>{};
}
''', 'Post.meta: the type Map<String, int> can not be a GraphQL field.');
    });

    test('a return type GraphQL can not show', () async {
      await expectError('''
class R {
  @GraphQLQuery()
  Future<void> hello() async {}
}
''', 'R.hello: the type void can not be a GraphQL field.');
    });

    test('a class that is not a @GraphQLType', () async {
      await expectError('''
class Thing {}
class R {
  @GraphQLQuery()
  Thing thing() => Thing();
}
''', 'R.thing: the type Thing can not be a GraphQL field.');
    });

    test('an argument type GraphQL can not read', () async {
      await expectError('''
@GraphQLType()
class Post { final int id = 1; }
class R {
  @GraphQLQuery()
  int hello(Post post) => 1;
}
''', 'R.hello(post): the type Post can not be a GraphQL argument.');
    });

    test('a list of DTOs as an argument', () async {
      String out = await generate(<String, String>{
        'lib/app.dart':
            '''
$_imports
part 'app.g.dart';
@Dto()
class Line {
  Line({required this.name});
  final String name;
}
class R {
  @GraphQLQuery()
  int hello(List<Line> lines) => 1;
}
''',
      });
      expect(
        out,
        contains(
          'R.hello(lines): the type List<Line> can not be a GraphQL argument.',
        ),
      );
    });

    test('a DTO field GraphQL can not read', () async {
      String out = await generate(<String, String>{
        'lib/app.dart':
            '''
$_imports
part 'app.g.dart';
@Dto()
class Upload {
  Upload({required this.meta});
  final Map<String, dynamic> meta;
}
class R {
  @GraphQLQuery()
  int hello() => 1;
  @GraphQLMutation()
  int upload(Upload input) => 1;
}
''',
      });
      expect(
        out,
        contains(
          'Upload.meta: the type Map<String, dynamic> can not be a GraphQL '
          'input field.',
        ),
      );
    });

    test('a default value with no GraphQL form', () async {
      await expectError('''
class R {
  @GraphQLQuery()
  int hello({Duration wait = const Duration(seconds: 1)}) => 1;
}
''', 'R.hello(wait): the type Duration can not be a GraphQL argument.');
    });

    test('@GraphQLField on a method', () async {
      await expectError('''
$_hello
@GraphQLType()
class Post {
  @GraphQLField()
  String excerpt(int size) => '';
}
''', 'Post.excerpt: @GraphQLField() works on a getter or a field.');
    });

    test('@ResolveField with no parent type', () async {
      await expectError(
        '''
$_hello
class R {
  @ResolveField()
  String author(int id) => '';
}
''',
        'R.author: the first parameter of a @ResolveField() method must be the parent',
      );
    });

    test('two types with one name', () async {
      await expectError('''
$_hello
@GraphQLType(name: 'Post')
class A { final int id = 1; }
@GraphQLType(name: 'Post')
class B { final int id = 1; }
''', 'the GraphQL type name "Post" is used twice');
    });

    test('two root fields with one name', () async {
      await expectError('''
class R {
  @GraphQLQuery()
  String hello() => 'hi';
  @GraphQLQuery(name: 'hello')
  String other() => 'hi';
}
''', 'R.other: the field "hello" of Query is made twice: here and in R.hello.');
    });

    test('a field made twice on a type', () async {
      await expectError('''
$_hello
@GraphQLType()
class Post { final int id = 1; }
class R {
  @ResolveField()
  int id(Post post) => 1;
}
''', 'R.id: the field "id" of Post is made twice');
    });

    test('dto: on a plain class', () async {
      String out = await generate(<String, String>{
        'lib/app.dart':
            '''
$_imports
part 'app.g.dart';
$_hello
@Dto()
class In {
  In({required this.name});
  final String name;
}
@GraphQLType(dto: In)
class Post { final int id = 1; }
''',
      });
      expect(out, contains('Post: `dto:` works only on a model of dox_orm.'));
    });

    test('a private @GraphQLType class', () async {
      await expectError('''
$_hello
@GraphQLType()
class _Hidden { final int id = 1; }
''', '_Hidden: a @GraphQLType class can not be private');
    });

    test('a private enum as a field type', () async {
      await expectError('''
$_hello
enum _Priv { a, b }
@GraphQLType()
class Post { final _Priv kind = _Priv.a; }
''', '_Priv: a private enum can not be a GraphQL type');
    });

    test('a schema with no query', () async {
      await expectError('''
@GraphQLType()
class Post { final int id = 1; }
''', 'The GraphQL schema has no query.');
    });

    test('an abstract resolver', () async {
      await expectError('''
abstract class R {
  @GraphQLQuery()
  String hello() => 'hi';
}
''', 'R: a resolver class can not be abstract or generic');
    });

    test('a resolver with no unnamed constructor', () async {
      await expectError('''
class R {
  R.named();
  @GraphQLQuery()
  String hello() => 'hi';
}
''', 'R: a resolver class needs an unnamed constructor.');
    });

    test('a static resolver method', () async {
      await expectError('''
class R {
  @GraphQLQuery()
  static String hello() => 'hi';
}
''', 'R.hello: @GraphQLQuery() needs a public instance method.');
    });

    test('a name GraphQL does not allow', () async {
      await expectError('''
class R {
  @GraphQLQuery(name: '__hello')
  String hello() => 'hi';
}
''', 'R.hello: "__hello" is not a valid GraphQL name.');
    });
  });

  group('auth |', () {
    test('auth: on queries, mutations and @ResolveField', () async {
      String out = flat(
        await _build('''
@GraphQLType(auth: true)
class Book {
  final int id = 1;
}

class BookResolver {
  @GraphQLQuery(auth: false)
  String open() => 'o';

  @GraphQLQuery()
  String plain() => 'p';

  @GraphQLMutation(auth: true)
  int write() => 1;

  @ResolveField(auth: true)
  String secret(Book book) => 's';
}
'''),
      );
      expect(
        out,
        contains(flat("'open', graphqlString.nonNull, auth: false,")),
      );
      expect(out, contains(flat("'plain', graphqlString.nonNull, resolve:")));
      expect(out, contains(flat("'write', graphqlInt.nonNull, auth: true,")));
      expect(
        out,
        contains(flat("'secret', graphqlString.nonNull, auth: true,")),
      );
    });
  });
}
