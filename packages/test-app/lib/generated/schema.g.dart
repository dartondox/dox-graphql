// GENERATED CODE - DO NOT MODIFY BY HAND
// Made by dox_graphql_builder. Run `dart run build_runner build`.
// ignore_for_file: type=lint

import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_graphql_test_app/app/graphql/types.dart' as i1;
import 'package:dox_graphql_test_app/app/repositories/repositories.dart' as i2;
import 'package:dox_graphql_test_app/app/graphql/book.resolver.dart' as i3;
import 'package:dox_graphql_test_app/app/dtos/create_book.dart' as i4;
import 'package:dox_graphql_test_app/app/graphql/math.resolver.dart' as i5;

/// The GraphQL schema of the app, made from the
/// `@GraphQLType`, `@GraphQLQuery` and `@GraphQLMutation` annotations.
/// Use it in `GraphQLConfig(schema: graphqlSchema)`.
final GraphQLSchema<DoxGraphQLContext> graphqlSchema =
    GraphQLSchema<DoxGraphQLContext>(
      query: ObjectType<Object?, DoxGraphQLContext>(
        'Query',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          Field<Object?, DoxGraphQLContext>(
            'books',
            _tBook.nonNull.list.nonNull,
            description: 'The latest books.',
            args: <Argument>[
              Argument('limit', graphqlInt.nonNull, defaultValue: '20'),
            ],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i3.BookResolver(
                  info.context.make<i2.BookRepository>(),
                  info.context.make<i2.AuthorRepository>(),
                ).books(limit: info.args.get<int>('limit')!),
          ),
          Field<Object?, DoxGraphQLContext>(
            'book',
            _tBook,
            args: <Argument>[Argument('id', graphqlInt.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i3.BookResolver(
                  info.context.make<i2.BookRepository>(),
                  info.context.make<i2.AuthorRepository>(),
                ).book(info.args.get<int>('id')!),
          ),
          Field<Object?, DoxGraphQLContext>(
            'me',
            graphqlString,
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i3.BookResolver(
                  info.context.make<i2.BookRepository>(),
                  info.context.make<i2.AuthorRepository>(),
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
                i5.MathResolver().rowSums(
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
            description: 'The path of the request.',
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) =>
                i5.MathResolver().path(info.context),
          ),
        ],
      ),
      mutation: ObjectType<Object?, DoxGraphQLContext>(
        'Mutation',
        fields: () => <Field<Object?, DoxGraphQLContext>>[
          Field<Object?, DoxGraphQLContext>(
            'createBook',
            _tBook.nonNull,
            args: <Argument>[Argument('input', _iCreateBookInput.nonNull)],
            resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) async =>
                i3.BookResolver(
                  info.context.make<i2.BookRepository>(),
                  info.context.make<i2.AuthorRepository>(),
                ).createBook(
                  await _vCreateBookInput(
                    info.args.input('input')!,
                    info.context,
                  ),
                ),
          ),
        ],
      ),
      types: <NamedType>[_tAuthor, _tBook],
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
              i3.BookResolver(
                info.context.make<i2.BookRepository>(),
                info.context.make<i2.AuthorRepository>(),
              ).author(s, info.context),
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

Future<i4.CreateBook> _vCreateBookInput(
  InputValues v,
  DoxGraphQLContext context,
) {
  return GraphQLDto.validate<i4.CreateBook>(
    i4.$CreateBookDto,
    _mCreateBookInput(v),
    context,
    names: const <String, String>{'author_id': 'authorId'},
  );
}
