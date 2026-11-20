// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_dto.dart';

// **************************************************************************
// DoxDtoGenerator
// **************************************************************************

// ignore_for_file: type=lint

/// The checks, the converter and the JSON Schema of [ArticleDto].
const DtoSchema<ArticleDto> $ArticleDtoDto = _$ArticleDtoDto();

class _$ArticleDtoDto extends DtoSchema<ArticleDto> {
  const _$ArticleDtoDto();

  static const Map<String, String> _m = <String, String>{};

  @override
  Type get type => ArticleDto;

  @override
  String get name => 'ArticleDto';

  @override
  bool get usesRequiredWhen => false;

  @override
  ArticleDto? convert(Object? input, DtoState s, List<Object> p) {
    if (input is! Map) {
      s.notObject(input, p, _m);
      return null;
    }
    int e = s.issues.length;
    // title: String
    Object? c0;
    c0 = s.string(s.read(input, 'title'), p, 'title', _m);
    if (c0 == null || c0 is Undefined) s.required(p, 'title', _m);
    if (s.issues.length != e && !s.allErrors) return null;
    if (s.issues.length != e) return null;
    return ArticleDto(title: c0 as String);
  }

  @override
  ArticleDto fromMap(Map<String, dynamic> m) {
    return ArticleDto(title: m['title'] as String);
  }

  @override
  Map<String, dynamic> toMap(ArticleDto o) {
    String f0 = o.title;
    return <String, dynamic>{'title': f0};
  }

  @override
  Map<String, dynamic> toJsonSchema() {
    return <String, dynamic>{
      'type': 'object',
      'title': 'ArticleDto',
      'properties': <String, dynamic>{
        'title': <String, dynamic>{'type': 'string'},
      },
      'required': <dynamic>['title'],
    };
  }
}
