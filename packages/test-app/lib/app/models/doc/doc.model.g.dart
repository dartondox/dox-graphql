// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doc.model.dart';

// **************************************************************************
// Generator: DoxModelBuilder
// **************************************************************************

// ignore_for_file: always_specify_types

class DocGenerator extends Model<Doc> {
  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> get timestampsColumn => const <String, dynamic>{
    'created_at': 'created_at',
    'updated_at': 'updated_at',
  };

  @override
  String get tableName => 'docs';

  int? get id => tempIdValue as int?;

  set id(int? val) => tempIdValue = val;

  Doc query() => Doc();

  @override
  bool get readsRowDates => true;

  @override
  List<String> get tableColumns => const <String>[
    'id',
    'title',
    'owner',
    'account_id',
    'parent_id',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get preloadList => const <String>[];

  @override
  Map<String, Function> get relationsResultMatcher => const <String, Function>{
    'parent': getParent,
    'child': getChild,
  };

  @override
  Map<String, Function> get relationsQueryMatcher => const <String, Function>{
    'parent': queryParent,
    'child': queryChild,
  };

  static Future<void> getParent(List<Model<Doc>> list) async {
    var result = await getBelongsTo<Doc, Doc>(queryParent(list), list);
    for (dynamic i in list) {
      if (result[i.tempIdValue.toString()] != null) {
        i.parent = result[i.tempIdValue.toString()]!;
      }
    }
  }

  static Doc? queryParent(List<Model<Doc>> list) {
    return belongsTo<Doc, Doc>(
      list,
      () => Doc(),
      foreignKey: 'parent_id',
      relation: 'parent',
    );
  }

  static Future<void> getChild(List<Model<Doc>> list) async {
    var result = await getHasOne<Doc, Doc>(queryChild(list), list);
    for (dynamic i in list) {
      i.child = result[i.tempIdValue.toString()];
    }
  }

  static Doc? queryChild(List<Model<Doc>> list) {
    return hasOne<Doc, Doc>(list, () => Doc(), foreignKey: 'parent_id');
  }

  @override
  Doc fromMap(Map<String, dynamic> m) => Doc()
    ..id = m['id'] as int?
    ..title = m['title'] as String?
    ..owner = m['owner'] as String?
    ..accountId = m['account_id'] as int?
    ..parentId = m['parent_id'] as int?
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
    Doc instance = this as Doc;
    Map<String, dynamic> map = <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'owner': instance.owner,
      'account_id': instance.accountId,
      'parent_id': instance.parentId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

    return map;
  }

  @override
  dynamic $columnValue(String column) {
    Doc instance = this as Doc;
    switch (column) {
      case 'id':
        return instance.id;
      case 'title':
        return instance.title;
      case 'owner':
        return instance.owner;
      case 'account_id':
        return instance.accountId;
      case 'parent_id':
        return instance.parentId;
      case 'created_at':
        return instance.createdAt?.toIso8601String();
      case 'updated_at':
        return instance.updatedAt?.toIso8601String();
    }
    return super.$columnValue(column);
  }

  @override
  Map<String, dynamic> convertToMap(dynamic i) {
    Doc instance = i as Doc;
    Map<String, dynamic> map = instance.columnsToMap();

    List<String> preload = getPreload();
    if (preload.contains('parent')) {
      map['parent'] = toMap(instance.parent);
    }
    if (preload.contains('child')) {
      map['child'] = toMap(instance.child);
    }

    return map;
  }

  @override
  bool setColumnValue(String column, dynamic value) {
    Doc instance = this as Doc;
    switch (column) {
      case 'id':
        if (value is! int?) return false;
        instance.id = value;
        return true;
      case 'title':
        if (value is! String?) return false;
        instance.title = value;
        return true;
      case 'owner':
        if (value is! String?) return false;
        instance.owner = value;
        return true;
      case 'account_id':
        if (value is! int?) return false;
        instance.accountId = value;
        return true;
      case 'parent_id':
        if (value is! int?) return false;
        instance.parentId = value;
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
  bool $copyColumnsFrom(Model<Doc> other) {
    Doc o = other as Doc;
    (this as Doc)
      ..id = o.id
      ..title = o.title
      ..owner = o.owner
      ..accountId = o.accountId
      ..parentId = o.parentId
      ..createdAt = o.createdAt
      ..updatedAt = o.updatedAt;
    return true;
  }
}
