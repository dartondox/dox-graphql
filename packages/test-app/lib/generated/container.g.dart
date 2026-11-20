// GENERATED CODE - DO NOT MODIFY BY HAND
// Made by dox_builder. Run `dart run build_runner build`.
// ignore_for_file: type=lint

import 'package:dox_core/dox_core.dart';
import 'package:dox_graphql_test_app/app/repositories/repositories.dart' as i1;

/// Puts every class of the app into the container: the
/// `@Inject()` classes, routers, providers and model binders.
/// Use it in `AppConfig(container: registerContainer)`.
void registerContainer(IocContainer c) {
  c.singleton<i1.BookRepository>((IocContainer c) => i1.BookRepository());
  c.singleton<i1.AuthorRepository>((IocContainer c) => i1.AuthorRepository());
}
