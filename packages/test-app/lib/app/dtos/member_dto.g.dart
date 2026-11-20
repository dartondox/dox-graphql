// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_dto.dart';

// **************************************************************************
// DoxDtoGenerator
// **************************************************************************

// ignore_for_file: type=lint

/// The checks, the converter and the JSON Schema of [MemberDto].
const DtoSchema<MemberDto> $MemberDtoDto = _$MemberDtoDto();

class _$MemberDtoDto extends DtoSchema<MemberDto> {
  const _$MemberDtoDto();

  static const Map<String, String> _m = <String, String>{};

  @override
  Type get type => MemberDto;

  @override
  String get name => 'MemberDto';

  @override
  bool get usesRequiredWhen => false;

  @override
  bool get isAsync => true;

  @override
  MemberDto? convert(Object? input, DtoState s, List<Object> p) {
    if (input is! Map) {
      s.notObject(input, p, _m);
      return null;
    }
    int e = s.issues.length;
    // name: String
    Object? c0;
    c0 = s.string(s.read(input, 'name'), p, 'name', _m);
    if (c0 == null || c0 is Undefined) s.required(p, 'name', _m);
    // email: String?
    Object? c1;
    c1 = s.string(s.read(input, 'email'), p, 'email', _m, trim: true);
    if (s.issues.length != e && !s.allErrors) return null;
    if (c0 is String) {
      if (!(c0.runes.length >= 3)) {
        s.fail(
          p,
          'name',
          IssueCodes.minLength,
          DefaultMessages.minLength,
          c0,
          params: const <String, Object?>{'min': 3},
          message: 'The name is too short',
          messages: _m,
        );
      }
    }
    if (c1 is String) {
      if (!(c1.runes.length >= 5)) {
        s.fail(
          p,
          'email',
          IssueCodes.minLength,
          DefaultMessages.minLength,
          c1,
          params: const <String, Object?>{'min': 5},
          message: 'The email is too short',
          messages: _m,
        );
      }
    }
    if (s.issues.length != e) return null;
    return MemberDto(
      name: c0 as String,
      email: c1 is Undefined ? null : c1 as String?,
    );
  }

  @override
  Future<void> checkAsync(MemberDto o, DtoState s, List<Object> p) async {
    {
      String f = o.name;
      await s.asyncRule(
        const Unique('members', column: 'name', message: 'The name is taken'),
        f,
        p,
        'name',
        _m,
      );
    }
  }

  @override
  MemberDto fromMap(Map<String, dynamic> m) {
    return MemberDto(
      name: m['name'] as String,
      email: m['email'] == null ? null : (m['email'] as String),
    );
  }

  @override
  Map<String, dynamic> toMap(MemberDto o) {
    String f0 = o.name;
    String? f1 = o.email;
    return <String, dynamic>{'name': f0, 'email': f1};
  }

  @override
  Map<String, dynamic> toJsonSchema() {
    Map<String, dynamic> j = <String, dynamic>{
      'type': 'object',
      'title': 'MemberDto',
      'properties': <String, dynamic>{
        'name': <String, dynamic>{'type': 'string', 'minLength': 3},
        'email': <String, dynamic>{
          'type': <dynamic>['string', 'null'],
          'minLength': 5,
        },
      },
      'required': <dynamic>['name'],
    };
    JsonSchemaTools.merge(
      j,
      <String>['properties', 'name'],
      const Unique(
        'members',
        column: 'name',
        message: 'The name is taken',
      ).toJsonSchema(),
    );
    return j;
  }
}
