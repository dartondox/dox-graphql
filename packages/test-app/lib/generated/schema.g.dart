// GENERATED CODE - DO NOT MODIFY BY HAND
// Made by dox_graphql_builder. Run `dart run build_runner build`.
// ignore_for_file: type=lint

import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_orm/dox_graphql_orm.dart';
import 'package:dox_auth/dox_auth.dart' show Gate;
import 'package:dox_graphql_test_app/app/graphql/types.dart' as i1;
import 'package:dox_graphql_test_app/app/models/account/account.model.dart'
    as i2;
import 'package:dox_graphql_test_app/app/models/article/article.model.dart'
    as i3;
import 'package:dox_graphql_test_app/app/models/comment/comment.model.dart'
    as i4;
import 'package:dox_graphql_test_app/app/models/image/image.model.dart' as i5;
import 'package:dox_graphql_test_app/app/models/member/member.model.dart' as i6;
import 'package:dox_graphql_test_app/app/models/post/post.model.dart' as i7;
import 'package:dox_graphql_test_app/app/models/profile/profile.model.dart'
    as i8;
import 'package:dox_graphql_test_app/app/models/tag/tag.model.dart' as i9;
import 'package:dox_graphql_test_app/app/models/user/user.model.dart' as i10;
import 'package:dox_graphql_test_app/app/dtos/article_dto.dart' as i11;
import 'package:dox_graphql_test_app/app/dtos/member_dto.dart' as i12;
import 'package:dox_graphql_test_app/app/dtos/create_post.dart' as i13;
import 'package:dox_graphql_test_app/app/repositories/repositories.dart' as i14;
import 'package:dox_graphql_test_app/app/graphql/book.resolver.dart' as i15;
import 'package:dox_graphql_test_app/app/dtos/create_book.dart' as i16;
import 'package:dox_graphql_test_app/app/graphql/math.resolver.dart' as i17;
import 'package:dox_graphql_test_app/app/services/post_service.dart' as i18;
import 'package:dox_graphql_test_app/app/graphql/post.resolver.dart' as i19;

