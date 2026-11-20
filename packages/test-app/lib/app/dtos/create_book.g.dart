// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_book.dart';

// **************************************************************************
// DoxDtoGenerator
// **************************************************************************

// ignore_for_file: type=lint

/// The checks, the converter and the JSON Schema of [CreateBook].
const DtoSchema<CreateBook> $CreateBookDto = _$CreateBookDto();

class _$CreateBookDto extends DtoSchema<CreateBook> {
  const _$CreateBookDto();

  static const Map<String, String> _m = <String, String>{};

  @override
  Type get type => CreateBook;

  @override
  String get name => 'CreateBook';

  @override
  bool get usesRequiredWhen => false;

  @override
  CreateBook? convert(Object? input, DtoState s, List<Object> p) {
    if (input is! Map) {
      s.notObject(input, p, _m);
      return null;
    }
    int e = s.issues.length;
    // title: String
    Object? c0;
    c0 = s.string(s.read(input, 'title'), p, 'title', _m);
    if (c0 == null || c0 is Undefined) s.required(p, 'title', _m);
    // authorId: int
    Object? c1;
    c1 = s.integer(s.read(input, 'author_id'), p, 'author_id', _m);
    if (c1 == null || c1 is Undefined) s.required(p, 'author_id', _m);
    // genre: Genre?
    Object? c2;
    c2 = s.enumName(s.read(input, 'genre'), p, 'genre', _m, const <String>[
      'novel',
      'poetry',
    ]);
    if (c2 is String) {
      c2 = switch (c2) {
        'novel' => Genre.novel,
        _ => Genre.poetry,
      };
    }
    if (s.issues.length != e && !s.allErrors) return null;
    if (c0 is String) {
      if (!(c0.runes.length >= 3)) {
        s.fail(
          p,
          'title',
          IssueCodes.minLength,
          DefaultMessages.minLength,
          c0,
          params: const <String, Object?>{'min': 3},
          message: 'The title is too short',
          messages: _m,
        );
      }
    }
    if (s.issues.length != e) return null;
    return CreateBook(
      title: c0 as String,
      authorId: c1 as int,
      genre: c2 is Undefined ? null : c2 as Genre?,
    );
  }

  @override
  CreateBook fromMap(Map<String, dynamic> m) {
    return CreateBook(
      title: m['title'] as String,
      authorId: (m['author_id'] as num).toInt(),
      genre: m['genre'] == null
          ? null
          : (Genre.values.byName(m['genre'] as String)),
    );
  }

  @override
  Map<String, dynamic> toMap(CreateBook o) {
    String f0 = o.title;
    int f1 = o.authorId;
    Genre? f2 = o.genre;
    return <String, dynamic>{
      'title': f0,
      'author_id': f1,
      'genre': f2 == null ? null : f2.name,
    };
  }

  @override
  Map<String, dynamic> toJsonSchema() {
    return <String, dynamic>{
      'type': 'object',
      'title': 'CreateBook',
      'properties': <String, dynamic>{
        'title': <String, dynamic>{'type': 'string', 'minLength': 3},
        'author_id': <String, dynamic>{'type': 'integer'},
        'genre': <String, dynamic>{
          'type': <dynamic>['string', 'null'],
          'enum': <dynamic>['novel', 'poetry'],
        },
      },
      'required': <dynamic>['title', 'author_id'],
    };
  }
}
