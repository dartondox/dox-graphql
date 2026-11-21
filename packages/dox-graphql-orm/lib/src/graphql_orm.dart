import 'package:dox_graphql/dox_graphql.dart';
import 'package:dox_orm/dox_orm.dart';

/// Reads and writes models of dox_orm for GraphQL. The code that
/// `dox_graphql_builder` writes for the `@GraphQLAll`, `@GraphQLFind`,
/// ... annotations of models calls it.
class GraphQLOrm {
  const GraphQLOrm._();

  /// The most rows one list query can read.
  static const int maxLimit = 100;

  /// The rows of the list query: `posts(limit: Int = 20, offset: Int = 0)`.
  /// A [limit] above [maxLimit] is an error, so one query can not read
  /// the whole table.
  static Future<List<M>> list<M extends Model<M>>(
    M query,
    ResolveInfo<DoxGraphQLContext> info,
  ) {
    int limit = info.args.get<int>('limit') ?? 20;
    int offset = info.args.get<int>('offset') ?? 0;
    if (limit > maxLimit) {
      throw GraphQLError('"limit" can be at most $maxLimit.');
    }
    if (limit < 0 || offset < 0) {
      throw GraphQLError('"limit" and "offset" can not be negative.');
    }
    return query.orderBy(query.primaryKey).limit(limit).offset(offset).get();
  }

  /// The page of the paged list query:
  /// `posts(first: Int = 20, page: Int = 1)`. It uses `paginate` of
  /// dox_orm: one count query and one page query. A [first] above
  /// [maxLimit] is an error, like the `limit` of [list].
  static Future<Pagination<M>> paginate<M extends Model<M>>(
    M query,
    ResolveInfo<DoxGraphQLContext> info,
  ) {
    int first = info.args.get<int>('first') ?? 20;
    int page = info.args.get<int>('page') ?? 1;
    if (first > maxLimit) {
      throw GraphQLError('"first" can be at most $maxLimit.');
    }
    if (first < 1 || page < 1) {
      throw GraphQLError('"first" and "page" must be at least 1.');
    }
    return query
        .orderBy(query.primaryKey)
        .paginate(currentPage: page, perPage: first);
  }

  /// [page] with only the rows [kept] (of `filter:`). The page keeps the
  /// number of its rows before the filter, for `firstItem` and
  /// `lastItem`.
  static Pagination<T> filteredPage<T>(Pagination<T> page, List<T> kept) {
    return _FilteredPage<T>(page, kept);
  }

  /// The `PaginatorInfo` type of every paged list query: the numbers of
  /// the page. `count` is the number of rows in `data`. `firstItem` and
  /// `lastItem` are the numbers of the first and last row of the page
  /// (from 1), null on an empty page.
  ///
  /// With `filter:` on the model, the rows that the filter drops are
  /// left out of `data` and `count`. `total`, `lastPage`, `firstItem` and
  /// `lastItem` still count them: the queries run before the filter, so
  /// these numbers agree with each other.
  static final ObjectType<Pagination<Object?>, DoxGraphQLContext>
  paginatorInfo = ObjectType<Pagination<Object?>, DoxGraphQLContext>(
    'PaginatorInfo',
    description: 'The numbers of a page of a paged list.',
    fields: () => <Field<Pagination<Object?>, DoxGraphQLContext>>[
      _info('count', graphqlInt.nonNull, _count),
      _info('currentPage', graphqlInt.nonNull, _currentPage),
      _info('firstItem', graphqlInt, _firstItem),
      _info('lastItem', graphqlInt, _lastItem),
      _info('hasMorePages', graphqlBoolean.nonNull, _hasMorePages),
      _info('lastPage', graphqlInt.nonNull, _lastPage),
      _info('perPage', graphqlInt.nonNull, _perPage),
      _info('total', graphqlInt.nonNull, _total),
    ],
  );

  static Field<Pagination<Object?>, DoxGraphQLContext> _info(
    String name,
    GraphQLTypeRef type,
    Object? Function(Pagination<Object?> page) read,
  ) {
    return Field<Pagination<Object?>, DoxGraphQLContext>(
      name,
      type,
      resolve: (Pagination<Object?> s, ResolveInfo<DoxGraphQLContext> _) =>
          read(s),
    );
  }

  static int _count(Pagination<Object?> p) => p.data.length;
  static int _currentPage(Pagination<Object?> p) => p.currentPage;

  /// The rows of the page before the filter.
  static int _rows(Pagination<Object?> p) =>
      p is _FilteredPage<Object?> ? p.rows : p.data.length;
  static int? _firstItem(Pagination<Object?> p) =>
      _rows(p) == 0 ? null : (p.currentPage - 1) * p.perPage + 1;
  static int? _lastItem(Pagination<Object?> p) =>
      _rows(p) == 0 ? null : (p.currentPage - 1) * p.perPage + _rows(p);
  static bool _hasMorePages(Pagination<Object?> p) =>
      p.currentPage < p.lastPage;
  static int _lastPage(Pagination<Object?> p) => p.lastPage;
  static int _perPage(Pagination<Object?> p) => p.perPage;
  static int _total(Pagination<Object?> p) => p.total;

