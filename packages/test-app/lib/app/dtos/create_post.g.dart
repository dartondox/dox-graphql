// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post.dart';

// **************************************************************************
// DoxDtoGenerator
// **************************************************************************

// ignore_for_file: type=lint

/// The checks, the converter and the JSON Schema of [CreatePostDto].
const DtoSchema<CreatePostDto> $CreatePostDtoDto = _$CreatePostDtoDto();

class _$CreatePostDtoDto extends DtoSchema<CreatePostDto> {
  const _$CreatePostDtoDto();

  static const Map<String, String> _m = <String, String>{};

  @override
  Type get type => CreatePostDto;

  @override
  String get name => 'CreatePostDto';

  @override
  bool get usesRequiredWhen => false;

  @override
  CreatePostDto? convert(Object? input, DtoState s, List<Object> p) {
    if (input is! Map) {
      s.notObject(input, p, _m);
      return null;
    }
    int e = s.issues.length;
    // title: String
    Object? c0;
    c0 = s.string(s.read(input, 'title'), p, 'title', _m);
    if (c0 == null || c0 is Undefined) s.required(p, 'title', _m);
    // body: String?
    Object? c1;
    c1 = s.string(s.read(input, 'body'), p, 'body', _m);
    // status: PostStatus?
    Object? c2;
    c2 = s.enumName(s.read(input, 'status'), p, 'status', _m, const <String>[
      'draft',
      'published',
    ]);
    if (c2 is String) {
      c2 = switch (c2) {
        'draft' => PostStatus.draft,
        _ => PostStatus.published,
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
    return CreatePostDto(
      title: c0 as String,
      body: c1 is Undefined ? null : c1 as String?,
      status: c2 is Undefined ? null : c2 as PostStatus?,
    );
  }

  @override
  CreatePostDto fromMap(Map<String, dynamic> m) {
    return CreatePostDto(
      title: m['title'] as String,
      body: m['body'] == null ? null : (m['body'] as String),
      status: m['status'] == null
          ? null
          : (PostStatus.values.byName(m['status'] as String)),
    );
  }

  @override
  Map<String, dynamic> toMap(CreatePostDto o) {
    String f0 = o.title;
    String? f1 = o.body;
    PostStatus? f2 = o.status;
    return <String, dynamic>{
      'title': f0,
      'body': f1,
      'status': f2 == null ? null : f2.name,
    };
  }

  @override
  Map<String, dynamic> toJsonSchema() {
    return <String, dynamic>{
      'type': 'object',
      'title': 'CreatePostDto',
      'properties': <String, dynamic>{
        'title': <String, dynamic>{'type': 'string', 'minLength': 3},
        'body': <String, dynamic>{
          'type': <dynamic>['string', 'null'],
        },
        'status': <String, dynamic>{
          'type': <dynamic>['string', 'null'],
          'enum': <dynamic>['draft', 'published'],
        },
      },
      'required': <dynamic>['title'],
    };
  }
}
