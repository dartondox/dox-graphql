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
- A Dox provider that serves GraphQL over HTTP, with GraphiQL in
  development.

The engine is pure Dart. It uses [gql](https://pub.dev/packages/gql) only
to parse queries.

## Install in a Dox app

```bash
dox add graphql
```

It adds the packages, writes `lib/config/graphql.dart` and
`lib/providers/graphql_provider.dart`, and runs the builder. Use
`dox graphql:install --no-orm` for an app without models. Then put
`@GraphQLType()` on a model, run `dart run build_runner build`, start the
app and open `/graphql`.

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

final GraphQLSchema<AppContext> schema = GraphQLSchema<AppContext>(
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
  a value. When two possible types match the same value this way (like
  two types made from `Map`), the field fails: give them `isTypeOf`, or
  give the interface or union a `resolveType`.
- Default values are GraphQL literal text: `'10'`, `'"hi"'`, `'RED'`,
  `'{limit: 5}'`. They are checked when the schema is built.
- Resolvers read arguments with typed getters: `info.args.get<int>('id')`,
  `info.args.list<String>('tags')`, `info.args.input('filter')`.
- `execute` never throws. A query deeper than `maxDepth` (64) or longer
  than `maxQueryLength` is rejected before it is parsed. A query that
  selects more than `maxFields` (20,000) fields, with fragments expanded,
  is rejected before it runs. A request stops with one error when it
  resolves more than `maxNodes` (100,000) fields and list items.
  At most `maxErrors` (100) errors are kept. Validation stops at the
  next error. A request keeps the data it has built; fields that start
  after the cap give null. Both add one last error.
- An error from a resolver that is not a `GraphQLError` is sent as
  "Internal server error". Turn on `showInternalErrors` in development
  to see the real message. Throw a `GraphQLError` to send your own.
- Make one `DataLoader` per request, in the context, so the cache lives
  only as long as the request.

## Use it in a Dox app

`GraphQLProvider` adds the endpoint. It builds the executor once when the
app starts and adds `GET` and `POST` routes at `/graphql`.

Put the config in `lib/config/graphql.dart`:

```dart
import 'package:dox_graphql/dox_graphql.dart';

GraphQLConfig graphqlConfig = GraphQLConfig(
  schema: schema, // a GraphQLSchema<DoxGraphQLContext>
  middleware: <Object>[AuthMiddleware(optional: true)],
);
```

Add a provider (Dox finds it, like every `DoxProvider`):

```dart
class AppGraphQLProvider extends GraphQLProvider {
  AppGraphQLProvider() : super(graphqlConfig);
}
```

Resolvers get a `DoxGraphQLContext`:

```dart
Field<Object?, DoxGraphQLContext>(
  'me',
  userType,
  resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) {
    User? me = info.context.user<User>(); // null for a guest
    return me;
  },
)
```

- `info.context.request`: the `DoxRequest`.
- `info.context.user<T>()` and `info.context.auth`: the logged-in user,
  set by an auth middleware on the route.
- `info.context.make<T>()`: a service from the Dox container.
- `info.context.loader<K, V>(name, create)`: a `DataLoader` for this
  request only. The first call makes it; later calls get the same one.

### Defaults

| Setting | Default |
| --- | --- |
| `path` | `/graphql` |
| `introspection` | on when `APP_ENV` is `development`, else off |
| `showInternalErrors` | on when `APP_ENV` is `development`, else off |
| `graphiql` | on when `APP_ENV` is `development`, else off |
| `maxDepth`, `maxQueryLength`, `maxFields`, `maxNodes`, `maxErrors` | the engine defaults |

### HTTP

- `POST` with a JSON body: `query`, `variables`, `operationName`,
  `extensions`.
- `GET` with the same names in the URL (`variables` and `extensions` as
  JSON text). Queries only: a mutation gets `405` with `Allow: POST`.
- The answer is `application/graphql-response+json` when the `Accept`
  header has it, else `application/json`. With the new type, a request
  that fails before it runs (syntax, validation, variables) gets `400`.
  With `application/json` it gets `200`.
- Bad JSON or a missing query gets `400` with a GraphQL error. A body
  that is not JSON gets `415`.
- An error a resolver throws is sent to the `ExceptionHandler` of the
  app (it logs with the Dox logger by default). The client sees
  "Internal server error", unless `showInternalErrors` is on.
- A browser that opens `/graphql` gets the GraphiQL page when `graphiql`
  is on. It loads GraphiQL 4.1.2 and React 18.3.1 from jsDelivr, with
  SRI hashes.
