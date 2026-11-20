// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image.model.dart';

// **************************************************************************
// Generator: DoxModelBuilder
// **************************************************************************

// ignore_for_file: always_specify_types

class ImageGenerator extends Model<Image> {
  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> get timestampsColumn => const <String, dynamic>{
    'created_at': 'created_at',
    'updated_at': 'updated_at',
  };

  @override
  String get tableName => 'images';

  int? get id => tempIdValue as int?;

  set id(int? val) => tempIdValue = val;

  Image query() => Image();

  @override
  bool get readsRowDates => true;

  @override
  List<String> get tableColumns => const <String>[
    'id',
    'url',
    'imageable_id',
    'imageable_type',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get preloadList => const <String>[];

  @override
  Map<String, Function> get relationsResultMatcher =>
      const <String, Function>{};

  @override
  Map<String, Function> get relationsQueryMatcher => const <String, Function>{};

  @override
  Image fromMap(Map<String, dynamic> m) => Image()
    ..id = m['id'] as int?
    ..url = m['url'] as String?
    ..imageableId = m['imageable_id'] as int?
    ..imageableType = m['imageable_type'] as String?
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
    Image instance = this as Image;
    Map<String, dynamic> map = <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'imageable_id': instance.imageableId,
      'imageable_type': instance.imageableType,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

    return map;
  }

  @override
  dynamic $columnValue(String column) {
    Image instance = this as Image;
    switch (column) {
      case 'id':
        return instance.id;
      case 'url':
        return instance.url;
      case 'imageable_id':
        return instance.imageableId;
      case 'imageable_type':
        return instance.imageableType;
      case 'created_at':
        return instance.createdAt?.toIso8601String();
      case 'updated_at':
        return instance.updatedAt?.toIso8601String();
    }
    return super.$columnValue(column);
  }

  @override
  Map<String, dynamic> convertToMap(dynamic i) {
    Image instance = i as Image;
    Map<String, dynamic> map = instance.columnsToMap();

    return map;
  }

  @override
  bool setColumnValue(String column, dynamic value) {
    Image instance = this as Image;
    switch (column) {
      case 'id':
        if (value is! int?) return false;
        instance.id = value;
        return true;
      case 'url':
        if (value is! String?) return false;
        instance.url = value;
        return true;
      case 'imageable_id':
        if (value is! int?) return false;
        instance.imageableId = value;
        return true;
      case 'imageable_type':
        if (value is! String?) return false;
        instance.imageableType = value;
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
  bool $copyColumnsFrom(Model<Image> other) {
    Image o = other as Image;
    (this as Image)
      ..id = o.id
      ..url = o.url
      ..imageableId = o.imageableId
      ..imageableType = o.imageableType
      ..createdAt = o.createdAt
      ..updatedAt = o.updatedAt;
    return true;
  }
}
