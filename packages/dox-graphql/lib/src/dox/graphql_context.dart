import 'package:dox_core/dox_core.dart';

import '../data_loader.dart';
import 'graphql_auth.dart';

/// The context every resolver gets in a Dox app (`info.context`). One is
/// made for each HTTP request.
///
/// ```dart
/// resolve: (Object? _, ResolveInfo<DoxGraphQLContext> info) async {
///   User? me = await info.context.user<User>();
///   PostService posts = info.context.make<PostService>();
///   return posts.forUser(me);
/// }
/// ```
class DoxGraphQLContext {
  /// [login] are the auth middleware of the config, in their optional
  /// form. They run the first time the user is needed.
  DoxGraphQLContext(
    this.request,
    this._container, {
    this._login = const <IAuthMiddleware>[],
  });

  /// The HTTP request.
  final DoxRequest request;

  final IocContainer _container;

  final List<IAuthMiddleware> _login;

  /// The login of this request, read once.
  Future<IAuth?>? _auth;

  /// The loaders of this request, by name.
  final Map<String, DataLoader<Object?, Object?>> _loaders =
      <String, DataLoader<Object?, Object?>>{};

  /// The auth of the logged-in user, or null for a guest.
  ///
  /// The auth middleware of the config (like `AuthMiddleware` of
  /// dox_auth) runs here, the first time a field needs the user. A
  /// request that never needs the user does no token lookup. Later
  /// calls in the same request, also from fields that run at the same
  /// time, get the same answer.
  Future<IAuth?> auth() => _auth ??= _load();

  /// The logged-in user, or null for a guest. See [auth].
  Future<T?> user<T>() async => (await auth())?.user<T>();

  Future<IAuth?> _load() async {
    for (IAuthMiddleware login in _login) {
      if (request.auth != null) break;
      Object? result = login.handle(request);
      if (result is Future<Object?>) await result;
    }
    return request.auth;
  }

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