  /// The row with key [id], or null. A null [id] (an id that is not a
  /// number, for a number key) gives null.
  static Future<M?> find<M extends Model<M>>(M query, Object? id) async {
    if (id == null) return null;
    return query.find(id);
  }

  /// The relation [name] of [parent], read with [read].
  ///
  /// A relation that is already loaded (preloaded, or `eager: true`) runs
  /// no query. Else the relation is loaded for every parent of this
  /// request in one batch: one `WHERE ... IN` query per relation and
  /// level, so there is no N+1 problem.
  ///
  /// A relation with no related row gives null, also for a `late` field
  /// (not nullable in Dart) that the model leaves unset.
  static Future<R?> relation<P extends Model<P>, R>(
    P parent,
    String name,
    DoxGraphQLContext context,
    R Function(P parent) read,
  ) async {
    if (parent.getPreload().contains(name)) return _readOrNull(parent, read);
    DataLoader<P, bool> loader = context.loader<P, bool>(
      'dox_graphql_orm:$P.$name',
      () => DataLoader<P, bool>((List<P> parents) => _load(parents, name)),
    );
    await loader.load(parent);
    return _readOrNull(parent, read);
  }

  /// [read] of [parent], or null when a `late` field is not set.
  static R? _readOrNull<P, R>(P parent, R Function(P parent) read) {
    try {
      return read(parent);
    } on Error catch (e) {
      // ponytail: LateError is not a public type, and its runtimeType
      // name is renamed by `--obfuscate`. Its message is not.
      if (e.toString().contains('has not been initialized')) return null;
      rethrow;
    }
  }

  /// The list relation [name] of [parent] (`HasMany`, `ManyToMany`,
  /// `HasManyThrough`, `MorphMany`), read with [read] when preloaded.
  ///
  /// Like [relation], it loads every parent of the request in one batch.
  /// The batch query has `LIMIT maxRelationRows + 1`, with
  /// `GraphQLConfig.maxRelationRows`: more rows is an error. [pivot] is
  /// true for `ManyToMany`.
  static Future<List<R>?> many<P extends Model<P>, R>(
    P parent,
    String name,
    DoxGraphQLContext context,
    List<R>? Function(P parent) read, {
    bool pivot = false,
  }) async {
    if (parent.getPreload().contains(name)) return read(parent);
    DataLoader<P, List<R>> loader = context.loader<P, List<R>>(
      'dox_graphql_orm:many:$P.$name',
      () => DataLoader<P, List<R>>(
        (List<P> parents) =>
            _loadMany<P, R>(parents, name, pivot, context.maxRelationRows),
      ),
    );
    return (await loader.load(parent)) ?? <R>[];
  }

  static Future<List<List<R>>> _loadMany<P extends Model<P>, R>(
    List<P> parents,
    String name,
    bool pivot,
    int maxRows,
  ) async {
    Function? query = parents.first.relationsQueryMatcher[name];
    if (query == null) {
      throw StateError('"$name" is not a relation of $P.');
    }
    // the generated query builders take a List<Model<P>>
    Object? q = Function.apply(query, <Object?>[
      <Model<P>>[...parents],
    ]);
    if (q is! QueryBuilder<Object?>) {
      throw StateError(
        'The query of relation $P.$name is not a QueryBuilder but '
        '${q.runtimeType}. Run the dox_orm model builder again.',
      );
    }
    q.limit(maxRows + 1);
    Map<String, List<R>> rows = pivot
        ? await getManyToMany<P, R>(q, parents)
        : await getHasMany<P, R>(q, parents);
    int count = 0;
    for (List<R> list in rows.values) {
      count += list.length;
    }
    if (count > maxRows) {
      throw GraphQLError(
        'The relation $P.$name has more than $maxRows rows for this '
        'request (GraphQLConfig.maxRelationRows). Ask for fewer parents, '
        'or page it in a resolver.',
      );
    }
    return <List<R>>[
      for (P p in parents) rows[p.tempIdValue.toString()] ?? <R>[],
    ];
  }

  /// Loads relation [name] into its field on each of [parents], with the
  /// loader the model generator made for it.
  static Future<List<bool?>> _load<P extends Model<P>>(
    List<P> parents,
    String name,
  ) async {
    Function? load = parents.first.relationsResultMatcher[name];
    if (load == null) {
      throw StateError('"$name" is not a relation of $P.');
    }
    // the generated loaders take a List<Model<P>> and fill the fields
    await (Function.apply(load, <Object?>[
      <Model<P>>[...parents],
    ]) as Future<Object?>);
    return <bool?>[for (P _ in parents) true];
  }
}

/// A page after `filter:`: [data] has only the allowed rows, [rows] is
/// the number of rows before the filter.
class _FilteredPage<T> extends Pagination<T> {
  _FilteredPage(Pagination<T> page, List<T> kept)
    : rows = page.data.length,
      super(
        total: page.total,
        perPage: page.perPage,
        lastPage: page.lastPage,
        currentPage: page.currentPage,
        data: kept,
      );

  final int rows;
}
