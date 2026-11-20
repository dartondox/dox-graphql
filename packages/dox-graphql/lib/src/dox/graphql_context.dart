import 'package:dox_core/dox_core.dart';

import '../data_loader.dart';

/// The context every resolver gets in a Dox app (`info.context`). One is
/// made for each HTTP request.
///
/// ```dart
/// resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) {
///   User? me = info.context.user<User>();
///   PostService posts = info.context.make<PostService>();
///   return posts.forUser(me);
/// }
/// ```
class DoxGraphQLContext {
  DoxGraphQLContext(this.request, this._container);

  /// The HTTP request.
  final DoxRequest request;

  final IocContainer _container;

  /// The loaders of this request, by name.
  final Map<String, DataLoader<Object?, Object?>> _loaders =
      <String, DataLoader<Object?, Object?>>{};

  /// The auth of the logged-in user, set by an auth middleware (like
  /// `AuthMiddleware` of dox_auth). Null for a guest.
  IAuth? get auth => request.auth;

  /// The logged-in user, or null for a guest.
  T? user<T>() => request.auth?.user<T>();

  /// A service from the Dox container.
  T make<T extends Object>() => _container.get<T>();

  /// The [DataLoader] named [name] of this request. The first call makes
  /// it with [create]; later calls in the same request get the same one.
  /// Each request has its own loaders, so a cache never leaks to another
  /// request.
  ///
  /// ```dart
  /// DataLoader<int, User> users = info.context.loader<int, User>(
  ///   'users',
  ///   () => DataLoader<int, User>(userRepository.findByIds),
  /// );
  /// ```
  DataLoader<K, V> loader<K, V>(
    String name,
    DataLoader<K, V> Function() create,
  ) {
    DataLoader<Object?, Object?>? found = _loaders[name];
    if (found == null) {
      DataLoader<K, V> made = create();
      _loaders[name] = made;
      return made;
    }
    if (found is DataLoader<K, V>) return found;
    throw StateError(
      'The DataLoader "$name" is a ${found.runtimeType}, not a '
      'DataLoader<$K, $V>. Use another name for each kind of loader.',
    );
  }
}
