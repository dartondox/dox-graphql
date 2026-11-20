import 'package:dox_graphql/dox_graphql.dart';

enum Genre { novel, poetry }

/// A person. Not a GraphQL type itself.
class Person {
  Person({required this.name});

  final String name;
}

/// A writer of books. A plain class: it has no table. `name` comes from
/// [Person].
@GraphQLType()
class Author extends Person {
  Author({required this.id, required super.name});

  final int id;
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
