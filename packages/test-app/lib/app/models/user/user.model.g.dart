// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.model.dart';

// **************************************************************************
// Generator: DoxModelBuilder
// **************************************************************************

// ignore_for_file: always_specify_types

class UserGenerator extends Model<User> {
  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> get timestampsColumn => const <String, dynamic>{
    'created_at': 'created_at',
    'updated_at': 'updated_at',
  };

  @override
  String get tableName => 'users';

  int? get id => tempIdValue as int?;

  set id(int? val) => tempIdValue = val;

  User query() => User();

  @override
  bool get readsRowDates => true;

  @override
  List<String> get tableColumns => const <String>[
    'id',
    'name',
    'password',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get preloadList => const <String>[];

  @override
  Map<String, Function> get relationsResultMatcher => const <String, Function>{
    'posts': getPosts,
  };

  @override
  Map<String, Function> get relationsQueryMatcher => const <String, Function>{
    'posts': queryPosts,
  };

  static Future<void> getPosts(List<Model<User>> list) async {
    var result = await getHasMany<User, Post>(queryPosts(list), list);
    for (dynamic i in list) {
      i.posts = result[i.tempIdValue.toString()] ?? <Post>[];
    }
  }

  static Post? queryPosts(List<Model<User>> list) {
    return hasMany<User, Post>(list, () => Post());
  }

  @override
  User fromMap(Map<String, dynamic> m) => User()
    ..id = m['id'] as int?
    ..name = m['name'] as String?
    ..password = m['password'] as String?
    ..createdAt = switch (m['created_at']) {
      DateTime? v => v,
      Object? v => DateTime.parse(v as String),
    }
    ..updatedAt = switch (m['updated_at']) {
      DateTime? v => v,
      Object? v => DateTime.parse(v as String),
    };
  @override
  Map<String, dynamic> columnsToMap() {
    User instance = this as User;
    Map<String, dynamic> map = <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'password': instance.password,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

    return map;
  }

  @override
  dynamic $columnValue(String column) {
    User instance = this as User;
    switch (column) {
      case 'id':
        return instance.id;
      case 'name':
        return instance.name;
      case 'password':
        return instance.password;
      case 'created_at':
        return instance.createdAt?.toIso8601String();
      case 'updated_at':
        return instance.updatedAt?.toIso8601String();
    }
    return super.$columnValue(column);
  }

  @override
  Map<String, dynamic> convertToMap(dynamic i) {
    User instance = i as User;
    Map<String, dynamic> map = instance.columnsToMap();

    List<String> preload = getPreload();
    if (preload.contains('posts')) {
      map['posts'] = toMap(instance.posts);
    }

    return map;
  }

  @override
  bool setColumnValue(String column, dynamic value) {
    User instance = this as User;
    switch (column) {
      case 'id':
        if (value is! int?) return false;
        instance.id = value;
        return true;
      case 'name':
        if (value is! String?) return false;
        instance.name = value;
        return true;
      case 'password':
        if (value is! String?) return false;
        instance.password = value;
        return true;
      case 'created_at':
        if (value is! DateTime?) return false;
        instance.createdAt = value;
        return true;
      case 'updated_at':
        if (value is! DateTime?) return false;
        instance.updatedAt = value;
        return true;
    }
    return false;
  }

  @override
  bool $copyColumnsFrom(Model<User> other) {
    User o = other as User;
    (this as User)
      ..id = o.id
      ..name = o.name
      ..password = o.password
      ..createdAt = o.createdAt
      ..updatedAt = o.updatedAt;
    return true;
  }
}
