// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_dto.dart';

// **************************************************************************
// DoxDtoGenerator
// **************************************************************************

// ignore_for_file: type=lint

/// The checks, the converter and the JSON Schema of [NoteDto].
const DtoSchema<NoteDto> $NoteDtoDto = _$NoteDtoDto();

class _$NoteDtoDto extends DtoSchema<NoteDto> {
  const _$NoteDtoDto();

  static const Map<String, String> _m = <String, String>{};

  @override
  Type get type => NoteDto;

  @override
  String get name => 'NoteDto';

  @override
  bool get usesRequiredWhen => false;

  @override
  NoteDto? convert(Object? input, DtoState s, List<Object> p) {
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
    return NoteDto(title: c0 as String);
  }

  @override
  NoteDto fromMap(Map<String, dynamic> m) {
    return NoteDto(title: m['title'] as String);
  }

  @override
  Map<String, dynamic> toMap(NoteDto o) {
    String f0 = o.title;
    return <String, dynamic>{'title': f0};
  }

  @override
  Map<String, dynamic> toJsonSchema() {
    return <String, dynamic>{
      'type': 'object',
      'title': 'NoteDto',
      'properties': <String, dynamic>{
        'title': <String, dynamic>{'type': 'string'},
      },
      'required': <dynamic>['title'],
    };
  }
}
