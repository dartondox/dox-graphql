// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.model.dart';

// **************************************************************************
// Generator: DoxModelBuilder
// **************************************************************************

// ignore_for_file: always_specify_types

class NoteGenerator extends Model<Note> {
  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> get timestampsColumn => const <String, dynamic>{
    'created_at': 'created_at',
    'updated_at': 'updated_at',
  };

  @override
  String get tableName => 'notes';

  int? get id => tempIdValue as int?;

  set id(int? val) => tempIdValue = val;

  Note query() => Note();

  @override
  bool get readsRowDates => true;

  @override
  List<String> get tableColumns => const <String>[
    'id',
    'title',
    'user_id',
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
  Note fromMap(Map<String, dynamic> m) => Note()
    ..id = m['id'] as int?
    ..title = m['title'] as String?
    ..userId = m['user_id'] as int?
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
    Note instance = this as Note;
    Map<String, dynamic> map = <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'user_id': instance.userId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

    return map;
  }

  @override
  dynamic $columnValue(String column) {
    Note instance = this as Note;
    switch (column) {
      case 'id':
        return instance.id;
      case 'title':
        return instance.title;
      case 'user_id':
        return instance.userId;
      case 'created_at':
        return instance.createdAt?.toIso8601String();
      case 'updated_at':
        return instance.updatedAt?.toIso8601String();
    }
    return super.$columnValue(column);
  }

  @override
  Map<String, dynamic> convertToMap(dynamic i) {
    Note instance = i as Note;
    Map<String, dynamic> map = instance.columnsToMap();

    return map;
  }

  @override
  bool setColumnValue(String column, dynamic value) {
    Note instance = this as Note;
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
  bool $copyColumnsFrom(Model<Note> other) {
    Note o = other as Note;
    (this as Note)
      ..id = o.id
      ..title = o.title
      ..userId = o.userId
      ..createdAt = o.createdAt
      ..updatedAt = o.updatedAt;
    return true;
  }
}
