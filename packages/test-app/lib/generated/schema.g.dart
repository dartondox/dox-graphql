// GENERATED CODE - DO NOT MODIFY BY HAND
// Made by dox_graphql_builder. Run `dart run build_runner build`.
// ignore_for_file: type=lint, unused_element

import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_orm/dox_graphql_orm.dart';
import 'package:dox_auth/dox_auth.dart' show Gate, Policy;
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
/// `@GraphQLType`, `@GraphQLAll`, `@GraphQLQuery`, ... annotations.
/// Use it in `GraphQLConfig(schema: graphqlSchema)`.
final GraphQLSchema<DoxGraphQLContext> graphqlSchema =
    GraphQLSchema<DoxGraphQLContext>(
      query: ObjectType<Object?, DoxGraphQLContext>(
        'Query',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          Field<Object?, DoxGraphQLContext>(
            'accounts',
            _tAccount.nonNull.list,
            args: <Argument>[
              Argument('limit', graphqlInt, defaultValue: '20'),
              Argument('offset', graphqlInt, defaultValue: '0'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.list<i2.Account>(i2.Account(), info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'account',
            _tAccount,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.find<i2.Account>(
                  i2.Account(),
                  int.tryParse(info.args.get<String>('id')!),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'articles',
            _tArticle.nonNull.list,
            args: <Argument>[
              Argument('limit', graphqlInt, defaultValue: '20'),
              Argument('offset', graphqlInt, defaultValue: '0'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.list<i3.Article>(i3.Article(), info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'article',
            _tArticle,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.find<i3.Article>(
                  i3.Article(),
                  int.tryParse(info.args.get<String>('id')!),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'docs',
            _tDoc.nonNull.list,
            args: <Argument>[
              Argument('limit', graphqlInt, defaultValue: '20'),
              Argument('offset', graphqlInt, defaultValue: '0'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _allow(info, 'viewAny', i5.Doc).then(
                  (_) => _filterList<i5.Doc>(
                    info,
                    'view',
                    GraphQLOrm.list<i5.Doc>(i5.Doc(), info),
                  ),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'docsPaginate',
            _pDoc,
            args: <Argument>[
              Argument('first', graphqlInt, defaultValue: '20'),
              Argument('page', graphqlInt, defaultValue: '1'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _allow(info, 'viewAny', i5.Doc).then(
                  (_) => _filterPage<i5.Doc>(
                    info,
                    'view',
                    GraphQLOrm.paginate<i5.Doc>(i5.Doc(), info),
                  ),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'doc',
            _tDoc,
            guard: true,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _findDoc(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'members',
            _tMember.nonNull.list,
            args: <Argument>[
              Argument('limit', graphqlInt, defaultValue: '20'),
              Argument('offset', graphqlInt, defaultValue: '0'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.list<i7.Member>(i7.Member(), info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'member',
            _tMember,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.find<i7.Member>(
                  i7.Member(),
                  int.tryParse(info.args.get<String>('id')!),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'notes',
            _pNote,
            args: <Argument>[
              Argument('first', graphqlInt, defaultValue: '20'),
              Argument('page', graphqlInt, defaultValue: '1'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _filterPage<i8.Note>(
                  info,
                  'view',
                  GraphQLOrm.paginate<i8.Note>(i8.Note(), info),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'note',
            _tNote,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _findNote(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'posts',
            _tPost.nonNull.list,
            args: <Argument>[
              Argument('limit', graphqlInt, defaultValue: '20'),
              Argument('offset', graphqlInt, defaultValue: '0'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.list<i9.Post>(i9.Post(), info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'postsPaginate',
            _pPost,
            args: <Argument>[
              Argument('first', graphqlInt, defaultValue: '20'),
              Argument('page', graphqlInt, defaultValue: '1'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.paginate<i9.Post>(i9.Post(), info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'post',
            _tPost,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.find<i9.Post>(
                  i9.Post(),
                  int.tryParse(info.args.get<String>('id')!),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'users',
            _tUser.nonNull.list,
            args: <Argument>[
              Argument('limit', graphqlInt, defaultValue: '20'),
              Argument('offset', graphqlInt, defaultValue: '0'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.list<i12.User>(i12.User(), info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'usersPaginate',
            _pUser,
            args: <Argument>[
              Argument('first', graphqlInt, defaultValue: '20'),
              Argument('page', graphqlInt, defaultValue: '1'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.paginate<i12.User>(i12.User(), info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'user',
            _tUser,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.find<i12.User>(
                  i12.User(),
                  int.tryParse(info.args.get<String>('id')!),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'books',
            _tBook.nonNull.list,
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
            guard: true,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i19.BookResolver(
                  info.context.make<i18.BookRepository>(),
                  info.context.make<i18.AuthorRepository>(),
                ).me(info.context),
          ),
          Field<Object?, DoxGraphQLContext>(
            'rowSums',
            graphqlInt.nonNull.list,
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
            graphqlString,
            description: 'The path of the request. Public: no `guard:`.',
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i21.MathResolver().path(info.context),
          ),
          Field<Object?, DoxGraphQLContext>(
            'postsWithUsers',
            _tPost.nonNull.list,
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
          Field<Object?, DoxGraphQLContext>(
            'createArticle',
            _tArticle,
            args: <Argument>[Argument('input', _iCreateArticleInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _createArticle(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'updateArticle',
            _tArticle,
            args: <Argument>[
              Argument('id', graphqlId.nonNull),
              Argument('input', _iUpdateArticleInput.nonNull),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _updateArticle(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'deleteArticle',
            graphqlBoolean,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _deleteArticle(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'createDoc',
            _tDoc,
            args: <Argument>[Argument('input', _iCreateDocInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _createDoc(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'updateDoc',
            _tDoc,
            guard: true,
            args: <Argument>[
              Argument('id', graphqlId.nonNull),
              Argument('input', _iUpdateDocInput.nonNull),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _updateDoc(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'deleteDoc',
            graphqlBoolean,
            guard: true,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _deleteDoc(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'createMember',
            _tMember,
            args: <Argument>[Argument('input', _iCreateMemberInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _createMember(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'updateMember',
            _tMember,
            args: <Argument>[
              Argument('id', graphqlId.nonNull),
              Argument('input', _iUpdateMemberInput.nonNull),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _updateMember(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'deleteMember',
            graphqlBoolean,
            guard: true,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _deleteMember(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'createNote',
            _tNote,
            guard: true,
            args: <Argument>[Argument('input', _iCreateNoteInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _createNote(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'updateNote',
            _tNote,
            guard: true,
            args: <Argument>[
              Argument('id', graphqlId.nonNull),
              Argument('input', _iUpdateNoteInput.nonNull),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _updateNote(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'deleteNote',
            graphqlBoolean,
            guard: true,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _deleteNote(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'createPost',
            _tPost,
            args: <Argument>[Argument('input', _iCreatePostInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _createPost(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'updatePost',
            _tPost,
            args: <Argument>[
              Argument('id', graphqlId.nonNull),
              Argument('input', _iUpdatePostInput.nonNull),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _updatePost(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'deletePost',
            graphqlBoolean,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _deletePost(info),
          ),
          Field<Object?, DoxGraphQLContext>(
            'createBook',
            _tBook,
            args: <Argument>[Argument('input', _iCreateBookInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) async =>
                i19.BookResolver(
                  info.context.make<i18.BookRepository>(),
                  info.context.make<i18.AuthorRepository>(),
                ).createBook(
                  await _vCreateBookInput(
                    info.args.input('input')!,
                    info.context,
                  ),
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
        _pDoc,
        _pNote,
        _pPost,
        _pUser,
        GraphQLOrm.paginatorInfo,
      ],
      startChecks: <void Function()>[_checkAbilities],
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
      description: '`visibleFields` keeps only these fields. `docs` is a relation to a\nmodel with `filter:`.',
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
                  _filterList<i5.Doc>(
                    info,
                    'view',
                    GraphQLOrm.many<i2.Account, i5.Doc>(
                      s,
                      'docs',
                      info.context,
                      (i2.Account p) => p.docs,
                    ),
                  ),
            ),
        ];
      },
    );

final ObjectType<i3.Article, DoxGraphQLContext> _tArticle =
    ObjectType<i3.Article, DoxGraphQLContext>(
      'Article',
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
      description:
          'No operation annotation: only reachable through `post.comments`.',
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
                  GraphQLOrm.relation<i4.Comment, i9.Post?>(
                    s,
                    'post',
                    info.context,
                    (i4.Comment p) => p.post,
                  ),
            ),
        ];
      },
    );

final ObjectType<i5.Doc, DoxGraphQLContext>
_tDoc = ObjectType<i5.Doc, DoxGraphQLContext>(
  'Doc',
  description: 'Its policy (DocPolicy) has every ability. The lists and the relations\nto Doc drop the rows that `view` denies. Find, update and delete need\na login, so a guest is stopped before the row lookup.',
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
          description: 'A single relation to a model with `filter:`. It is not\nnullable in Dart: only the field can be null, not the parent.',
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) =>
              _filterOne<i5.Doc>(
                info,
                'view',
                GraphQLOrm.relation<i5.Doc, i5.Doc>(
                  s,
                  'parent',
                  info.context,
                  (i5.Doc p) => p.parent,
                ),
              ),
        ),
      if (show('child'))
        Field<i5.Doc, DoxGraphQLContext>(
          'child',
          _tDoc,
          description: 'The doc whose parent this one is: a HasOne relation.',
          resolve: (i5.Doc s, ResolveInfo<DoxGraphQLContext> info) =>
              _filterOne<i5.Doc>(
                info,
                'view',
                GraphQLOrm.relation<i5.Doc, i5.Doc?>(
                  s,
                  'child',
                  info.context,
                  (i5.Doc p) => p.child,
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
      guard: true,
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
      description: 'Public to read, but `owner:` makes create need a login. The create\nsets `userId` to the logged-in user. Only @GraphQLPaginate, so the\npaged list is `notes`. A note with the title `hidden` is left out of\nevery read (`filter:`), also of the find with no `can:`.',
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
  guard: true,
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
              GraphQLOrm.many<i12.User, i9.Post>(
                s,
                'posts',
                info.context,
                (i12.User p) => p.posts,
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
              GraphQLOrm.many<i12.User, i3.Article>(
                s,
                'articles',
                info.context,
                (i12.User p) => p.articles,
              ),
        ),
    ];
  },
);

final ObjectType<Pagination<i5.Doc>, DoxGraphQLContext>
_pDoc = ObjectType<Pagination<i5.Doc>, DoxGraphQLContext>(
  'DocPaginator',
  description: 'A page of Doc rows.',
  fields: () => <Field<Pagination<i5.Doc>, DoxGraphQLContext>>[
    Field<Pagination<i5.Doc>, DoxGraphQLContext>(
      'data',
      _tDoc.nonNull.list.nonNull,
      resolve: (Pagination<i5.Doc> s, ResolveInfo<DoxGraphQLContext> info) =>
          s.data,
    ),
    Field<Pagination<i5.Doc>, DoxGraphQLContext>(
      'paginatorInfo',
      GraphQLOrm.paginatorInfo.nonNull,
      resolve: (Pagination<i5.Doc> s, ResolveInfo<DoxGraphQLContext> info) => s,
    ),
  ],
);

final ObjectType<Pagination<i8.Note>, DoxGraphQLContext>
_pNote = ObjectType<Pagination<i8.Note>, DoxGraphQLContext>(
  'NotePaginator',
  description: 'A page of Note rows.',
  fields: () => <Field<Pagination<i8.Note>, DoxGraphQLContext>>[
    Field<Pagination<i8.Note>, DoxGraphQLContext>(
      'data',
      _tNote.nonNull.list.nonNull,
      resolve: (Pagination<i8.Note> s, ResolveInfo<DoxGraphQLContext> info) =>
          s.data,
    ),
    Field<Pagination<i8.Note>, DoxGraphQLContext>(
      'paginatorInfo',
      GraphQLOrm.paginatorInfo.nonNull,
      resolve: (Pagination<i8.Note> s, ResolveInfo<DoxGraphQLContext> info) =>
          s,
    ),
  ],
);

final ObjectType<Pagination<i9.Post>, DoxGraphQLContext>
_pPost = ObjectType<Pagination<i9.Post>, DoxGraphQLContext>(
  'PostPaginator',
  description: 'A page of Post rows.',
  fields: () => <Field<Pagination<i9.Post>, DoxGraphQLContext>>[
    Field<Pagination<i9.Post>, DoxGraphQLContext>(
      'data',
      _tPost.nonNull.list.nonNull,
      resolve: (Pagination<i9.Post> s, ResolveInfo<DoxGraphQLContext> info) =>
          s.data,
    ),
    Field<Pagination<i9.Post>, DoxGraphQLContext>(
      'paginatorInfo',
      GraphQLOrm.paginatorInfo.nonNull,
      resolve: (Pagination<i9.Post> s, ResolveInfo<DoxGraphQLContext> info) =>
          s,
    ),
  ],
);

final ObjectType<Pagination<i12.User>, DoxGraphQLContext>
_pUser = ObjectType<Pagination<i12.User>, DoxGraphQLContext>(
  'UserPaginator',
  description: 'A page of User rows.',
  guard: true,
  fields: () => <Field<Pagination<i12.User>, DoxGraphQLContext>>[
    Field<Pagination<i12.User>, DoxGraphQLContext>(
      'data',
      _tUser.nonNull.list.nonNull,
      resolve: (Pagination<i12.User> s, ResolveInfo<DoxGraphQLContext> info) =>
          s.data,
    ),
    Field<Pagination<i12.User>, DoxGraphQLContext>(
      'paginatorInfo',
      GraphQLOrm.paginatorInfo.nonNull,
      resolve: (Pagination<i12.User> s, ResolveInfo<DoxGraphQLContext> info) =>
          s,
    ),
  ],
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

/// Makes a Article from the input of `@GraphQLCreate`.
Future<i3.Article> _createArticle(ResolveInfo<DoxGraphQLContext> info) async {
  i13.ArticleDto dto = await _vCreateArticleInput(
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

/// Deletes a Article. False when there is no Article with that id.
Future<bool> _deleteArticle(ResolveInfo<DoxGraphQLContext> info) async {
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

/// The Doc with the id, after the `can:` check and the `filter:` of
/// the type. A missing id is checked as a blank Doc, so a denied user
/// gets the same error for an id that exists and one that does not. A
/// row that the filter denies gives null, like a missing id.
Future<i5.Doc?> _findDoc(ResolveInfo<DoxGraphQLContext> info) async {
  i5.Doc? model = await GraphQLOrm.find<i5.Doc>(
    i5.Doc(),
    int.tryParse(info.args.get<String>('id')!),
  );
  await (model == null
      ? _allowMissing(info, 'view', i5.Doc())
      : _allow(info, 'view', model));
  return await _filterOne<i5.Doc>(info, 'view', Future<i5.Doc?>.value(model));
}

/// Makes a Doc from the input of `@GraphQLCreate`.
Future<i5.Doc> _createDoc(ResolveInfo<DoxGraphQLContext> info) async {
  await _allow(info, 'create', i5.Doc);
  i14.DocDto dto = await _vCreateDocInput(
    info.args.input('input')!,
    info.context,
  );
  i5.Doc model = i5.Doc()..title = dto.title;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Doc. Null when there is no
/// Doc with that id.
Future<i5.Doc?> _updateDoc(ResolveInfo<DoxGraphQLContext> info) async {
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

/// Deletes a Doc. False when there is no Doc with that id.
Future<bool> _deleteDoc(ResolveInfo<DoxGraphQLContext> info) async {
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

/// Makes a Member from the input of `@GraphQLCreate`.
Future<i7.Member> _createMember(ResolveInfo<DoxGraphQLContext> info) async {
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
/// Member with that id.
Future<i7.Member?> _updateMember(ResolveInfo<DoxGraphQLContext> info) async {
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

/// Deletes a Member. False when there is no Member with that id.
Future<bool> _deleteMember(ResolveInfo<DoxGraphQLContext> info) async {
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

/// The Note with the id, after the `can:` check and the `filter:` of
/// the type. A missing id is checked as a blank Note, so a denied user
/// gets the same error for an id that exists and one that does not. A
/// row that the filter denies gives null, like a missing id.
Future<i8.Note?> _findNote(ResolveInfo<DoxGraphQLContext> info) async {
  i8.Note? model = await GraphQLOrm.find<i8.Note>(
    i8.Note(),
    int.tryParse(info.args.get<String>('id')!),
  );
  return await _filterOne<i8.Note>(info, 'view', Future<i8.Note?>.value(model));
}

/// Makes a Note from the input of `@GraphQLCreate`.
Future<i8.Note> _createNote(ResolveInfo<DoxGraphQLContext> info) async {
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
/// Note with that id.
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

/// Deletes a Note. False when there is no Note with that id.
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

/// Makes a Post from the input of `@GraphQLCreate`.
Future<i9.Post> _createPost(ResolveInfo<DoxGraphQLContext> info) async {
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
/// Post with that id.
Future<i9.Post?> _updatePost(ResolveInfo<DoxGraphQLContext> info) async {
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

/// Deletes a Post. False when there is no Post with that id.
Future<bool> _deletePost(ResolveInfo<DoxGraphQLContext> info) async {
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

/// Asks `Gate` (a policy registered with `Gate.policy`, or a
/// `Gate.define`) if the user may do [ability] on [subject]: a row, or
/// the model type. Throws when not: "Unauthenticated" for a guest, else
/// "Forbidden".
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
/// empty row (a null check, a missing value, a `late` field that is not
/// set) denies. Other errors, like a
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
  } on Error catch (e) {
    // a `late` field of the blank row that is not set. The type of the
    // error is not public, and --obfuscate renames it: read the message.
    if (!e.toString().contains('has not been initialized')) rethrow;
    allowed = false;
  }
  if (!allowed) throw _denied(user);
}

/// The rows of [rows] that [ability] allows (`filter:`). The others are
/// left out, with no error.
Future<List<T>?> _filterList<T extends Object>(
  ResolveInfo<DoxGraphQLContext> info,
  String ability,
  Future<List<T>?> rows,
) async {
  List<T>? list = await rows;
  if (list == null || list.isEmpty) return list;
  Object? user = await info.context.user<Object>();
  return <T>[
    for (T row in list)
      if (await Gate.allows(user, ability, row)) row,
  ];
}

/// [row] when [ability] allows it (`filter:`), else null.
Future<T?> _filterOne<T extends Object>(
  ResolveInfo<DoxGraphQLContext> info,
  String ability,
  Future<T?> row,
) async {
  T? value = await row;
  if (value == null) return null;
  Object? user = await info.context.user<Object>();
  return await Gate.allows(user, ability, value) ? value : null;
}

/// [page] with only the rows that [ability] allows (`filter:`). The
/// count query ran before, so `total` and `lastPage` still count the
/// rows that are left out.
Future<Pagination<T>> _filterPage<T extends Object>(
  ResolveInfo<DoxGraphQLContext> info,
  String ability,
  Future<Pagination<T>> page,
) async {
  Pagination<T> result = await page;
  result.data = (await _filterList<T>(
    info,
    ability,
    Future<List<T>>.value(result.data),
  ))!;
  return result;
}

GraphQLError _denied(Object? user) =>
    user == null ? GraphQLAuth.unauthenticatedError() : GraphQLAuth.forbidden();

/// The abilities of `can:` and `filter:`, checked when the
/// app starts (`GraphQLSchema.startChecks`).
void _checkAbilities() {
  _checkAbility<i3.Article>(
    '@GraphQLUpdate(can: \'update\')',
    'Article',
    'update',
  );
  _checkAbility<i3.Article>(
    '@GraphQLDelete(can: \'delete\')',
    'Article',
    'delete',
  );
  _checkAbility<i5.Doc>('@GraphQLType(filter: \'view\')', 'Doc', 'view');
  _checkAbility<i5.Doc>('@GraphQLAll(can: \'viewAny\')', 'Doc', 'viewAny');
  _checkAbility<i5.Doc>('@GraphQLPaginate(can: \'viewAny\')', 'Doc', 'viewAny');
  _checkAbility<i5.Doc>('@GraphQLFind(can: \'view\')', 'Doc', 'view');
  _checkAbility<i5.Doc>('@GraphQLCreate(can: \'create\')', 'Doc', 'create');
  _checkAbility<i5.Doc>('@GraphQLUpdate(can: \'update\')', 'Doc', 'update');
  _checkAbility<i5.Doc>('@GraphQLDelete(can: \'delete\')', 'Doc', 'delete');
  _checkAbility<i7.Member>(
    '@GraphQLUpdate(can: \'update\')',
    'Member',
    'update',
  );
  _checkAbility<i7.Member>(
    '@GraphQLDelete(can: \'delete\')',
    'Member',
    'delete',
  );
  _checkAbility<i8.Note>('@GraphQLType(filter: \'view\')', 'Note', 'view');
  _checkAbility<i8.Note>('@GraphQLUpdate(can: \'update\')', 'Note', 'update');
  _checkAbility<i8.Note>('@GraphQLDelete(can: \'delete\')', 'Note', 'delete');
  _checkAbility<i9.Post>('@GraphQLUpdate(can: \'update\')', 'Post', 'update');
  _checkAbility<i9.Post>('@GraphQLDelete(can: \'delete\')', 'Post', 'delete');
}

/// Throws when [ability] (of [annotation] on [model]) is not an ability
/// of the policy of [M]: a typo. A model with no policy needs a
/// `Gate.define` of [ability].
void _checkAbility<M>(String annotation, String model, String ability) {
  Policy<dynamic, M>? policy = Gate.policyOf<M>();
  if (policy == null) {
    if (Gate.isDefined(ability)) return;
    throw StateError(
      '$annotation on $model: $model has no policy and there is no '
      "Gate.define('$ability'). Register the policy with "
      'Gate.policy<$model>(...) in the setup() of a provider: the check '
      'runs in GraphQLProvider.boot(), after every setup().',
    );
  }
  if (policy.has(ability)) return;
  throw StateError(
    "$annotation on $model: ${policy.runtimeType} has no ability "
    "'$ability'. Available: ${policy.abilities.keys.join(', ')}.",
  );
}
