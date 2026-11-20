// GENERATED CODE - DO NOT MODIFY BY HAND
// Made by dox_graphql_builder. Run `dart run build_runner build`.
// ignore_for_file: type=lint

import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_orm/dox_graphql_orm.dart';
import 'package:dox_graphql_test_app/app/graphql/types.dart' as i1;
import 'package:dox_graphql_test_app/app/models/comment/comment.model.dart'
    as i2;
import 'package:dox_graphql_test_app/app/models/post/post.model.dart' as i3;
import 'package:dox_graphql_test_app/app/models/user/user.model.dart' as i4;
import 'package:dox_graphql_test_app/app/dtos/create_post.dart' as i5;
import 'package:dox_graphql_test_app/app/repositories/repositories.dart' as i6;
import 'package:dox_graphql_test_app/app/graphql/book.resolver.dart' as i7;
import 'package:dox_graphql_test_app/app/dtos/create_book.dart' as i8;
import 'package:dox_graphql_test_app/app/services/post_service.dart' as i9;
import 'package:dox_graphql_test_app/app/graphql/post.resolver.dart' as i10;

/// The GraphQL schema of the app, made from the
/// `@GraphQLType`, `@Query` and `@Mutation` annotations.
/// Use it in `GraphQLConfig(schema: graphqlSchema)`.
final GraphQLSchema<DoxGraphQLContext> graphqlSchema =
    GraphQLSchema<DoxGraphQLContext>(
      query: ObjectType<Object?, DoxGraphQLContext>(
        'Query',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          AutoField<Object?, DoxGraphQLContext>(
            'posts',
            _tPost.nonNull.list.nonNull,
            args: <Argument>[
              Argument('limit', graphqlInt, defaultValue: '20'),
              Argument('offset', graphqlInt, defaultValue: '0'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.list<i3.Post>(i3.Post(), info),
          ),
          AutoField<Object?, DoxGraphQLContext>(
            'post',
            _tPost,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.find<i3.Post>(
                  i3.Post(),
                  int.tryParse(info.args.get<String>('id')!),
                ),
          ),
          AutoField<Object?, DoxGraphQLContext>(
            'users',
            _tUser.nonNull.list.nonNull,
            args: <Argument>[
              Argument('limit', graphqlInt, defaultValue: '20'),
              Argument('offset', graphqlInt, defaultValue: '0'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.list<i4.User>(i4.User(), info),
          ),
          AutoField<Object?, DoxGraphQLContext>(
            'user',
            _tUser,
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.find<i4.User>(
                  i4.User(),
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
                i7.BookResolver(
                  info.context.make<i6.BookRepository>(),
                  info.context.make<i6.AuthorRepository>(),
                ).books(limit: info.args.get<int>('limit')!),
          ),
          Field<Object?, DoxGraphQLContext>(
            'book',
            _tBook,
            args: <Argument>[Argument('id', graphqlInt.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i7.BookResolver(
                  info.context.make<i6.BookRepository>(),
                  info.context.make<i6.AuthorRepository>(),
                ).book(info.args.get<int>('id')!),
          ),
          Field<Object?, DoxGraphQLContext>(
            'me',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i7.BookResolver(
                  info.context.make<i6.BookRepository>(),
                  info.context.make<i6.AuthorRepository>(),
                ).me(info.context),
          ),
          Field<Object?, DoxGraphQLContext>(
            'postsWithUsers',
            _tPost.nonNull.list.nonNull,
            description: 'The posts, with their users preloaded.',
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i10.PostResolver(info.context.make<i9.PostService>())
                    .postsWithUsers(),
          ),
        ],
      ),
      mutation: ObjectType<Object?, DoxGraphQLContext>(
        'Mutation',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          AutoField<Object?, DoxGraphQLContext>(
            'createPost',
            _tPost.nonNull,
            args: <Argument>[Argument('input', _iCreatePostInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                _createPost(info),
          ),
          AutoField<Object?, DoxGraphQLContext>(
            'updatePost',
            _tPost,
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
            args: <Argument>[Argument('id', graphqlId.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.delete<i3.Post>(
                  i3.Post(),
                  int.tryParse(info.args.get<String>('id')!),
                ),
          ),
          Field<Object?, DoxGraphQLContext>(
            'createBook',
            _tBook.nonNull,
            args: <Argument>[Argument('input', _iCreateBookInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) async =>
                i7.BookResolver(
                  info.context.make<i6.BookRepository>(),
                  info.context.make<i6.AuthorRepository>(),
                ).createBook(
                  await _vCreateBookInput(
                    info.args.input('input')!,
                    info.context,
                  ),
                ),
          ),
        ],
      ),
      types: <NamedType>[_tAuthor, _tBook, _tComment, _tPost, _tUser],
    );

final ObjectType<i1.Author, DoxGraphQLContext> _tAuthor =
    ObjectType<i1.Author, DoxGraphQLContext>(
      'Author',
      description: 'A writer of books. A plain class: it has no table.',
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
              i7.BookResolver(
                info.context.make<i6.BookRepository>(),
                info.context.make<i6.AuthorRepository>(),
              ).author(s, info.context),
        ),
      ],
    );

final ObjectType<i2.Comment, DoxGraphQLContext> _tComment =
    ObjectType<i2.Comment, DoxGraphQLContext>(
      'Comment',
      description: 'Only reachable through `post.comments`.',
      fields: () {
        List<String> hidden = i2.Comment().hidden;
        return <Field<i2.Comment, DoxGraphQLContext>>[
          if (!hidden.contains('id'))
            Field<i2.Comment, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i2.Comment s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.id,
            ),
          if (!hidden.contains('body'))
            Field<i2.Comment, DoxGraphQLContext>(
              'body',
              graphqlString,
              resolve: (i2.Comment s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.body,
            ),
          if (!hidden.contains('post_id'))
            Field<i2.Comment, DoxGraphQLContext>(
              'postId',
              graphqlInt,
              resolve: (i2.Comment s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.postId,
            ),
          Field<i2.Comment, DoxGraphQLContext>(
            'post',
            _tPost,
            resolve: (i2.Comment s, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.relation<i2.Comment, i3.Post?>(
                  s,
                  'post',
                  info.context,
                  (i2.Comment p) => p.post,
                ),
          ),
        ];
      },
    );

final ObjectType<i3.Post, DoxGraphQLContext> _tPost =
    ObjectType<i3.Post, DoxGraphQLContext>(
      'Post',
      fields: () {
        List<String> hidden = i3.Post().hidden;
        return <Field<i3.Post, DoxGraphQLContext>>[
          if (!hidden.contains('id'))
            Field<i3.Post, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i3.Post s, ResolveInfo<DoxGraphQLContext> info) => s.id,
            ),
          if (!hidden.contains('title'))
            Field<i3.Post, DoxGraphQLContext>(
              'title',
              graphqlString,
              resolve: (i3.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.title,
            ),
          if (!hidden.contains('body'))
            Field<i3.Post, DoxGraphQLContext>(
              'body',
              graphqlString,
              resolve: (i3.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.body,
            ),
          if (!hidden.contains('user_id'))
            Field<i3.Post, DoxGraphQLContext>(
              'userId',
              graphqlInt,
              resolve: (i3.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.userId,
            ),
          if (!hidden.contains('status'))
            Field<i3.Post, DoxGraphQLContext>(
              'status',
              _ePostStatus,
              resolve: (i3.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.status,
            ),
          Field<i3.Post, DoxGraphQLContext>(
            'user',
            _tUser,
            resolve: (i3.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.relation<i3.Post, i4.User?>(
                  s,
                  'user',
                  info.context,
                  (i3.Post p) => p.user,
                ),
          ),
          Field<i3.Post, DoxGraphQLContext>(
            'comments',
            _tComment.nonNull.list.nonNull,
            resolve: (i3.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.relation<i3.Post, List<i2.Comment>>(
                  s,
                  'comments',
                  info.context,
                  (i3.Post p) => p.comments,
                ),
          ),
          Field<i3.Post, DoxGraphQLContext>(
            'excerpt',
            graphqlString.nonNull,
            description: 'The first 5 letters of the body.',
            resolve: (i3.Post s, ResolveInfo<DoxGraphQLContext> info) =>
                s.excerpt,
          ),
        ];
      },
    );

final ObjectType<i4.User, DoxGraphQLContext> _tUser =
    ObjectType<i4.User, DoxGraphQLContext>(
      'User',
      fields: () {
        List<String> hidden = i4.User().hidden;
        return <Field<i4.User, DoxGraphQLContext>>[
          if (!hidden.contains('id'))
            Field<i4.User, DoxGraphQLContext>(
              'id',
              graphqlId.nonNull,
              resolve: (i4.User s, ResolveInfo<DoxGraphQLContext> info) => s.id,
            ),
          if (!hidden.contains('name'))
            Field<i4.User, DoxGraphQLContext>(
              'name',
              graphqlString,
              resolve: (i4.User s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.name,
            ),
          if (!hidden.contains('password'))
            Field<i4.User, DoxGraphQLContext>(
              'password',
              graphqlString,
              resolve: (i4.User s, ResolveInfo<DoxGraphQLContext> info) =>
                  s.password,
            ),
          Field<i4.User, DoxGraphQLContext>(
            'posts',
            _tPost.nonNull.list.nonNull,
            resolve: (i4.User s, ResolveInfo<DoxGraphQLContext> info) =>
                GraphQLOrm.relation<i4.User, List<i3.Post>>(
                  s,
                  'posts',
                  info.context,
                  (i4.User p) => p.posts,
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

final EnumType<i3.PostStatus> _ePostStatus = EnumType<i3.PostStatus>(
  'PostStatus',
  <EnumValue<i3.PostStatus>>[
    EnumValue<i3.PostStatus>('draft', i3.PostStatus.draft),
    EnumValue<i3.PostStatus>('published', i3.PostStatus.published),
  ],
);

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
        i3.PostStatus e1 => e1.name,
        _ => null,
      },
  };
}

Future<i5.CreatePostDto> _vCreatePostInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i5.CreatePostDto>(
    i5.$CreatePostDtoDto,
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
        i3.PostStatus e1 => e1.name,
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

Future<i8.CreateBook> _vCreateBookInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i8.CreateBook>(
    i8.$CreateBookDto,
    _mCreateBookInput(v),
    context,
    names: const <String, String>{'author_id': 'authorId'},
  );
}

/// Makes a Post from the input of `createPost`.
Future<i3.Post> _createPost(ResolveInfo<DoxGraphQLContext> info) async {
  i5.CreatePostDto dto = await _vCreatePostInput(
    info.args.input('input')!,
    info.context,
  );
  i3.Post model = i3.Post()
    ..title = dto.title
    ..body = dto.body
    ..status = dto.status;
  await model.save();
  return model;
}

/// Sets the fields the client sent on a Post. Null when there is no
/// Post with that id.
Future<i3.Post?> _updatePost(ResolveInfo<DoxGraphQLContext> info) async {
  i3.Post? model = await GraphQLOrm.find<i3.Post>(
    i3.Post(),
    int.tryParse(info.args.get<String>('id')!),
  );
  if (model == null) return null;
  InputValues input = info.args.input('input')!;
  Map<String, Object?> given = _mUpdatePostInput(input);
  // the other fields keep their values, so the DTO gets a whole input
  i5.CreatePostDto dto = await GraphQLDto.validate<i5.CreatePostDto>(
    i5.$CreatePostDtoDto,
    <String, Object?>{
      'title': model.title,
      'body': model.body,
      'status': model.status?.name,
      ...given,
    },
    info.context,
    names: const <String, String>{},
    params: <String, String>{'id': '${model.id}'},
    only: given.keys.toSet(),
  );
  if (input.has('title')) model.title = dto.title;
  if (input.has('body')) model.body = dto.body;
  if (input.has('status')) model.status = dto.status;
  await model.save();
  return model;
}
