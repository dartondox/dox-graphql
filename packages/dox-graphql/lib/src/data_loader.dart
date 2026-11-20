import 'dart:async';

/// Loads many keys in one call. Implement it, or pass a function to
/// [DataLoader].
abstract interface class BatchLoader<K, V> {
  /// Returns one value per key, in the same order. Null when a key has no
  /// value.
  Future<List<V?>> load(List<K> keys);
}

/// The result of loading one key: a value or an error.
sealed class LoadResult<V> {
  const LoadResult();
}

/// A loaded value. Null when the key has no value.
final class LoadValue<V> extends LoadResult<V> {
  const LoadValue(this.value);

  final V? value;
}

/// A key that failed. Only the load of this key fails.
final class LoadError<V> extends LoadResult<V> {
  const LoadError(this.error, [this.stackTrace]);

  /// What the load of this key throws. Dart can throw any object, so this
  /// is not typed.
  final Object error;
  final StackTrace? stackTrace;
}

/// Batches and caches loads of one kind of value.
///
/// All [load] calls in the same event-loop turn become one call of the
/// batch function. Each key is loaded once: later loads get the cached
/// value. Make a new loader for each request, so that the cache lives only
/// as long as the request.
///
/// ```dart
/// DataLoader<int, User> users = DataLoader<int, User>(repository.findByIds);
/// User? user = await users.load(7);
/// ```
final class DataLoader<K, V> {
  /// A loader with a batch function that returns one value per key.
  DataLoader(Future<List<V?>> Function(List<K> keys) batch)
    : _batch = _wrap(batch);

  /// A loader that calls [loader].
  DataLoader.of(BatchLoader<K, V> loader) : _batch = _wrap(loader.load);

  /// A loader with a batch function that returns one [LoadResult] per key.
  /// Use it when some keys can fail on their own.
  DataLoader.withResults(this._batch);

  final Future<List<LoadResult<V>>> Function(List<K> keys) _batch;
  final Map<K, Future<V?>> _cache = <K, Future<V?>>{};
  List<K> _keys = <K>[];
  List<Completer<V?>> _waiting = <Completer<V?>>[];

  static Future<List<LoadResult<V>>> Function(List<K> keys) _wrap<K, V>(
    Future<List<V?>> Function(List<K> keys) batch,
  ) {
    return (List<K> keys) async => <LoadResult<V>>[
      for (V? v in await batch(keys)) LoadValue<V>(v),
    ];
  }

  /// Loads one key.
  Future<V?> load(K key) {
    Future<V?>? cached = _cache[key];
    if (cached != null) return cached;
    Completer<V?> completer = Completer<V?>();
    if (_keys.isEmpty) Timer.run(_dispatch);
    _keys.add(key);
    _waiting.add(completer);
    return _cache[key] = completer.future;
  }

  /// Loads many keys, in one batch with the other loads of this turn.
  Future<List<V?>> loadMany(List<K> keys) =>
      Future.wait(<Future<V?>>[for (K k in keys) load(k)]);

  /// Puts a value in the cache, when the key is not there yet.
  void prime(K key, V? value) {
    _cache.putIfAbsent(key, () => Future<V?>.value(value));
  }

  /// Removes one key from the cache, for example after a change.
  void clear(K key) => _cache.remove(key);

  /// Removes all keys from the cache.
  void clearAll() => _cache.clear();

  Future<void> _dispatch() async {
    List<K> keys = _keys;
    List<Completer<V?>> waiting = _waiting;
    _keys = <K>[];
    _waiting = <Completer<V?>>[];
    List<LoadResult<V>> results;
    try {
      results = await _batch(keys);
      if (results.length != keys.length) {
        throw StateError(
          'The batch function of a DataLoader must return one value per '
          'key: it got ${keys.length} keys and returned ${results.length} '
          'values.',
        );
      }
    } catch (e, st) {
      results = <LoadResult<V>>[for (K _ in keys) LoadError<V>(e, st)];
    }
    for (int i = 0; i < keys.length; i++) {
      switch (results[i]) {
        case LoadValue<V>(:V? value):
          waiting[i].complete(value);
        case LoadError<V>(:Object error, :StackTrace? stackTrace):
          // A failed key is not cached, so a later load tries again.
          _cache.remove(keys[i])?.ignore();
          waiting[i].completeError(error, stackTrace);
      }
    }
  }
}
