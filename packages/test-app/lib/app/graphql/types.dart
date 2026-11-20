import 'package:dox_graphql/dox_graphql.dart';

enum Genre { novel, poetry }

/// A writer of books. A plain class: it has no table.
@GraphQLType()
class Author {
  Author({required this.id, required this.name});

  final int id;
  final String name;
}

/// A book.
@GraphQLType(name: 'Book')
class BookItem {
  BookItem({
    required this.id,
    required this.title,
    required this.authorId,
    required this.genre,
    this.publishedAt,
  });

  final int id;
  final String title;
  final Genre genre;
  final DateTime? publishedAt;

  @GraphQLIgnore()
  final int authorId;

  /// The title in upper case.
  @GraphQLField()
  String get shout => title.toUpperCase();
}
