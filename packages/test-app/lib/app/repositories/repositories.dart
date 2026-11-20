import 'package:dox_core/dox_core.dart';

import '../dtos/create_book.dart';
import '../graphql/types.dart';

/// The books, in memory.
@Inject()
class BookRepository {
  final List<BookItem> books = <BookItem>[
    BookItem(id: 1, title: 'Dune', authorId: 1, genre: Genre.novel),
    BookItem(id: 2, title: 'Odes', authorId: 2, genre: Genre.poetry),
    BookItem(id: 3, title: 'Emma', authorId: 1, genre: Genre.novel),
  ];

  List<BookItem> latest(int limit) => books.take(limit).toList();

  BookItem add(CreateBook input) {
    BookItem book = BookItem(
      id: books.length + 1,
      title: input.title,
      authorId: input.authorId,
      genre: input.genre ?? Genre.novel,
    );
    books.add(book);
    return book;
  }
}

/// The authors, in memory. It keeps the ids of each batch, so a test can
/// see that the loads were batched.
@Inject()
class AuthorRepository {
  final List<List<int>> batches = <List<int>>[];

  Future<List<Author?>> findByIds(List<int> ids) async {
    batches.add(ids);
    return <Author?>[for (int id in ids) Author(id: id, name: 'author$id')];
  }
}