/// The GraphQL schema of the app, made from the
/// `@GraphQLType`, `@GraphQLQuery` and `@GraphQLMutation` annotations.
/// Use it in `GraphQLConfig(schema: graphqlSchema)`.
final GraphQLSchema<DoxGraphQLContext>
graphqlSchema = GraphQLSchema<DoxGraphQLContext>(
  query: ObjectType<Object?, DoxGraphQLContext>(
    'Query',
    fields: () => <Field<Object?, DoxGraphQLContext>>[
      AutoField<Object?, DoxGraphQLContext>(
        'accounts',
        _tAccount.nonNull.list.nonNull,
        args: <Argument>[
          Argument('limit', graphqlInt, defaultValue: '20'),
          Argument('offset', graphqlInt, defaultValue: '0'),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.list<i2.Account>(i2.Account(), info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'account',
        _tAccount,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.find<i2.Account>(
              i2.Account(),
              int.tryParse(info.args.get<String>('id')!),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'articles',
        _tArticle.nonNull.list.nonNull,
        auth: false,
        args: <Argument>[
          Argument('limit', graphqlInt, defaultValue: '20'),
          Argument('offset', graphqlInt, defaultValue: '0'),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.list<i3.Article>(i3.Article(), info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'article',
        _tArticle,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.find<i3.Article>(
              i3.Article(),
              int.tryParse(info.args.get<String>('id')!),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'members',
        _tMember.nonNull.list.nonNull,
        auth: true,
        args: <Argument>[
          Argument('limit', graphqlInt, defaultValue: '20'),
          Argument('offset', graphqlInt, defaultValue: '0'),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.list<i6.Member>(i6.Member(), info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'member',
        _tMember,
        auth: true,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.find<i6.Member>(
              i6.Member(),
              int.tryParse(info.args.get<String>('id')!),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'posts',
        _tPost.nonNull.list.nonNull,
        auth: false,
        args: <Argument>[
          Argument('limit', graphqlInt, defaultValue: '20'),
          Argument('offset', graphqlInt, defaultValue: '0'),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.list<i7.Post>(i7.Post(), info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'post',
        _tPost,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.find<i7.Post>(
              i7.Post(),
              int.tryParse(info.args.get<String>('id')!),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'users',
        _tUser.nonNull.list.nonNull,
        auth: true,
        args: <Argument>[
          Argument('limit', graphqlInt, defaultValue: '20'),
          Argument('offset', graphqlInt, defaultValue: '0'),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.list<i10.User>(i10.User(), info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'user',
        _tUser,
        auth: true,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.find<i10.User>(
              i10.User(),
              int.tryParse(info.args.get<String>('id')!),
            ),
      ),
      Field<Object?, DoxGraphQLContext>(
        'books',
        _tBook.nonNull.list.nonNull,
        description: 'The latest books.',
        args: <Argument>[
          Argument('limit', graphqlInt.nonNull, defaultValue: '20'),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i15.BookResolver(
              info.context.make<i14.BookRepository>(),
              info.context.make<i14.AuthorRepository>(),
            ).books(limit: info.args.get<int>('limit')!),
      ),
      Field<Object?, DoxGraphQLContext>(
        'book',
        _tBook,
        args: <Argument>[Argument('id', graphqlInt.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i15.BookResolver(
              info.context.make<i14.BookRepository>(),
              info.context.make<i14.AuthorRepository>(),
            ).book(info.args.get<int>('id')!),
      ),
      Field<Object?, DoxGraphQLContext>(
        'me',
        graphqlString,
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i15.BookResolver(
              info.context.make<i14.BookRepository>(),
              info.context.make<i14.AuthorRepository>(),
            ).me(info.context),
      ),
      Field<Object?, DoxGraphQLContext>(
        'rowSums',
        graphqlInt.nonNull.list.nonNull,
        description: 'The sum of each row.',
        args: <Argument>[
          Argument('rows', graphqlInt.nonNull.list.nonNull.list.nonNull),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i17.MathResolver().rowSums(
              (switch (info.args.get<Object?>('rows')) {
                List<Object?> l1 => <List<int>>[
                  for (Object? x1 in l1)
                    (switch (x1) {
                      List<Object?> l2 => <int>[
                        for (Object? x2 in l2) (x2 as int),
                      ],
                      _ => null,
                    })!,
                ],
                _ => null,
              })!,
            ),
      ),
      Field<Object?, DoxGraphQLContext>(
        'path',
        graphqlString.nonNull,
        description:
            'The path of the request. Public, even with the auth middleware.',
        auth: false,
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i17.MathResolver().path(info.context),
      ),
      Field<Object?, DoxGraphQLContext>(
        'postsWithUsers',
        _tPost.nonNull.list.nonNull,
        description: 'The posts, with their users preloaded.',
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i19.PostResolver(info.context.make<i18.PostService>())
                .postsWithUsers(),
      ),
    ],
  ),
  mutation: ObjectType<Object?, DoxGraphQLContext>(
    'Mutation',
    fields: () => <Field<Object?, DoxGraphQLContext>>[
      AutoField<Object?, DoxGraphQLContext>(
        'createArticle',
        _tArticle.nonNull,
        auth: false,
        args: <Argument>[Argument('input', _iCreateArticleInput.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _createArticle(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'updateArticle',
        _tArticle,
        auth: false,
        args: <Argument>[
          Argument('id', graphqlId.nonNull),
          Argument('input', _iUpdateArticleInput.nonNull),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _updateArticle(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'deleteArticle',
        graphqlBoolean.nonNull,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _deleteArticle(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'createMember',
        _tMember.nonNull,
        auth: true,
        args: <Argument>[Argument('input', _iCreateMemberInput.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _createMember(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'updateMember',
        _tMember,
        auth: true,
        args: <Argument>[
          Argument('id', graphqlId.nonNull),
          Argument('input', _iUpdateMemberInput.nonNull),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _updateMember(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'deleteMember',
        graphqlBoolean.nonNull,
        auth: true,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _deleteMember(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'createPost',
        _tPost.nonNull,
        auth: false,
        args: <Argument>[Argument('input', _iCreatePostInput.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _createPost(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'updatePost',
        _tPost,
        auth: false,
        args: <Argument>[
          Argument('id', graphqlId.nonNull),
          Argument('input', _iUpdatePostInput.nonNull),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _updatePost(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'deletePost',
        graphqlBoolean.nonNull,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _deletePost(info),
      ),
      Field<Object?, DoxGraphQLContext>(
        'createBook',
        _tBook.nonNull,
        args: <Argument>[Argument('input', _iCreateBookInput.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) async =>
            i15.BookResolver(
              info.context.make<i14.BookRepository>(),
              info.context.make<i14.AuthorRepository>(),
            ).createBook(
              await _vCreateBookInput(info.args.input('input')!, info.context),
            ),
      ),
    ],
  ),
  types: <NamedType>[
    _tAuthor,
    _tBook,
    _tAccount,
    _tArticle,
    _tComment,
    _tImage,
    _tMember,
    _tPost,
    _tProfile,
    _tTag,
    _tUser,
  ],
);

final ObjectType<i1.Author, DoxGraphQLContext> _tAuthor =
    ObjectType<i1.Author, DoxGraphQLContext>(
      'Author',
      description: 'A writer of books. A plain class: it has no table. `name` comes from\n[Person].',
      fields: () => <Field<i1.Author, DoxGraphQLContext>>[
        Field<i1.Author, DoxGraphQLContext>(
          'id',
          graphqlInt.nonNull,
          resolve: (i1.Author s, ResolveInfo<DoxGraphQLContext> info) => s.id,
        ),
        Field<i1.Author, DoxGraphQLContext>(
          'name',
          graphqlString.nonNull,
          resolve: (i1.Author s, ResolveInfo<DoxGraphQLContext> info) => s.name,
        ),
      ],
    );

final ObjectType<i1.BookItem, DoxGraphQLContext> _tBook =
    ObjectType<i1.BookItem, DoxGraphQLContext>(
      'Book',
      description: 'A book.',
      fields: () => <Field<i1.BookItem, DoxGraphQLContext>>[
        Field<i1.BookItem, DoxGraphQLContext>(
          'id',
          graphqlInt.nonNull,
          resolve: (i1.BookItem s, ResolveInfo<DoxGraphQLContext> info) => s.id,
        ),
        Field<i1.BookItem, DoxGraphQLContext>(
          'title',
          graphqlString.nonNull,
          resolve: (i1.BookItem s, ResolveInfo<DoxGraphQLContext> info) =>
              s.title,
        ),
        Field<i1.BookItem, DoxGraphQLContext>(
          'genre',
          _eGenre.nonNull,
          resolve: (i1.BookItem s, ResolveInfo<DoxGraphQLContext> info) =>
              s.genre,
        ),
        Field<i1.BookItem, DoxGraphQLContext>(
          'publishedAt',
          graphqlDateTime,
          resolve: (i1.BookItem s, ResolveInfo<DoxGraphQLContext> info) =>
              s.publishedAt,
        ),
        Field<i1.BookItem, DoxGraphQLContext>(
          'shout',
          graphqlString.nonNull,
          description: 'The title in upper case.',
          resolve: (i1.BookItem s, ResolveInfo<DoxGraphQLContext> info) =>
              s.shout,
        ),
        Field<i1.BookItem, DoxGraphQLContext>(
          'author',
          _tAuthor,
          resolve: (i1.BookItem s, ResolveInfo<DoxGraphQLContext> info) =>
              i15.BookResolver(
                info.context.make<i14.BookRepository>(),
                info.context.make<i14.AuthorRepository>(),
              ).author(s, info.context),
        ),
      ],
    );

final ObjectType<i2.Account, DoxGraphQLContext> _tAccount =
    ObjectType<i2.Account, DoxGraphQLContext>(
      'Account',
      description: '`visibleFields` keeps only these fields.',
      fields: () {
        i2.Account model = i2.Account();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i2.Account, DoxGraphQLContext>>[
          if (show('id'))
            Field<i2.Account, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i2.Account s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('name'))
            Field<i2.Account, DoxGraphQLContext>(
              'name',
              graphqlString,
              resolve: (i2.Account s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.name,
            ),
          if (show('email'))
            Field<i2.Account, DoxGraphQLContext>(
              'email',
              graphqlString,
              resolve: (i2.Account s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.email,
            ),
          if (show('secret'))
            Field<i2.Account, DoxGraphQLContext>(
              'secret',
              graphqlString,
              resolve: (i2.Account s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.secret,
            ),
        ];
      },
    );

final ObjectType<i3.Article, DoxGraphQLContext> _tArticle =
    ObjectType<i3.Article, DoxGraphQLContext>(
      'Article',
      auth: false,
      fields: () {
        i3.Article model = i3.Article();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i3.Article, DoxGraphQLContext>>[
          if (show('id'))
            Field<i3.Article, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i3.Article s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('title'))
            Field<i3.Article, DoxGraphQLContext>(
              'title',
              graphqlString,
              resolve: (i3.Article s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.title,
            ),
          if (show('user_id'))
            Field<i3.Article, DoxGraphQLContext>(
              'userId',
              graphqlInt,
              resolve: (i3.Article s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.userId,
            ),
          if (show('user'))
            Field<i3.Article, DoxGraphQLContext>(
              'user',
              _tUser,
              resolve: (i3.Article s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i3.Article, i10.User?>(
                    s,
                    'user',
                    info.context,
                    (i3.Article p) => p.user,
                  ),
            ),
        ];
      },
    );

final ObjectType<i4.Comment, DoxGraphQLContext> _tComment =
    ObjectType<i4.Comment, DoxGraphQLContext>(
      'Comment',
      description: 'Only reachable through `post.comments`.',
      fields: () {
        i4.Comment model = i4.Comment();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i4.Comment, DoxGraphQLContext>>[
          if (show('id'))
            Field<i4.Comment, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i4.Comment s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('body'))
            Field<i4.Comment, DoxGraphQLContext>(
              'body',
              graphqlString,
              resolve: (i4.Comment s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.body,
            ),
          if (show('post_id'))
            Field<i4.Comment, DoxGraphQLContext>(
              'postId',
              graphqlInt,
              resolve: (i4.Comment s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.postId,
            ),
          if (show('post'))
            Field<i4.Comment, DoxGraphQLContext>(
              'post',
              _tPost,
              resolve: (i4.Comment s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i4.Comment, i7.Post?>(
                    s,
                    'post',
                    info.context,
                    (i4.Comment p) => p.post,
                  ),
            ),
        ];
      },
    );

final ObjectType<i5.Image, DoxGraphQLContext> _tImage =
    ObjectType<i5.Image, DoxGraphQLContext>(
      'Image',
      fields: () {
        i5.Image model = i5.Image();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i5.Image, DoxGraphQLContext>>[
          if (show('id'))
            Field<i5.Image, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i5.Image s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('url'))
            Field<i5.Image, DoxGraphQLContext>(
              'url',
              graphqlString,
              resolve: (i5.Image s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.url,
            ),
        ];
      },
    );

final ObjectType<i6.Member, DoxGraphQLContext> _tMember =
    ObjectType<i6.Member, DoxGraphQLContext>(
      'Member',
      description: '`hidden` leaves out a column and a relation.',
      auth: true,
      fields: () {
        i6.Member model = i6.Member();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i6.Member, DoxGraphQLContext>>[
          if (show('id'))
            Field<i6.Member, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i6.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('name'))
            Field<i6.Member, DoxGraphQLContext>(
              'name',
              graphqlString,
              resolve: (i6.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.name,
            ),
          if (show('email'))
            Field<i6.Member, DoxGraphQLContext>(
              'email',
              graphqlString,
              resolve: (i6.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.email,
            ),
          if (show('secret'))
            Field<i6.Member, DoxGraphQLContext>(
              'secret',
              graphqlString,
              resolve: (i6.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.secret,
            ),
          if (show('profile'))
            Field<i6.Member, DoxGraphQLContext>(
              'profile',
              _tProfile,
              resolve: (i6.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i6.Member, i8.Profile?>(
                    s,
                    'profile',
                    info.context,
                    (i6.Member p) => p.profile,
                  ),
            ),
        ];
      },
    );

final ObjectType<i7.Post, DoxGraphQLContext> _tPost =
    ObjectType<i7.Post, DoxGraphQLContext>(
      'Post',
      auth: false,
      fields: () {
        i7.Post model = i7.Post();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i7.Post, DoxGraphQLContext>>[
          if (show('id'))
            Field<i7.Post, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) => s.id,
            ),
          if (show('title'))
            Field<i7.Post, DoxGraphQLContext>(
              'title',
              graphqlString,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.title,
            ),
          if (show('body'))
            Field<i7.Post, DoxGraphQLContext>(
              'body',
              graphqlString,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.body,
            ),
          if (show('user_id'))
            Field<i7.Post, DoxGraphQLContext>(
              'userId',
              graphqlInt,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.userId,
            ),
          if (show('status'))
            Field<i7.Post, DoxGraphQLContext>(
              'status',
              _ePostStatus,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.status,
            ),
          if (show('user'))
            Field<i7.Post, DoxGraphQLContext>(
              'user',
              _tUser,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i7.Post, i10.User?>(
                    s,
                    'user',
                    info.context,
                    (i7.Post p) => p.user,
                  ),
            ),
          if (show('comments'))
            Field<i7.Post, DoxGraphQLContext>(
              'comments',
              _tComment.nonNull.list.nonNull,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i7.Post, List<i4.Comment>>(
                    s,
                    'comments',
                    info.context,
                    (i7.Post p) => p.comments,
                  ),
            ),
          if (show('tags'))
            Field<i7.Post, DoxGraphQLContext>(
              'tags',
              _tTag.nonNull.list.nonNull,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i7.Post, List<i9.Tag>>(
                    s,
                    'tags',
                    info.context,
                    (i7.Post p) => p.tags,
                  ),
            ),
          if (show('images'))
            Field<i7.Post, DoxGraphQLContext>(
              'images',
              _tImage.nonNull.list.nonNull,
              resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i7.Post, List<i5.Image>>(
                    s,
                    'images',
                    info.context,
                    (i7.Post p) => p.images,
                  ),
            ),
          Field<i7.Post, DoxGraphQLContext>(
            'excerpt',
            graphqlString.nonNull,
            description: 'The first 5 letters of the body.',
            resolve: (i7.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                s.excerpt,
          ),
        ];
      },
    );

final ObjectType<i8.Profile, DoxGraphQLContext> _tProfile =
    ObjectType<i8.Profile, DoxGraphQLContext>(
      'Profile',
      fields: () {
        i8.Profile model = i8.Profile();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i8.Profile, DoxGraphQLContext>>[
          if (show('id'))
            Field<i8.Profile, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i8.Profile s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('bio'))
            Field<i8.Profile, DoxGraphQLContext>(
              'bio',
              graphqlString,
              resolve: (i8.Profile s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.bio,
            ),
          if (show('user_id'))
            Field<i8.Profile, DoxGraphQLContext>(
              'userId',
              graphqlInt,
              resolve: (i8.Profile s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.userId,
            ),
          if (show('member_id'))
            Field<i8.Profile, DoxGraphQLContext>(
              'memberId',
              graphqlInt,
              resolve: (i8.Profile s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.memberId,
            ),
        ];
      },
    );

final ObjectType<i9.Tag, DoxGraphQLContext> _tTag =
    ObjectType<i9.Tag, DoxGraphQLContext>(
      'Tag',
      fields: () {
        i9.Tag model = i9.Tag();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i9.Tag, DoxGraphQLContext>>[
          if (show('id'))
            Field<i9.Tag, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i9.Tag s, ResolveInfo<DoxGraphQLContext> info) => s.id,
            ),
          if (show('name'))
            Field<i9.Tag, DoxGraphQLContext>(
              'name',
              graphqlString,
              resolve: (i9.Tag s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.name,
            ),
        ];
      },
    );

final ObjectType<i10.User, DoxGraphQLContext>
_tUser = ObjectType<i10.User, DoxGraphQLContext>(
  'User',
  description: 'Every field that gives a User needs a login, also `post.user`.',
  auth: true,
  fields: () {
    i10.User model = i10.User();
    List<String> hidden = model.hidden;
    List<String> visible = model.visibleFields;
    bool show(String name) =>
        !hidden.contains(name) && (visible.isEmpty || visible.contains(name));
    return <Field<i10.User, DoxGraphQLContext>>[
      if (show('id'))
        Field<i10.User, DoxGraphQLContext>(
          'id',
          graphqlId.nonNull,
          resolve: (i10.User s, ResolveInfo<DoxGraphQLContext> info) => s.id,
        ),
      if (show('name'))
        Field<i10.User, DoxGraphQLContext>(
          'name',
          graphqlString,
          resolve: (i10.User s, ResolveInfo<DoxGraphQLContext> info) => s.name,
        ),
      if (show('password'))
        Field<i10.User, DoxGraphQLContext>(
          'password',
          graphqlString,
          resolve: (i10.User s, ResolveInfo<DoxGraphQLContext> info) =>
              s.password,
        ),
      if (show('posts'))
        Field<i10.User, DoxGraphQLContext>(
          'posts',
          _tPost.nonNull.list.nonNull,
          resolve: (i10.User s, ResolveInfo<DoxGraphQLContext> info) =>
              GraphQLOrm.relation<i10.User, List<i7.Post>>(
                s,
                'posts',
                info.context,
                (i10.User p) => p.posts,
              ),
        ),
      if (show('profile'))
        Field<i10.User, DoxGraphQLContext>(
          'profile',
          _tProfile,
          resolve: (i10.User s, ResolveInfo<DoxGraphQLContext> info) =>
              GraphQLOrm.relation<i10.User, i8.Profile?>(
                s,
                'profile',
                info.context,
                (i10.User p) => p.profile,
              ),
        ),
      if (show('articles'))
        Field<i10.User, DoxGraphQLContext>(
          'articles',
          _tArticle.nonNull.list.nonNull,
          resolve: (i10.User s, ResolveInfo<DoxGraphQLContext> info) =>
              GraphQLOrm.relation<i10.User, List<i3.Article>>(
                s,
                'articles',
                info.context,
                (i10.User p) => p.articles,
              ),
        ),
    ];
  },
);

final EnumType<i1.Genre> _eGenre = EnumType<i1.Genre>(
  'Genre',
  <EnumValue<i1.Genre>>[
    EnumValue<i1.Genre>('novel', i1.Genre.novel),
    EnumValue<i1.Genre>('poetry', i1.Genre.poetry),
  ],
);

final EnumType<i7.PostStatus> _ePostStatus = EnumType<i7.PostStatus>(
  'PostStatus',
  <EnumValue<i7.PostStatus>>[
    EnumValue<i7.PostStatus>('draft', i7.PostStatus.draft),
    EnumValue<i7.PostStatus>('published', i7.PostStatus.published),
  ],
);

final InputObjectType _iCreateArticleInput = InputObjectType(
  'CreateArticleInput',
  fields: () => <InputField>[InputField('title', graphqlString)],
);

Map<String, Object?> _mCreateArticleInput(InputValues v) {
  return <String, Object?>{
    if (v.has('title')) 'title': v.get<Object?>('title'),
  };
}

Future<i11.ArticleDto> _vCreateArticleInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i11.ArticleDto>(
    i11.$ArticleDtoDto,
    _mCreateArticleInput(v),
    context,
    names: const <String, String>{},
  );
}

final InputObjectType _iUpdateArticleInput = InputObjectType(
  'UpdateArticleInput',
  fields: () => <InputField>[InputField('title', graphqlString)],
);

Map<String, Object?> _mUpdateArticleInput(InputValues v) {
  return <String, Object?>{
    if (v.has('title')) 'title': v.get<Object?>('title'),
  };
}

final InputObjectType _iCreateMemberInput = InputObjectType(
  'CreateMemberInput',
  description: '`@Unique` has no `ignoreParam`: an update that does not send `name`\nmust not check it.',
  fields: () => <InputField>[
    InputField('name', graphqlString),
    InputField('email', graphqlString),
  ],
);

Map<String, Object?> _mCreateMemberInput(InputValues v) {
  return <String, Object?>{
    if (v.has('name')) 'name': v.get<Object?>('name'),
    if (v.has('email')) 'email': v.get<Object?>('email'),
  };
}

Future<i12.MemberDto> _vCreateMemberInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i12.MemberDto>(
    i12.$MemberDtoDto,
    _mCreateMemberInput(v),
    context,
    names: const <String, String>{},
  );
}

final InputObjectType _iUpdateMemberInput = InputObjectType(
  'UpdateMemberInput',
  description: '`@Unique` has no `ignoreParam`: an update that does not send `name`\nmust not check it.',
  fields: () => <InputField>[
    InputField('name', graphqlString),
    InputField('email', graphqlString),
  ],
);

Map<String, Object?> _mUpdateMemberInput(InputValues v) {
  return <String, Object?>{
    if (v.has('name')) 'name': v.get<Object?>('name'),
    if (v.has('email')) 'email': v.get<Object?>('email'),
  };
}

final InputObjectType _iCreatePostInput = InputObjectType(
  'CreatePostInput',
  description: 'The fields a client may set on a post. `userId` is not here, so a\nclient can not set it.',
  fields: () => <InputField>[
    InputField('title', graphqlString),
    InputField('body', graphqlString),
    InputField('status', _ePostStatus),
  ],
);

Map<String, Object?> _mCreatePostInput(InputValues v) {
  return <String, Object?>{
    if (v.has('title')) 'title': v.get<Object?>('title'),
    if (v.has('body')) 'body': v.get<Object?>('body'),
    if (v.has('status'))
      'status': switch (v.get<Object?>('status')) {
        i7.PostStatus e1 => e1.name,
        _ => null,
      },
  };
}

Future<i13.CreatePostDto> _vCreatePostInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i13.CreatePostDto>(
    i13.$CreatePostDtoDto,
    _mCreatePostInput(v),
    context,
    names: const <String, String>{},
  );
}

final InputObjectType _iUpdatePostInput = InputObjectType(
  'UpdatePostInput',
  description: 'The fields a client may set on a post. `userId` is not here, so a\nclient can not set it.',
  fields: () => <InputField>[
    InputField('title', graphqlString),
    InputField('body', graphqlString),
    InputField('status', _ePostStatus),
  ],
);

Map<String, Object?> _mUpdatePostInput(InputValues v) {
  return <String, Object?>{
    if (v.has('title')) 'title': v.get<Object?>('title'),
    if (v.has('body')) 'body': v.get<Object?>('body'),
    if (v.has('status'))
      'status': switch (v.get<Object?>('status')) {
        i7.PostStatus e1 => e1.name,
        _ => null,
      },
  };
}

final InputObjectType _iCreateBookInput = InputObjectType(
  'CreateBookInput',
  fields: () => <InputField>[
    InputField('title', graphqlString),
    InputField('authorId', graphqlInt),
    InputField('genre', _eGenre),
  ],
);

Map<String, Object?> _mCreateBookInput(InputValues v) {
  return <String, Object?>{
    if (v.has('title')) 'title': v.get<Object?>('title'),
    if (v.has('authorId')) 'author_id': v.get<Object?>('authorId'),
    if (v.has('genre'))
      'genre': switch (v.get<Object?>('genre')) {
        i1.Genre e1 => e1.name,
        _ => null,
      },
  };
}

Future<i16.CreateBook> _vCreateBookInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i16.CreateBook>(
    i16.$CreateBookDto,
    _mCreateBookInput(v),
    context,
    names: const <String, String>{'author_id': 'authorId'},
  );
}

/// Makes a Article from the input of `createArticle`.
Future<i3.Article> _createArticle(ResolveInfo<DoxGraphQLContext> info) async {
  i11.ArticleDto dto = await _vCreateArticleInput(
    info.args.input('input')!,
    info.context,
  );
  i3.Article model = i3.Article()..title = dto.title;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Article. Null when there is no
/// Article with that id.
Future<i3.Article?> _updateArticle(ResolveInfo<DoxGraphQLContext> info) async {
  i3.Article? model = await GraphQLOrm.find<i3.Article>(
    i3.Article(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) return null;
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdateArticleInput(input);
  // the other fields keep their stored values, and are not checked
  i11.ArticleDto dto = await GraphQLDto.validateSent<i11.ArticleDto>(
    i11.$ArticleDtoDto,
    <String, Object?>{'title': model.title, ...given},
    info.context,
    sent: given.keys.toSet(),
    placeholders: const <String, Object?>{'title': '-'},
    names: const <String, String>{},
    params: <String, String>{'id': '${model.id}'},
  );
  if (input.has('title')) model.title = dto.title;
  await model.save();
  return model;
}

/// Deletes a Article. False when there is no Article with that id.
Future<bool> _deleteArticle(ResolveInfo<DoxGraphQLContext> info) async {
  i3.Article? model = await GraphQLOrm.find<i3.Article>(
    i3.Article(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) return false;
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}

/// Makes a Member from the input of `createMember`.
Future<i6.Member> _createMember(ResolveInfo<DoxGraphQLContext> info) async {
  i12.MemberDto dto = await _vCreateMemberInput(
    info.args.input('input')!,
    info.context,
  );
  i6.Member model = i6.Member()
    ..name = dto.name
    ..email = dto.email;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Member. Null when there is no
/// Member with that id.
Future<i6.Member?> _updateMember(ResolveInfo<DoxGraphQLContext> info) async {
  i6.Member? model = await GraphQLOrm.find<i6.Member>(
    i6.Member(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) return null;
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdateMemberInput(input);
  // the other fields keep their stored values, and are not checked
  i12.MemberDto dto = await GraphQLDto.validateSent<i12.MemberDto>(
    i12.$MemberDtoDto,
    <String, Object?>{'name': model.name, 'email': model.email, ...given},
    info.context,
    sent: given.keys.toSet(),
    placeholders: const <String, Object?>{'name': '-', 'email': '-'},
    names: const <String, String>{},
    params: <String, String>{'id': '${model.id}'},
  );
  if (input.has('name')) model.name = dto.name;
  if (input.has('email')) model.email = dto.email;
  await model.save();
  return model;
}

/// Deletes a Member. False when there is no Member with that id.
Future<bool> _deleteMember(ResolveInfo<DoxGraphQLContext> info) async {
  i6.Member? model = await GraphQLOrm.find<i6.Member>(
    i6.Member(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) return false;
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}

/// Makes a Post from the input of `createPost`.
Future<i7.Post> _createPost(ResolveInfo<DoxGraphQLContext> info) async {
  i13.CreatePostDto dto = await _vCreatePostInput(
    info.args.input('input')!,
    info.context,
  );
  i7.Post model = i7.Post()
    ..title = dto.title
    ..body = dto.body
    ..status = dto.status;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Post. Null when there is no
/// Post with that id.
Future<i7.Post?> _updatePost(ResolveInfo<DoxGraphQLContext> info) async {
  i7.Post? model = await GraphQLOrm.find<i7.Post>(
    i7.Post(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) return null;
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdatePostInput(input);
  // the other fields keep their stored values, and are not checked
  i13.CreatePostDto dto = await GraphQLDto.validateSent<i13.CreatePostDto>(
    i13.$CreatePostDtoDto,
    <String, Object?>{
      'title': model.title,
      'body': model.body,
      'status': model.status?.name,
      ...given,
    },
    info.context,
    sent: given.keys.toSet(),
    placeholders: const <String, Object?>{
      'title': '-',
      'body': '-',
      'status': 'draft',
    },
    names: const <String, String>{},
    params: <String, String>{'id': '${model.id}'},
  );
  if (input.has('title')) model.title = dto.title;
  if (input.has('body')) model.body = dto.body;
  if (input.has('status')) model.status = dto.status;
  await model.save();
  return model;
}

/// Deletes a Post. False when there is no Post with that id.
Future<bool> _deletePost(ResolveInfo<DoxGraphQLContext> info) async {
  i7.Post? model = await GraphQLOrm.find<i7.Post>(
    i7.Post(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) return false;
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}

/// Asks the policy of [model] (registered with `Gate.policy`) if the user
/// may do [ability]. Throws "Forbidden" when not.
Future<void> _allow(
  ResolveInfo<DoxGraphQLContext> info,
  String ability,
  Object model,
) async {
  Object? user = await info.context.user<Object>();
  if (!await Gate.allows(user, ability, model)) throw GraphQLAuth.forbidden();
}
