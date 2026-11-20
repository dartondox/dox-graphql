// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.model.dart';

// **************************************************************************
// Generator: DoxModelBuilder
// **************************************************************************

// ignore_for_file: always_specify_types

class CommentGenerator extends Model<Comment> {
  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> get timestampsColumn => const <String, dynamic>{
    'created_at': 'created_at',
    'updated_at': 'updated_at',
  };

  @override
  String get tableName => 'comments';

  int? get id => tempIdValue as int?;

  set id(int? val) => tempIdValue = val;

  Comment query() => Comment();

  @override
  bool get readsRowDates => true;

  @override
  List<String> get tableColumns => const <String>[
    'id',
    'body',
    'post_id',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get preloadList => const <String>[];

  @override
  Map<String, Function> get relationsResultMatcher => const <String, Function>{
    'post': getPost,
  };

  @override
  Map<String, Function> get relationsQueryMatcher => const <String, Function>{
    'post': queryPost,
  };

  static Future<void> getPost(List<Model<Comment>> list) async {
    var result = await getBelongsTo<Comment, Post>(queryPost(list), list);
    for (dynamic i in list) {
      i.post = result[i.tempIdValue.toString()];
    }
  }

  static Post? queryPost(List<Model<Comment>> list) {
    return belongsTo<Comment, Post>(list, () => Post(), relation: 'post');
  }

  @override
  Comment fromMap(Map<String, dynamic> m) => Comment()
    ..id = m['id'] as int?
    ..body = m['body'] as String?
    ..postId = m['post_id'] as int?
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
    Comment instance = this as Comment;
    Map<String, dynamic> map = <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'post_id': instance.postId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

    return map;
  }

  @override
  dynamic $columnValue(String column) {
    Comment instance = this as Comment;
    switch (column) {
      case 'id':
        return instance.id;
      case 'body':
        return instance.body;
      case 'post_id':
        return instance.postId;
      case 'created_at':
        return instance.createdAt?.toIso8601String();
      case 'updated_at':
        return instance.updatedAt?.toIso8601String();
    }
    return super.$columnValue(column);
  }

  @override
  Map<String, dynamic> convertToMap(dynamic i) {
    Comment instance = i as Comment;
    Map<String, dynamic> map = instance.columnsToMap();

    List<String> preload = getPreload();
    if (preload.contains('post')) {
      map['post'] = toMap(instance.post);
    }

    return map;
  }

  @override
  bool setColumnValue(String column, dynamic value) {
    Comment instance = this as Comment;
    switch (column) {
      case 'id':
        if (value is! int?) return false;
        instance.id = value;
        return true;
      case 'body':
        if (value is! String?) return false;
        instance.body = value;
        return true;
      case 'post_id':
        if (value is! int?) return false;
        instance.postId = value;
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
  bool $copyColumnsFrom(Model<Comment> other) {
    Comment o = other as Comment;
    (this as Comment)
      ..id = o.id
      ..body = o.body
      ..postId = o.postId
      ..createdAt = o.createdAt
      ..updatedAt = o.updatedAt;
    return true;
  }
}
