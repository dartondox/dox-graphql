// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.model.dart';

// **************************************************************************
// Generator: DoxModelBuilder
// **************************************************************************

// ignore_for_file: always_specify_types

class AccountGenerator extends Model<Account> {
  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> get timestampsColumn => const <String, dynamic>{
    'created_at': 'created_at',
    'updated_at': 'updated_at',
  };

  @override
  String get tableName => 'accounts';

  int? get id => tempIdValue as int?;

  set id(int? val) => tempIdValue = val;

  Account query() => Account();

  @override
  bool get readsRowDates => true;

  @override
  List<String> get tableColumns => const <String>[
    'id',
    'name',
    'email',
    'secret',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get preloadList => const <String>[];

  @override
  Map<String, Function> get relationsResultMatcher => const <String, Function>{
    'docs': getDocs,
  };

  @override
  Map<String, Function> get relationsQueryMatcher => const <String, Function>{
    'docs': queryDocs,
  };

  static Future<void> getDocs(List<Model<Account>> list) async {
    var result = await getHasMany<Account, Doc>(queryDocs(list), list);
    for (dynamic i in list) {
      i.docs = result[i.tempIdValue.toString()] ?? <Doc>[];
    }
  }

  static Doc? queryDocs(List<Model<Account>> list) {
    return hasMany<Account, Doc>(list, () => Doc());
  }

  @override
  Account fromMap(Map<String, dynamic> m) => Account()
    ..id = m['id'] as int?
    ..name = m['name'] as String?
    ..email = m['email'] as String?
    ..secret = m['secret'] as String?
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
    Account instance = this as Account;
    Map<String, dynamic> map = <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'secret': instance.secret,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

    return map;
  }

  @override
  dynamic $columnValue(String column) {
    Account instance = this as Account;
    switch (column) {
      case 'id':
        return instance.id;
      case 'name':
        return instance.name;
      case 'email':
        return instance.email;
      case 'secret':
        return instance.secret;
      case 'created_at':
        return instance.createdAt?.toIso8601String();
      case 'updated_at':
        return instance.updatedAt?.toIso8601String();
    }
    return super.$columnValue(column);
  }

  @override
  Map<String, dynamic> convertToMap(dynamic i) {
    Account instance = i as Account;
    Map<String, dynamic> map = instance.columnsToMap();

    List<String> preload = getPreload();
    if (preload.contains('docs')) {
      map['docs'] = toMap(instance.docs);
    }

    return map;
  }

  @override
  bool setColumnValue(String column, dynamic value) {
    Account instance = this as Account;
    switch (column) {
      case 'id':
        if (value is! int?) return false;
        instance.id = value;
        return true;
      case 'name':
        if (value is! String?) return false;
        instance.name = value;
        return true;
      case 'email':
        if (value is! String?) return false;
        instance.email = value;
        return true;
      case 'secret':
        if (value is! String?) return false;
        instance.secret = value;
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
  bool $copyColumnsFrom(Model<Account> other) {
    Account o = other as Account;
    (this as Account)
      ..id = o.id
      ..name = o.name
      ..email = o.email
      ..secret = o.secret
      ..createdAt = o.createdAt
      ..updatedAt = o.updatedAt;
    return true;
  }
}
