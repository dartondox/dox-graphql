# dox_graphql

A GraphQL server engine for Dart. It follows the GraphQL spec (October
2021 edition).

- Types: scalars (built-in and custom), objects, interfaces, unions,
  enums, input objects, lists and non-null.
- A schema that is checked when you build it.
- Query validation with the rules of the spec, plus your own rules.
- Execution: variables, fragments, `@skip` / `@include`, async resolvers,
  null bubbling, and errors with `locations` and `path`.
- Introspection, so tools like GraphiQL work. You can turn it off.
- A `DataLoader` to batch and cache database loads.

The engine is pure Dart. It uses [gql](https://pub.dev/packages/gql) only
to parse queries.

## Example

```dart
import 'package:dox_graphql/dox_graphql.dart';

class AppContext {
  AppContext(this.userName);
  final String userName;
}

class Book {
  Book(this.title, this.year);
  final String title;
  final int year;
}

final ObjectType<Book, AppContext> bookType = ObjectType<Book, AppContext>(
  'Book',
  fields: () => <Field<Book, AppContext>>[
    Field<Book, AppContext>(
      'title',
      graphqlString.nonNull,
      resolve: (Book b, ResolveInfo<AppContext> info) => b.title,
    ),
    Field<Book, AppContext>(
      'year',
      graphqlInt,
      resolve: (Book b, ResolveInfo<AppContext> info) => b.year,
    ),
  ],
);

final Schema<AppContext> schema = Schema<AppContext>(
  query: ObjectType<Object?, AppContext>(
    'Query',
    fields: () => <Field<Object?, AppContext>>[
      Field<Object?, AppContext>(
        'books',
        bookType.nonNull.list.nonNull,
        args: <Argument>[Argument('limit', graphqlInt, defaultValue: '10')],
        resolve: (Object? _, ResolveInfo<AppContext> info) async {
          int limit = info.args.get<int>('limit')!;
          return <Book>[Book('Dune', 1965)].take(limit).toList();
        },
      ),
    ],
  ),
);

Future<void> main() async {
  GraphQLExecutor<AppContext> executor = GraphQLExecutor<AppContext>(schema);
  GraphQLResponse response = await executor.execute(
    const GraphQLRequest('{ books { title year } }'),
    context: AppContext('ann'),
  );
  print(response.toJson()); // {data: {books: [{title: Dune, year: 1965}]}}
}
```

## Notes

- `fields` is a function, so types can point at each other.
- `ObjectType<S, C>`: `S` is the Dart type of the parent value, `C` the
  type of the context. Without `isTypeOf`, a value belongs to the type
  when it is an `S`. This is how interfaces and unions find the type of
  a value.
- Default values are GraphQL literal text: `'10'`, `'"hi"'`, `'RED'`,
  `'{limit: 5}'`. They are checked when the schema is built.
- Resolvers read arguments with typed getters: `info.args.get<int>('id')`,
  `info.args.list<String>('tags')`, `info.args.input('filter')`.
- `execute` never throws. A query deeper than `maxDepth` (64) or longer
  than `maxQueryLength` is rejected before it is parsed.
- An error from a resolver that is not a `GraphQLError` is sent as
  "Internal server error". Turn on `showInternalErrors` in development
  to see the real message. Throw a `GraphQLError` to send your own.
- Make one `DataLoader` per request, in the context, so the cache lives
  only as long as the request.
