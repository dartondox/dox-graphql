import 'package:dox_graphql/dox_graphql.dart';

import '../dtos/create_book.dart';
import '../repositories/repositories.dart';
import 'types.dart';

class BookResolver {
  BookResolver(this.repo, this.authors);

  final BookRepository repo;
  final AuthorRepository authors;

  @GraphQLQuery(description: 'The latest books.')
  List<BookItem> books({int limit = 20}) => repo.latest(limit);

  @GraphQLQuery()
  BookItem? book(int id) {
    for (BookItem b in repo.books) {
      if (b.id == id) return b;
    }
    return null;
  }

  @GraphQLQuery()
  Future<String?> me(DoxGraphQLContext context) => context.user<String>();

  @GraphQLMutation()
  Future<BookItem> createBook(CreateBook input) async => repo.add(input);

  @ResolveField()
  Future<Author?> author(BookItem book, DoxGraphQLContext context) {
    DataLoader<int, Author> loader = context.loader<int, Author>(
      'authors',
      () => DataLoader<int, Author>(authors.findByIds),
    );
    return loader.load(book.authorId);
  }
}
