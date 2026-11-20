// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doc_dto.dart';

// **************************************************************************
// DoxDtoGenerator
// **************************************************************************

// ignore_for_file: type=lint

/// The checks, the converter and the JSON Schema of [DocDto].
const DtoSchema<DocDto> $DocDtoDto = _$DocDtoDto();

class _$DocDtoDto extends DtoSchema<DocDto> {
  const _$DocDtoDto();

  static const Map<String, String> _m = <String, String>{};

  @override
  Type get type => DocDto;

  @override
  String get name => 'DocDto';

  @override
  bool get usesRequiredWhen => false;

  @override
  DocDto? convert(Object? input, DtoState s, List<Object> p) {
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
    return DocDto(title: c0 as String);
  }

  @override
  DocDto fromMap(Map<String, dynamic> m) {
    return DocDto(title: m['title'] as String);
  }

  @override
  Map<String, dynamic> toMap(DocDto o) {
    String f0 = o.title;
    return <String, dynamic>{'title': f0};
  }

  @override
  Map<String, dynamic> toJsonSchema() {
    return <String, dynamic>{
      'type': 'object',
      'title': 'DocDto',
      'properties': <String, dynamic>{
        'title': <String, dynamic>{'type': 'string'},
      },
      'required': <dynamic>['title'],
    };
  }
}
