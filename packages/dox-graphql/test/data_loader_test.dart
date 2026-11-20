import 'package:dox_graphql/dox_graphql.dart';
import 'package:test/test.dart';

class UserLoader implements BatchLoader<int, String> {
  final List<List<int>> calls = <List<int>>[];

  @override
  Future<List<String?>> load(List<int> keys) async {
    calls.add(keys);
    return <String?>[for (int k in keys) k < 0 ? null : 'user $k'];
  }
}

class Post {
  Post(this.id, this.authorId);
  final int id;
  final int authorId;
}

class LoaderContext {
  final UserLoader users = UserLoader();
  late final DataLoader<int, String> userLoader = DataLoader<int, String>.of(
    users,
  );
}

void main() {
  test('loads in the same turn become one batch', () async {
    UserLoader users = UserLoader();
    DataLoader<int, String> loader = DataLoader<int, String>.of(users);
    List<String?> values = await Future.wait(<Future<String?>>[
      loader.load(1),
      loader.load(2),
      loader.load(1),
      loader.load(-1),
    ]);
    expect(values, <String?>['user 1', 'user 2', 'user 1', null]);
    expect(users.calls, <List<int>>[
      <int>[1, 2, -1],
    ]);
    // Cached: no new call.
    expect(await loader.load(2), 'user 2');
    expect(users.calls, hasLength(1));
    // A new key is a new batch.
    expect(await loader.loadMany(<int>[2, 3]), <String?>['user 2', 'user 3']);
    expect(users.calls.last, <int>[3]);
  });

  test('a function works too; clear, clearAll and prime', () async {
    List<List<String>> calls = <List<String>>[];
    DataLoader<String, int> loader = DataLoader<String, int>((
      List<String> keys,
    ) async {
      calls.add(keys);
      return <int?>[for (String k in keys) k.length];
    });
    loader.prime('primed', 99);
    expect(await loader.load('primed'), 99);
    expect(await loader.load('abc'), 3);
    loader.clear('abc');
    expect(await loader.load('abc'), 3);
    loader.clearAll();
    expect(await loader.load('primed'), 6);
    expect(calls, <List<String>>[
      <String>['abc'],
      <String>['abc'],
      <String>['primed'],
    ]);
  });

  test('errors reach every load, and are not cached', () async {
    int calls = 0;
    DataLoader<int, int> loader = DataLoader<int, int>((List<int> keys) async {
      calls++;
      if (calls == 1) throw StateError('db down');
      return <int?>[for (int k in keys) k];
    });
    await expectLater(loader.load(1), throwsA(isA<StateError>()));
    expect(await loader.load(1), 1);

    DataLoader<int, int> short = DataLoader<int, int>(
      (List<int> keys) async => <int?>[],
    );
    await expectLater(short.load(1), throwsA(isA<StateError>()));
  });

  test('one key can fail on its own', () async {
    DataLoader<int, String> loader = DataLoader<int, String>.withResults((
      List<int> keys,
    ) async {
      return <LoadResult<String>>[
        for (int k in keys)
          k == 2
              ? LoadError<String>(StateError('no 2'))
              : LoadValue<String>('v$k'),
      ];
    });
    Future<String?> one = loader.load(1);
    Future<String?> two = loader.load(2);
    Future<String?> three = loader.load(3);
    expect(await one, 'v1');
    await expectLater(two, throwsA(isA<StateError>()));
    expect(await three, 'v3');
  });

  test('batches across a GraphQL list (no N+1)', () async {
    ObjectType<Post, LoaderContext> postType = ObjectType<Post, LoaderContext>(
      'Post',
      fields: () => <Field<Post, LoaderContext>>[
        Field<Post, LoaderContext>(
          'id',
          graphqlInt,
          resolve: (Post p, ResolveInfo<LoaderContext> i) => p.id,
        ),
        Field<Post, LoaderContext>(
          'author',
          graphqlString,
          resolve: (Post p, ResolveInfo<LoaderContext> i) =>
              i.context.userLoader.load(p.authorId),
        ),
      ],
    );
    GraphQLSchema<LoaderContext> schema = GraphQLSchema<LoaderContext>(
      query: ObjectType<Object?, LoaderContext>(
        'Query',
        fields: () => <Field<Object?, LoaderContext>>[
          Field<Object?, LoaderContext>(
            'posts',
            postType.list,
            resolve: (Object? _, ResolveInfo<LoaderContext> i) async => <Post>[
              Post(1, 10),
              Post(2, 20),
              Post(3, 10),
            ],
          ),
        ],
      ),
    );
    LoaderContext ctx = LoaderContext();
    GraphQLResponse r = await GraphQLExecutor<LoaderContext>(schema)
        .execute(const GraphQLRequest('{ posts { id author } }'), context: ctx);
    expect(r.data, <String, Object?>{
      'posts': <Object?>[
        <String, Object?>{'id': 1, 'author': 'user 10'},
        <String, Object?>{'id': 2, 'author': 'user 20'},
        <String, Object?>{'id': 3, 'author': 'user 10'},
      ],
    });
    expect(ctx.users.calls, <List<int>>[
      <int>[10, 20],
    ]);
  });
}
