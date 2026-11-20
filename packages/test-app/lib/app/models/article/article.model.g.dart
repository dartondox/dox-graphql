// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.model.dart';

// **************************************************************************
// Generator: DoxModelBuilder
// **************************************************************************

// ignore_for_file: always_specify_types

class ArticleGenerator extends Model<Article> with SoftDeletes<Article> {
  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> get timestampsColumn => const <String, dynamic>{
    'created_at': 'created_at',
    'updated_at': 'updated_at',
  };

  @override
  String get tableName => 'articles';

  int? get id => tempIdValue as int?;

  set id(int? val) => tempIdValue = val;

  Article query() => Article();

  @override
  bool get readsRowDates => true;

  @override
  List<String> get tableColumns => const <String>[
    'id',
    'title',
    'user_id',
    'deleted_at',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get preloadList => const <String>[];

  @override
  Map<String, Function> get relationsResultMatcher => const <String, Function>{
    'user': getUser,
  };

  @override
  Map<String, Function> get relationsQueryMatcher => const <String, Function>{
    'user': queryUser,
  };

  static Future<void> getUser(List<Model<Article>> list) async {
    var result = await getBelongsTo<Article, User>(queryUser(list), list);
    for (dynamic i in list) {
      i.user = result[i.tempIdValue.toString()];
    }
  }

  static User? queryUser(List<Model<Article>> list) {
    return belongsTo<Article, User>(list, () => User(), relation: 'user');
  }

  @override
  Article fromMap(Map<String, dynamic> m) => Article()
    ..id = m['id'] as int?
    ..title = m['title'] as String?
    ..userId = m['user_id'] as int?
    ..deletedAt = switch (m['deleted_at']) {
      DateTime? v => v,
      Object? v => DateTime.parse(v as String),
    }
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
    Article instance = this as Article;
    Map<String, dynamic> map = <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'user_id': instance.userId,
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

    return map;
  }

  @override
  dynamic $columnValue(String column) {
    Article instance = this as Article;
    switch (column) {
      case 'id':
        return instance.id;
      case 'title':
        return instance.title;
      case 'user_id':
        return instance.userId;
      case 'deleted_at':
        return instance.deletedAt?.toIso8601String();
      case 'created_at':
        return instance.createdAt?.toIso8601String();
      case 'updated_at':
        return instance.updatedAt?.toIso8601String();
    }
    return super.$columnValue(column);
  }

  @override
  Map<String, dynamic> convertToMap(dynamic i) {
    Article instance = i as Article;
    Map<String, dynamic> map = instance.columnsToMap();

    List<String> preload = getPreload();
    if (preload.contains('user')) {
      map['user'] = toMap(instance.user);
    }

    return map;
  }

  @override
  bool setColumnValue(String column, dynamic value) {
    Article instance = this as Article;
    switch (column) {
      case 'id':
        if (value is! int?) return false;
        instance.id = value;
        return true;
      case 'title':
        if (value is! String?) return false;
        instance.title = value;
        return true;
      case 'user_id':
        if (value is! int?) return false;
        instance.userId = value;
        return true;
      case 'deleted_at':
        if (value is! DateTime?) return false;
        instance.deletedAt = value;
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
  bool $copyColumnsFrom(Model<Article> other) {
    Article o = other as Article;
    (this as Article)
      ..id = o.id
      ..title = o.title
      ..userId = o.userId
      ..deletedAt = o.deletedAt
      ..createdAt = o.createdAt
      ..updatedAt = o.updatedAt;
    return true;
  }
}
