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
import 'package:dox_graphql_test_app/app/models/doc/doc.model.dart' as i5;
import 'package:dox_graphql_test_app/app/models/image/image.model.dart' as i6;
import 'package:dox_graphql_test_app/app/models/member/member.model.dart' as i7;
import 'package:dox_graphql_test_app/app/models/note/note.model.dart' as i8;
import 'package:dox_graphql_test_app/app/models/post/post.model.dart' as i9;
import 'package:dox_graphql_test_app/app/models/profile/profile.model.dart'
    as i10;
import 'package:dox_graphql_test_app/app/models/tag/tag.model.dart' as i11;
import 'package:dox_graphql_test_app/app/models/user/user.model.dart' as i12;
import 'package:dox_graphql_test_app/app/dtos/article_dto.dart' as i13;
import 'package:dox_graphql_test_app/app/dtos/doc_dto.dart' as i14;
import 'package:dox_graphql_test_app/app/dtos/member_dto.dart' as i15;
import 'package:dox_graphql_test_app/app/dtos/note_dto.dart' as i16;
import 'package:dox_graphql_test_app/app/dtos/create_post.dart' as i17;
import 'package:dox_graphql_test_app/app/repositories/repositories.dart' as i18;
import 'package:dox_graphql_test_app/app/graphql/book.resolver.dart' as i19;
import 'package:dox_graphql_test_app/app/dtos/create_book.dart' as i20;
import 'package:dox_graphql_test_app/app/graphql/math.resolver.dart' as i21;
import 'package:dox_graphql_test_app/app/services/post_service.dart' as i22;
import 'package:dox_graphql_test_app/app/graphql/post.resolver.dart' as i23;

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
            _allowIf<i3.Article>(info, 'viewAny').then(
              (_) => _viewList<i3.Article>(
                info,
                GraphQLOrm.list<i3.Article>(i3.Article(), info),
              ),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'article',
        _tArticle,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _findArticle(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'docs',
        _tDoc.nonNull.list.nonNull,
        auth: false,
        args: <Argument>[
          Argument('limit', graphqlInt, defaultValue: '20'),
          Argument('offset', graphqlInt, defaultValue: '0'),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _allowIf<i5.Doc>(info, 'viewAny').then(
              (_) => _viewList<i5.Doc>(
                info,
                GraphQLOrm.list<i5.Doc>(i5.Doc(), info),
              ),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'doc',
        _tDoc,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _findDoc(info),
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
            _allowIf<i7.Member>(info, 'viewAny').then(
              (_) => _viewList<i7.Member>(
                info,
                GraphQLOrm.list<i7.Member>(i7.Member(), info),
              ),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'member',
        _tMember,
        auth: true,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _findMember(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'notes',
        _tNote.nonNull.list.nonNull,
        auth: false,
        args: <Argument>[
          Argument('limit', graphqlInt, defaultValue: '20'),
          Argument('offset', graphqlInt, defaultValue: '0'),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _allowIf<i8.Note>(info, 'viewAny').then(
              (_) => _viewList<i8.Note>(
                info,
                GraphQLOrm.list<i8.Note>(i8.Note(), info),
              ),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'note',
        _tNote,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _findNote(info),
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
            _allowIf<i9.Post>(info, 'viewAny').then(
              (_) => _viewList<i9.Post>(
                info,
                GraphQLOrm.list<i9.Post>(i9.Post(), info),
              ),
            ),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'post',
        _tPost,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _findPost(info),
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
            GraphQLOrm.list<i12.User>(i12.User(), info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'user',
        _tUser,
        auth: true,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            GraphQLOrm.find<i12.User>(
              i12.User(),
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
            i19.BookResolver(
              info.context.make<i18.BookRepository>(),
              info.context.make<i18.AuthorRepository>(),
            ).books(limit: info.args.get<int>('limit')!),
      ),
      Field<Object?, DoxGraphQLContext>(
        'book',
        _tBook,
        args: <Argument>[Argument('id', graphqlInt.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i19.BookResolver(
              info.context.make<i18.BookRepository>(),
              info.context.make<i18.AuthorRepository>(),
            ).book(info.args.get<int>('id')!),
      ),
      Field<Object?, DoxGraphQLContext>(
        'me',
        graphqlString,
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i19.BookResolver(
              info.context.make<i18.BookRepository>(),
              info.context.make<i18.AuthorRepository>(),
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
            i21.MathResolver().rowSums(
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
            i21.MathResolver().path(info.context),
      ),
      Field<Object?, DoxGraphQLContext>(
        'postsWithUsers',
        _tPost.nonNull.list.nonNull,
        description: 'The posts, with their users preloaded.',
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            i23.PostResolver(info.context.make<i22.PostService>())
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
        'createDoc',
        _tDoc.nonNull,
        auth: false,
        args: <Argument>[Argument('input', _iCreateDocInput.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _createDoc(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'updateDoc',
        _tDoc,
        auth: false,
        args: <Argument>[
          Argument('id', graphqlId.nonNull),
          Argument('input', _iUpdateDocInput.nonNull),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _updateDoc(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'deleteDoc',
        graphqlBoolean.nonNull,
        auth: false,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _deleteDoc(info),
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
        'createNote',
        _tNote.nonNull,
        auth: true,
        args: <Argument>[Argument('input', _iCreateNoteInput.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _createNote(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'updateNote',
        _tNote,
        auth: true,
        args: <Argument>[
          Argument('id', graphqlId.nonNull),
          Argument('input', _iUpdateNoteInput.nonNull),
        ],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _updateNote(info),
      ),
      AutoField<Object?, DoxGraphQLContext>(
        'deleteNote',
        graphqlBoolean.nonNull,
        auth: true,
        args: <Argument>[Argument('id', graphqlId.nonNull)],
        resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
            _deleteNote(info),
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
            i19.BookResolver(
              info.context.make<i18.BookRepository>(),
              info.context.make<i18.AuthorRepository>(),
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
    _tDoc,
    _tImage,
    _tMember,
    _tNote,
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
              i19.BookResolver(
                info.context.make<i18.BookRepository>(),
                info.context.make<i18.AuthorRepository>(),
              ).author(s, info.context),
        ),
      ],
    );

final ObjectType<i2.Account, DoxGraphQLContext> _tAccount =
    ObjectType<i2.Account, DoxGraphQLContext>(
      'Account',
      description: '`visibleFields` keeps only these fields. `docs` is a relation to a\nmodel whose policy has `viewAny`.',
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
          if (show('docs'))
            Field<i2.Account, DoxGraphQLContext>(
              'docs',
              _tDoc.nonNull.list,
              resolve: (i2.Account s, ResolveInfo<DoxGraphQLContext> info) =>
                  _allowIf<i5.Doc>(info, 'viewAny').then(
                    (_) => _viewList<i5.Doc>(
                      info,
                      GraphQLOrm.many<i2.Account, i5.Doc>(
                        s,
                        'docs',
                        info.context,
                        (i2.Account p) => p.docs,
                      ),
                    ),
                  ),
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
                  GraphQLOrm.relation<i3.Article, i12.User?>(
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
                  _allowIf<i9.Post>(info, 'viewAny').then(
                    (_) => _viewOne<i9.Post>(
                      info,
                      GraphQLOrm.relation<i4.Comment, i9.Post?>(
                        s,
                        'post',
                        info.context,
                        (i4.Comment p) => p.post,
                      ),
                    ),
                  ),
            ),
        ];
      },
    );

final ObjectType<i5.Doc, DoxGraphQLContext>
_tDoc = ObjectType<i5.Doc, DoxGraphQLContext>(
  'Doc',
  description: 'Its policy has `viewAny`, `view` and `create`: the reads and the create\nask it too.',
  auth: false,
  fields: () {
    i5.Doc model = i5.Doc();
    List<String> hidden = model.hidden;
    List<String> visible = model.visibleFields;
    bool show(String name) =>
        !hidden.contains(name) && (visible.isEmpty || visible.contains(name));
    return <Field<i5.Doc, DoxGraphQLContext>>[
      if (show('id'))
        Field<i5.Doc, DoxGraphQLContext>(
          'id',
          graphqlId.nonNull,
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) => s.id,
        ),
      if (show('title'))
        Field<i5.Doc, DoxGraphQLContext>(
          'title',
          graphqlString,
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) => s.title,
        ),
      if (show('owner'))
        Field<i5.Doc, DoxGraphQLContext>(
          'owner',
          graphqlString,
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) => s.owner,
        ),
      if (show('account_id'))
        Field<i5.Doc, DoxGraphQLContext>(
          'accountId',
          graphqlInt,
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) =>
              s.accountId,
        ),
      if (show('parent_id'))
        Field<i5.Doc, DoxGraphQLContext>(
          'parentId',
          graphqlInt,
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) =>
              s.parentId,
        ),
      if (show('parent'))
        Field<i5.Doc, DoxGraphQLContext>(
          'parent',
          _tDoc,
          description: 'A single relation to a model whose policy has `view`. It is not\nnullable in Dart: only the field can be null, not the parent.',
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) =>
              _allowIf<i5.Doc>(info, 'viewAny').then(
                (_) => _viewOne<i5.Doc>(
                  info,
                  GraphQLOrm.relation<i5.Doc, i5.Doc>(
                    s,
                    'parent',
                    info.context,
                    (i5.Doc p) => p.parent,
                  ),
                ),
              ),
        ),
      if (show('child'))
        Field<i5.Doc, DoxGraphQLContext>(
          'child',
          _tDoc,
          description: 'The doc whose parent this one is: a HasOne relation.',
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) =>
              _allowIf<i5.Doc>(info, 'viewAny').then(
                (_) => _viewOne<i5.Doc>(
                  info,
                  GraphQLOrm.relation<i5.Doc, i5.Doc?>(
                    s,
                    'child',
                    info.context,
                    (i5.Doc p) => p.child,
                  ),
                ),
              ),
        ),
    ];
  },
);

final ObjectType<i6.Image, DoxGraphQLContext> _tImage =
    ObjectType<i6.Image, DoxGraphQLContext>(
      'Image',
      fields: () {
        i6.Image model = i6.Image();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i6.Image, DoxGraphQLContext>>[
          if (show('id'))
            Field<i6.Image, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i6.Image s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('url'))
            Field<i6.Image, DoxGraphQLContext>(
              'url',
              graphqlString,
              resolve: (i6.Image s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.url,
            ),
        ];
      },
    );

final ObjectType<i7.Member, DoxGraphQLContext> _tMember =
    ObjectType<i7.Member, DoxGraphQLContext>(
      'Member',
      description: '`hidden` leaves out a column and a relation.',
      auth: true,
      fields: () {
        i7.Member model = i7.Member();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i7.Member, DoxGraphQLContext>>[
          if (show('id'))
            Field<i7.Member, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i7.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('name'))
            Field<i7.Member, DoxGraphQLContext>(
              'name',
              graphqlString,
              resolve: (i7.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.name,
            ),
          if (show('email'))
            Field<i7.Member, DoxGraphQLContext>(
              'email',
              graphqlString,
              resolve: (i7.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.email,
            ),
          if (show('secret'))
            Field<i7.Member, DoxGraphQLContext>(
              'secret',
              graphqlString,
              resolve: (i7.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.secret,
            ),
          if (show('profile'))
            Field<i7.Member, DoxGraphQLContext>(
              'profile',
              _tProfile,
              resolve: (i7.Member s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i7.Member, i10.Profile?>(
                    s,
                    'profile',
                    info.context,
                    (i7.Member p) => p.profile,
                  ),
            ),
        ];
      },
    );

final ObjectType<i8.Note, DoxGraphQLContext> _tNote =
    ObjectType<i8.Note, DoxGraphQLContext>(
      'Note',
      description: 'Public to read, but `owner:` makes create need a login. The create\nsets `userId` to the logged-in user.',
      auth: false,
      fields: () {
        i8.Note model = i8.Note();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i8.Note, DoxGraphQLContext>>[
          if (show('id'))
            Field<i8.Note, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i8.Note s, ResolveInfo<DoxGraphQLContext> info) => s.id,
            ),
          if (show('title'))
            Field<i8.Note, DoxGraphQLContext>(
              'title',
              graphqlString,
              resolve: (i8.Note s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.title,
            ),
          if (show('user_id'))
            Field<i8.Note, DoxGraphQLContext>(
              'userId',
              graphqlInt,
              resolve: (i8.Note s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.userId,
            ),
        ];
      },
    );

final ObjectType<i9.Post, DoxGraphQLContext> _tPost =
    ObjectType<i9.Post, DoxGraphQLContext>(
      'Post',
      auth: false,
      fields: () {
        i9.Post model = i9.Post();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i9.Post, DoxGraphQLContext>>[
          if (show('id'))
            Field<i9.Post, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) => s.id,
            ),
          if (show('title'))
            Field<i9.Post, DoxGraphQLContext>(
              'title',
              graphqlString,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.title,
            ),
          if (show('body'))
            Field<i9.Post, DoxGraphQLContext>(
              'body',
              graphqlString,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.body,
            ),
          if (show('user_id'))
            Field<i9.Post, DoxGraphQLContext>(
              'userId',
              graphqlInt,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.userId,
            ),
          if (show('status'))
            Field<i9.Post, DoxGraphQLContext>(
              'status',
              _ePostStatus,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.status,
            ),
          if (show('user'))
            Field<i9.Post, DoxGraphQLContext>(
              'user',
              _tUser,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.relation<i9.Post, i12.User?>(
                    s,
                    'user',
                    info.context,
                    (i9.Post p) => p.user,
                  ),
            ),
          if (show('comments'))
            Field<i9.Post, DoxGraphQLContext>(
              'comments',
              _tComment.nonNull.list,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.many<i9.Post, i4.Comment>(
                    s,
                    'comments',
                    info.context,
                    (i9.Post p) => p.comments,
                  ),
            ),
          if (show('tags'))
            Field<i9.Post, DoxGraphQLContext>(
              'tags',
              _tTag.nonNull.list,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.many<i9.Post, i11.Tag>(
                    s,
                    'tags',
                    info.context,
                    (i9.Post p) => p.tags,
                    pivot: true,
                  ),
            ),
          if (show('images'))
            Field<i9.Post, DoxGraphQLContext>(
              'images',
              _tImage.nonNull.list,
              resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  GraphQLOrm.many<i9.Post, i6.Image>(
                    s,
                    'images',
                    info.context,
                    (i9.Post p) => p.images,
                  ),
            ),
          Field<i9.Post, DoxGraphQLContext>(
            'excerpt',
            graphqlString.nonNull,
            description: 'The first 5 letters of the body.',
            resolve: (i9.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                s.excerpt,
          ),
        ];
      },
    );

final ObjectType<i10.Profile, DoxGraphQLContext> _tProfile =
    ObjectType<i10.Profile, DoxGraphQLContext>(
      'Profile',
      fields: () {
        i10.Profile model = i10.Profile();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i10.Profile, DoxGraphQLContext>>[
          if (show('id'))
            Field<i10.Profile, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i10.Profile s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (show('bio'))
            Field<i10.Profile, DoxGraphQLContext>(
              'bio',
              graphqlString,
              resolve: (i10.Profile s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.bio,
            ),
          if (show('user_id'))
            Field<i10.Profile, DoxGraphQLContext>(
              'userId',
              graphqlInt,
              resolve: (i10.Profile s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.userId,
            ),
          if (show('member_id'))
            Field<i10.Profile, DoxGraphQLContext>(
              'memberId',
              graphqlInt,
              resolve: (i10.Profile s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.memberId,
            ),
        ];
      },
    );

final ObjectType<i11.Tag, DoxGraphQLContext> _tTag =
    ObjectType<i11.Tag, DoxGraphQLContext>(
      'Tag',
      auth: false,
      fields: () {
        i11.Tag model = i11.Tag();
        List<String> hidden = model.hidden;
        List<String> visible = model.visibleFields;
        bool show(String name) =>
            !hidden.contains(name) &&
            (visible.isEmpty || visible.contains(name));
        return <Field<i11.Tag, DoxGraphQLContext>>[
          if (show('id'))
            Field<i11.Tag, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i11.Tag s, ResolveInfo<DoxGraphQLContext> info) => s.id,
            ),
          if (show('name'))
            Field<i11.Tag, DoxGraphQLContext>(
              'name',
              graphqlString,
              resolve: (i11.Tag s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.name,
            ),
        ];
      },
    );

final ObjectType<i12.User, DoxGraphQLContext>
_tUser = ObjectType<i12.User, DoxGraphQLContext>(
  'User',
  description: 'Every field that gives a User needs a login, also `post.user`.',
  auth: true,
  fields: () {
    i12.User model = i12.User();
    List<String> hidden = model.hidden;
    List<String> visible = model.visibleFields;
    bool show(String name) =>
        !hidden.contains(name) && (visible.isEmpty || visible.contains(name));
    return <Field<i12.User, DoxGraphQLContext>>[
      if (show('id'))
        Field<i12.User, DoxGraphQLContext>(
          'id',
          graphqlId.nonNull,
          resolve: (i12.User s, ResolveInfo<DoxGraphQLContext> info) => s.id,
        ),
      if (show('name'))
        Field<i12.User, DoxGraphQLContext>(
          'name',
          graphqlString,
          resolve: (i12.User s, ResolveInfo<DoxGraphQLContext> info) => s.name,
        ),
      if (show('password'))
        Field<i12.User, DoxGraphQLContext>(
          'password',
          graphqlString,
          resolve: (i12.User s, ResolveInfo<DoxGraphQLContext> info) =>
              s.password,
        ),
      if (show('posts'))
        Field<i12.User, DoxGraphQLContext>(
          'posts',
          _tPost.nonNull.list,
          resolve: (i12.User s, ResolveInfo<DoxGraphQLContext> info) =>
              _allowIf<i9.Post>(info, 'viewAny').then(
                (_) => _viewList<i9.Post>(
                  info,
                  GraphQLOrm.many<i12.User, i9.Post>(
                    s,
                    'posts',
                    info.context,
                    (i12.User p) => p.posts,
                  ),
                ),
              ),
        ),
      if (show('profile'))
        Field<i12.User, DoxGraphQLContext>(
          'profile',
          _tProfile,
          resolve: (i12.User s, ResolveInfo<DoxGraphQLContext> info) =>
              GraphQLOrm.relation<i12.User, i10.Profile?>(
                s,
                'profile',
                info.context,
                (i12.User p) => p.profile,
              ),
        ),
      if (show('articles'))
        Field<i12.User, DoxGraphQLContext>(
          'articles',
          _tArticle.nonNull.list,
          resolve: (i12.User s, ResolveInfo<DoxGraphQLContext> info) =>
              _allowIf<i3.Article>(info, 'viewAny').then(
                (_) => _viewList<i3.Article>(
                  info,
                  GraphQLOrm.many<i12.User, i3.Article>(
                    s,
                    'articles',
                    info.context,
                    (i12.User p) => p.articles,
                  ),
                ),
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

final EnumType<i9.PostStatus> _ePostStatus = EnumType<i9.PostStatus>(
  'PostStatus',
  <EnumValue<i9.PostStatus>>[
    EnumValue<i9.PostStatus>('draft', i9.PostStatus.draft),
    EnumValue<i9.PostStatus>('published', i9.PostStatus.published),
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

Future<i13.ArticleDto> _vCreateArticleInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i13.ArticleDto>(
    i13.$ArticleDtoDto,
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

final InputObjectType _iCreateDocInput = InputObjectType(
  'CreateDocInput',
  fields: () => <InputField>[InputField('title', graphqlString)],
);

Map<String, Object?> _mCreateDocInput(InputValues v) {
  return <String, Object?>{
    if (v.has('title')) 'title': v.get<Object?>('title'),
  };
}

Future<i14.DocDto> _vCreateDocInput(InputValues v, DoxGraphQLContext context) {
  return GraphQLDto.validate<i14.DocDto>(
    i14.$DocDtoDto,
    _mCreateDocInput(v),
    context,
    names: const <String, String>{},
  );
}

final InputObjectType _iUpdateDocInput = InputObjectType(
  'UpdateDocInput',
  fields: () => <InputField>[InputField('title', graphqlString)],
);

Map<String, Object?> _mUpdateDocInput(InputValues v) {
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

Future<i15.MemberDto> _vCreateMemberInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i15.MemberDto>(
    i15.$MemberDtoDto,
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

final InputObjectType _iCreateNoteInput = InputObjectType(
  'CreateNoteInput',
  fields: () => <InputField>[InputField('title', graphqlString)],
);

Map<String, Object?> _mCreateNoteInput(InputValues v) {
  return <String, Object?>{
    if (v.has('title')) 'title': v.get<Object?>('title'),
  };
}

Future<i16.NoteDto> _vCreateNoteInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i16.NoteDto>(
    i16.$NoteDtoDto,
    _mCreateNoteInput(v),
    context,
    names: const <String, String>{},
  );
}

final InputObjectType _iUpdateNoteInput = InputObjectType(
  'UpdateNoteInput',
  fields: () => <InputField>[InputField('title', graphqlString)],
);

Map<String, Object?> _mUpdateNoteInput(InputValues v) {
  return <String, Object?>{
    if (v.has('title')) 'title': v.get<Object?>('title'),
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
        i9.PostStatus e1 => e1.name,
        _ => null,
      },
  };
}

Future<i17.CreatePostDto> _vCreatePostInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i17.CreatePostDto>(
    i17.$CreatePostDtoDto,
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
        i9.PostStatus e1 => e1.name,
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

Future<i20.CreateBook> _vCreateBookInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i20.CreateBook>(
    i20.$CreateBookDto,
    _mCreateBookInput(v),
    context,
    names: const <String, String>{'author_id': 'authorId'},
  );
}

/// The Article with the id, after the `view` check of the policy when it has
/// one. A missing id is checked as a blank Article, so a user the policy
/// denies gets the same error for an id that exists and one that does not.
Future<i3.Article?> _findArticle(ResolveInfo<DoxGraphQLContext> info) async {
  bool view = Gate.hasAbility<i3.Article>('view');
  if (view) await _login(info);
  i3.Article? model = await GraphQLOrm.find<i3.Article>(
    i3.Article(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (view) {
    await (model == null
        ? _allowMissing(info, 'view', i3.Article())
        : _allow(info, 'view', model));
  }
  return model;
}

/// Makes a Article from the input of `createArticle`.
Future<i3.Article> _createArticle(ResolveInfo<DoxGraphQLContext> info) async {
  await _allowIf<i3.Article>(info, 'create');
  i13.ArticleDto dto = await _vCreateArticleInput(
    info.args.input('input')!,
    info.context,
  );
  i3.Article model = i3.Article()..title = dto.title;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Article. Null when there is no
/// Article with that id and the policy allows the update of a blank one.
Future<i3.Article?> _updateArticle(ResolveInfo<DoxGraphQLContext> info) async {
  await _login(info);
  i3.Article? model = await GraphQLOrm.find<i3.Article>(
    i3.Article(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'update', i3.Article());
    return null;
  }
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdateArticleInput(input);
  // the other fields keep their stored values, and are not checked
  i13.ArticleDto dto = await GraphQLDto.validateSent<i13.ArticleDto>(
    i13.$ArticleDtoDto,
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

/// Deletes a Article. False when there is no Article with that id and the
/// policy allows the delete of a blank one.
Future<bool> _deleteArticle(ResolveInfo<DoxGraphQLContext> info) async {
  await _login(info);
  i3.Article? model = await GraphQLOrm.find<i3.Article>(
    i3.Article(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'delete', i3.Article());
    return false;
  }
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}

/// The Doc with the id, after the `view` check of the policy when it has
/// one. A missing id is checked as a blank Doc, so a user the policy
/// denies gets the same error for an id that exists and one that does not.
Future<i5.Doc?> _findDoc(ResolveInfo<DoxGraphQLContext> info) async {
  bool view = Gate.hasAbility<i5.Doc>('view');
  if (view) await _login(info);
  i5.Doc? model = await GraphQLOrm.find<i5.Doc>(
    i5.Doc(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (view) {
    await (model == null
        ? _allowMissing(info, 'view', i5.Doc())
        : _allow(info, 'view', model));
  }
  return model;
}

/// Makes a Doc from the input of `createDoc`.
Future<i5.Doc> _createDoc(ResolveInfo<DoxGraphQLContext> info) async {
  await _allowIf<i5.Doc>(info, 'create');
  i14.DocDto dto = await _vCreateDocInput(
    info.args.input('input')!,
    info.context,
  );
  i5.Doc model = i5.Doc()..title = dto.title;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Doc. Null when there is no
/// Doc with that id and the policy allows the update of a blank one.
Future<i5.Doc?> _updateDoc(ResolveInfo<DoxGraphQLContext> info) async {
  await _login(info);
  i5.Doc? model = await GraphQLOrm.find<i5.Doc>(
    i5.Doc(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'update', i5.Doc());
    return null;
  }
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdateDocInput(input);
  // the other fields keep their stored values, and are not checked
  i14.DocDto dto = await GraphQLDto.validateSent<i14.DocDto>(
    i14.$DocDtoDto,
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

/// Deletes a Doc. False when there is no Doc with that id and the
/// policy allows the delete of a blank one.
Future<bool> _deleteDoc(ResolveInfo<DoxGraphQLContext> info) async {
  await _login(info);
  i5.Doc? model = await GraphQLOrm.find<i5.Doc>(
    i5.Doc(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'delete', i5.Doc());
    return false;
  }
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}

/// The Member with the id, after the `view` check of the policy when it has
/// one. A missing id is checked as a blank Member, so a user the policy
/// denies gets the same error for an id that exists and one that does not.
Future<i7.Member?> _findMember(ResolveInfo<DoxGraphQLContext> info) async {
  bool view = Gate.hasAbility<i7.Member>('view');
  if (view) await _login(info);
  i7.Member? model = await GraphQLOrm.find<i7.Member>(
    i7.Member(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (view) {
    await (model == null
        ? _allowMissing(info, 'view', i7.Member())
        : _allow(info, 'view', model));
  }
  return model;
}

/// Makes a Member from the input of `createMember`.
Future<i7.Member> _createMember(ResolveInfo<DoxGraphQLContext> info) async {
  await _allowIf<i7.Member>(info, 'create');
  i15.MemberDto dto = await _vCreateMemberInput(
    info.args.input('input')!,
    info.context,
  );
  i7.Member model = i7.Member()
    ..name = dto.name
    ..email = dto.email;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Member. Null when there is no
/// Member with that id and the policy allows the update of a blank one.
Future<i7.Member?> _updateMember(ResolveInfo<DoxGraphQLContext> info) async {
  await _login(info);
  i7.Member? model = await GraphQLOrm.find<i7.Member>(
    i7.Member(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'update', i7.Member());
    return null;
  }
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdateMemberInput(input);
  // the other fields keep their stored values, and are not checked
  i15.MemberDto dto = await GraphQLDto.validateSent<i15.MemberDto>(
    i15.$MemberDtoDto,
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

/// Deletes a Member. False when there is no Member with that id and the
/// policy allows the delete of a blank one.
Future<bool> _deleteMember(ResolveInfo<DoxGraphQLContext> info) async {
  await _login(info);
  i7.Member? model = await GraphQLOrm.find<i7.Member>(
    i7.Member(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'delete', i7.Member());
    return false;
  }
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}

/// The Note with the id, after the `view` check of the policy when it has
/// one. A missing id is checked as a blank Note, so a user the policy
/// denies gets the same error for an id that exists and one that does not.
Future<i8.Note?> _findNote(ResolveInfo<DoxGraphQLContext> info) async {
  bool view = Gate.hasAbility<i8.Note>('view');
  i8.Note? model = await GraphQLOrm.find<i8.Note>(
    i8.Note(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (view) {
    await (model == null
        ? _allowMissing(info, 'view', i8.Note())
        : _allow(info, 'view', model));
  }
  return model;
}

/// Makes a Note from the input of `createNote`.
Future<i8.Note> _createNote(ResolveInfo<DoxGraphQLContext> info) async {
  await _allowIf<i8.Note>(info, 'create');
  i16.NoteDto dto = await _vCreateNoteInput(
    info.args.input('input')!,
    info.context,
  );
  i8.Note model = i8.Note()..title = dto.title;
  model.userId = await GraphQLAuth.ownerId<int>(info.context, 'Note.userId');
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Note. Null when there is no
/// Note with that id and the policy allows the update of a blank one.
Future<i8.Note?> _updateNote(ResolveInfo<DoxGraphQLContext> info) async {
  i8.Note? model = await GraphQLOrm.find<i8.Note>(
    i8.Note(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'update', i8.Note());
    return null;
  }
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdateNoteInput(input);
  // the other fields keep their stored values, and are not checked
  i16.NoteDto dto = await GraphQLDto.validateSent<i16.NoteDto>(
    i16.$NoteDtoDto,
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

/// Deletes a Note. False when there is no Note with that id and the
/// policy allows the delete of a blank one.
Future<bool> _deleteNote(ResolveInfo<DoxGraphQLContext> info) async {
  i8.Note? model = await GraphQLOrm.find<i8.Note>(
    i8.Note(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'delete', i8.Note());
    return false;
  }
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}

/// The Post with the id, after the `view` check of the policy when it has
/// one. A missing id is checked as a blank Post, so a user the policy
/// denies gets the same error for an id that exists and one that does not.
Future<i9.Post?> _findPost(ResolveInfo<DoxGraphQLContext> info) async {
  bool view = Gate.hasAbility<i9.Post>('view');
  if (view) await _login(info);
  i9.Post? model = await GraphQLOrm.find<i9.Post>(
    i9.Post(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (view) {
    await (model == null
        ? _allowMissing(info, 'view', i9.Post())
        : _allow(info, 'view', model));
  }
  return model;
}

/// Makes a Post from the input of `createPost`.
Future<i9.Post> _createPost(ResolveInfo<DoxGraphQLContext> info) async {
  await _allowIf<i9.Post>(info, 'create');
  i17.CreatePostDto dto = await _vCreatePostInput(
    info.args.input('input')!,
    info.context,
  );
  i9.Post model = i9.Post()
    ..title = dto.title
    ..body = dto.body
    ..status = dto.status;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Post. Null when there is no
/// Post with that id and the policy allows the update of a blank one.
Future<i9.Post?> _updatePost(ResolveInfo<DoxGraphQLContext> info) async {
  await _login(info);
  i9.Post? model = await GraphQLOrm.find<i9.Post>(
    i9.Post(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'update', i9.Post());
    return null;
  }
  await _allow(info, 'update', model);
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdatePostInput(input);
  // the other fields keep their stored values, and are not checked
  i17.CreatePostDto dto = await GraphQLDto.validateSent<i17.CreatePostDto>(
    i17.$CreatePostDtoDto,
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

/// Deletes a Post. False when there is no Post with that id and the
/// policy allows the delete of a blank one.
Future<bool> _deletePost(ResolveInfo<DoxGraphQLContext> info) async {
  await _login(info);
  i9.Post? model = await GraphQLOrm.find<i9.Post>(
    i9.Post(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) {
    await _allowMissing(info, 'delete', i9.Post());
    return false;
  }
  await _allow(info, 'delete', model);
  await model.delete();
  return true;
}

/// Asks the policy (registered with `Gate.policy`) if the user may do
/// [ability] on [subject]: a row, or the model type. Throws when not:
/// "Unauthenticated" for a guest, else "Forbidden".
Future<void> _allow(
  ResolveInfo<DoxGraphQLContext> info,
  String ability,
  Object subject,
) async {
  Object? user = await info.context.user<Object>();
  if (!await Gate.allows(user, ability, subject)) throw _denied(user);
}

/// [_allow] for an id with no row: [blank] is a new, empty row. A user
/// the policy denies gets the same error as for a row that exists, so the
/// answer does not show which ids exist. A policy that fails to read the
/// empty row (a null check, a missing value) denies. Other errors, like a
/// database error, are thrown.
Future<void> _allowMissing(
  ResolveInfo<DoxGraphQLContext> info,
  String ability,
  Object blank,
) async {
  Object? user = await info.context.user<Object>();
  bool allowed;
  try {
    allowed = await Gate.allows(user, ability, blank);
  } on TypeError {
    allowed = false;
  } on StateError {
    allowed = false;
  } on NoSuchMethodError {
    allowed = false;
  }
  if (!allowed) throw _denied(user);
}

/// [_allow] on the model type [T], when the policy of [T] lists
/// [ability] (`viewAny`, `create`). Else nothing is checked.
Future<void> _allowIf<T>(
  ResolveInfo<DoxGraphQLContext> info,
  String ability,
) async {
  if (Gate.hasAbility<T>(ability)) await _allow(info, ability, T);
}

/// The rows of [rows] that the `view` ability of the policy allows, when
/// the policy of [T] lists `view`. The others are left out, with no error.
Future<List<T>?> _viewList<T extends Object>(
  ResolveInfo<DoxGraphQLContext> info,
  Future<List<T>?> rows,
) async {
  List<T>? list = await rows;
  if (list == null || list.isEmpty || !Gate.hasAbility<T>('view')) {
    return list;
  }
  Object? user = await info.context.user<Object>();
  return <T>[
    for (T row in list)
      if (await Gate.allows(user, 'view', row)) row,
  ];
}

/// [row] when the `view` ability of the policy allows it (or the policy
/// of [T] does not list `view`), else null.
Future<T?> _viewOne<T extends Object>(
  ResolveInfo<DoxGraphQLContext> info,
  Future<T?> row,
) async {
  T? value = await row;
  if (value == null || !Gate.hasAbility<T>('view')) return value;
  Object? user = await info.context.user<Object>();
  return await Gate.allows(user, 'view', value) ? value : null;
}

/// "Unauthenticated" before the row lookup, when the policy denies every
/// guest.
Future<void> _login(ResolveInfo<DoxGraphQLContext> info) async {
  if (await info.context.auth() == null)
    throw GraphQLAuth.unauthenticatedError();
}

GraphQLError _denied(Object? user) =>
    user == null ? GraphQLAuth.unauthenticatedError() : GraphQLAuth.forbidden();
