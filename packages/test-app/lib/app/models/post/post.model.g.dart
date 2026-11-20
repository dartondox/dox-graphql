// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.model.dart';

// **************************************************************************
// Generator: DoxModelBuilder
// **************************************************************************

// ignore_for_file: always_specify_types

class PostGenerator extends Model<Post> {
  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> get timestampsColumn => const <String, dynamic>{
    'created_at': 'created_at',
    'updated_at': 'updated_at',
  };

  @override
  String get tableName => 'posts';

  int? get id => tempIdValue as int?;

  set id(int? val) => tempIdValue = val;

  Post query() => Post();

  @override
  bool get readsRowDates => true;

  @override
  List<String> get tableColumns => const <String>[
    'id',
    'title',
    'body',
    'user_id',
    'status',
    'internal_note',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get preloadList => const <String>[];

  @override
  Map<String, Function> get relationsResultMatcher => const <String, Function>{
    'user': getUser,
    'comments': getComments,
    'tags': getTags,
    'images': getImages,
  };

  @override
  Map<String, Function> get relationsQueryMatcher => const <String, Function>{
    'user': queryUser,
    'comments': queryComments,
    'tags': queryTags,
    'images': queryImages,
  };

  static Future<void> getUser(List<Model<Post>> list) async {
    var result = await getBelongsTo<Post, User>(queryUser(list), list);
    for (dynamic i in list) {
      i.user = result[i.tempIdValue.toString()];
    }
  }

  static User? queryUser(List<Model<Post>> list) {
    return belongsTo<Post, User>(list, () => User(), relation: 'user');
  }

  static Future<void> getComments(List<Model<Post>> list) async {
    var result = await getHasMany<Post, Comment>(queryComments(list), list);
    for (dynamic i in list) {
      i.comments = result[i.tempIdValue.toString()] ?? <Comment>[];
    }
  }

  static Comment? queryComments(List<Model<Post>> list) {
    return hasMany<Post, Comment>(list, () => Comment());
  }

  static Future<void> getTags(List<Model<Post>> list) async {
    var result = await getManyToMany<Post, Tag>(queryTags(list), list);
    for (dynamic i in list) {
      i.tags = result[i.tempIdValue.toString()] ?? <Tag>[];
    }
  }

  static Tag? queryTags(List<Model<Post>> list) {
    return manyToMany<Post, Tag>(list, () => Tag(), pivotTable: 'post_tag');
  }

  static Future<void> getImages(List<Model<Post>> list) async {
    var result = await getMorphMany<Post, Image>(queryImages(list), list);
    for (dynamic i in list) {
      i.images = result[i.tempIdValue.toString()] ?? <Image>[];
    }
  }

  static Image? queryImages(List<Model<Post>> list) {
    return morphMany<Post, Image>(list, () => Image(), name: 'imageable');
  }

  static const _statusCast = EnumCast(PostStatus.values);

  @override
  Post fromMap(Map<String, dynamic> m) => Post()
    ..id = m['id'] as int?
    ..title = m['title'] as String?
    ..body = m['body'] as String?
    ..userId = m['user_id'] as int?
    ..status = _statusCast.get(m['status'])
    ..internalNote = m['internal_note'] as String?
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
    Post instance = this as Post;
    Map<String, dynamic> map = <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'user_id': instance.userId,
      'status': _statusCast.set(instance.status),
      'internal_note': instance.internalNote,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

    return map;
  }

  @override
  dynamic $columnValue(String column) {
    Post instance = this as Post;
    switch (column) {
      case 'id':
        return instance.id;
      case 'title':
        return instance.title;
      case 'body':
        return instance.body;
      case 'user_id':
        return instance.userId;
      case 'status':
        return _statusCast.set(instance.status);
      case 'internal_note':
        return instance.internalNote;
      case 'created_at':
        return instance.createdAt?.toIso8601String();
      case 'updated_at':
        return instance.updatedAt?.toIso8601String();
    }
    return super.$columnValue(column);
  }

  @override
  Map<String, dynamic> convertToMap(dynamic i) {
    Post instance = i as Post;
    Map<String, dynamic> map = instance.columnsToMap();

    List<String> preload = getPreload();
    if (preload.contains('user')) {
      map['user'] = toMap(instance.user);
    }
    if (preload.contains('comments')) {
      map['comments'] = toMap(instance.comments);
    }
    if (preload.contains('tags')) {
      map['tags'] = toMap(instance.tags);
    }
    if (preload.contains('images')) {
      map['images'] = toMap(instance.images);
    }

    return map;
  }

  @override
  bool setColumnValue(String column, dynamic value) {
    Post instance = this as Post;
    switch (column) {
      case 'id':
        if (value is! int?) return false;
        instance.id = value;
        return true;
      case 'title':
        if (value is! String?) return false;
        instance.title = value;
        return true;
      case 'body':
        if (value is! String?) return false;
        instance.body = value;
        return true;
      case 'user_id':
        if (value is! int?) return false;
        instance.userId = value;
        return true;
      case 'status':
        if (value is! PostStatus?) return false;
        instance.status = value;
        return true;
      case 'internal_note':
        if (value is! String?) return false;
        instance.internalNote = value;
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
  bool $copyColumnsFrom(Model<Post> other) {
    Post o = other as Post;
    (this as Post)
      ..id = o.id
      ..title = o.title
      ..body = o.body
      ..userId = o.userId
      ..status = o.status
      ..internalNote = o.internalNote
      ..createdAt = o.createdAt
      ..updatedAt = o.updatedAt;
    return true;
  }
}
