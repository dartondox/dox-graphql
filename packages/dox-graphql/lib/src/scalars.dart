import 'package:gql/ast.dart';
import 'package:gql/language.dart';

import 'errors.dart';
import 'types.dart';

const int _maxInt = 2147483647;
const int _minInt = -2147483648;

/// The built-in `Int` scalar: a signed 32-bit integer.
final ScalarType<int> graphqlInt = _IntType();

/// The built-in `Float` scalar: a double.
final ScalarType<double> graphqlFloat = _FloatType();

/// The built-in `String` scalar.
final ScalarType<String> graphqlString = _StringType();

/// The built-in `Boolean` scalar.
final ScalarType<bool> graphqlBoolean = _BooleanType();

/// The built-in `ID` scalar. Resolvers can return a `String` or an `int`;
/// arguments always come as a `String`.
final ScalarType<String> graphqlId = _IdType();

/// All built-in scalars.
final List<ScalarType<Object>> builtInScalars = <ScalarType<Object>>[
  graphqlInt,
  graphqlFloat,
  graphqlString,
  graphqlBoolean,
  graphqlId,
];

bool _isInt32(int v) => v >= _minInt && v <= _maxInt;

final class _IntType extends ScalarType<int> {
  _IntType()
    : super(
        'Int',
        description:
            'The `Int` scalar type represents non-fractional signed whole '
            'numeric values. Int can represent values between -(2^31) and '
            '2^31 - 1.',
      );

  @override
  Object serialize(Object value) {
    int? n = switch (value) {
      int() => value,
      double() when value.isFinite && value == value.truncateToDouble() =>
        value.toInt(),
      bool() => value ? 1 : 0,
      _ => null,
    };
    if (n == null) {
      throw GraphQLError('Int cannot represent non-integer value: $value');
    }
    if (!_isInt32(n)) {
      throw GraphQLError(
        'Int cannot represent non 32-bit signed integer value: $value',
      );
    }
    return n;
  }

  @override
  int parseValue(Object value) {
    int? n = switch (value) {
      int() => value,
      double() when value.isFinite && value == value.truncateToDouble() =>
        value.toInt(),
      _ => null,
    };
    if (n == null) {
      throw GraphQLError('Int cannot represent non-integer value: $value');
    }
    if (!_isInt32(n)) {
      throw GraphQLError(
        'Int cannot represent non 32-bit signed integer value: $value',
      );
    }
    return n;
  }

  @override
  int parseLiteral(ValueNode node) {
    if (node is! IntValueNode) {
      throw GraphQLError(
        'Int cannot represent non-integer value: ${printNode(node)}',
      );
    }
    int? n = int.tryParse(node.value);
    if (n == null || !_isInt32(n)) {
      throw GraphQLError(
        'Int cannot represent non 32-bit signed integer value: ${node.value}',
      );
    }
    return n;
  }
}

final class _FloatType extends ScalarType<double> {
  _FloatType()
    : super(
        'Float',
        description:
            'The `Float` scalar type represents signed double-precision '
            'fractional values as specified by IEEE 754.',
      );

  @override
  Object serialize(Object value) {
    double? n = switch (value) {
      num() when value.isFinite => value.toDouble(),
      bool() => value ? 1.0 : 0.0,
      _ => null,
    };
    if (n == null) {
      throw GraphQLError('Float cannot represent non numeric value: $value');
    }
    return n;
  }

  @override
  double parseValue(Object value) {
    if (value is num && value.isFinite) return value.toDouble();
    throw GraphQLError('Float cannot represent non numeric value: $value');
  }

  @override
  double parseLiteral(ValueNode node) {
    if (node is IntValueNode) return double.parse(node.value);
    if (node is FloatValueNode) return double.parse(node.value);
    throw GraphQLError(
      'Float cannot represent non numeric value: ${printNode(node)}',
    );
  }
}

final class _StringType extends ScalarType<String> {
  _StringType()
    : super(
        'String',
        description:
            'The `String` scalar type represents textual data, represented '
            'as UTF-8 character sequences.',
      );

  @override
  Object serialize(Object value) {
    return switch (value) {
      String() => value,
      num() || bool() => value.toString(),
      _ => throw GraphQLError(
        'String cannot represent value: ${value.runtimeType}',
      ),
    };
  }

  @override
  String parseValue(Object value) {
    if (value is String) return value;
    throw GraphQLError('String cannot represent a non string value: $value');
  }

  @override
  String parseLiteral(ValueNode node) {
    if (node is StringValueNode) return node.value;
    throw GraphQLError(
      'String cannot represent a non string value: ${printNode(node)}',
    );
  }
}

final class _BooleanType extends ScalarType<bool> {
  _BooleanType()
    : super(
        'Boolean',
        description: 'The `Boolean` scalar type represents `true` or `false`.',
      );

  @override
  Object serialize(Object value) {
    return switch (value) {
      bool() => value,
      num() when value.isFinite => value != 0,
      _ => throw GraphQLError(
        'Boolean cannot represent a non boolean value: $value',
      ),
    };
  }

  @override
  bool parseValue(Object value) {
    if (value is bool) return value;
    throw GraphQLError('Boolean cannot represent a non boolean value: $value');
  }

  @override
  bool parseLiteral(ValueNode node) {
    if (node is BooleanValueNode) return node.value;
    throw GraphQLError(
      'Boolean cannot represent a non boolean value: ${printNode(node)}',
    );
  }
}

final class _IdType extends ScalarType<String> {
  _IdType()
    : super(
        'ID',
        description:
            'The `ID` scalar type represents a unique identifier. It is '
            'serialized as a String; a String or an Int is accepted as input.',
      );

  @override
  Object serialize(Object value) {
    return switch (value) {
      String() => value,
      int() => value.toString(),
      _ => throw GraphQLError('ID cannot represent value: $value'),
    };
  }

  @override
  String parseValue(Object value) {
    return switch (value) {
      String() => value,
      int() => value.toString(),
      _ => throw GraphQLError('ID cannot represent value: $value'),
    };
  }

  @override
  String parseLiteral(ValueNode node) {
    return switch (node) {
      StringValueNode() => node.value,
      IntValueNode() => node.value,
      _ => throw GraphQLError(
        'ID cannot represent a non-string and non-integer value: '
        '${printNode(node)}',
      ),
    };
  }
}

/// The `DateTime` scalar: a date and time as ISO 8601 text, like
/// `2026-11-20T10:00:00.000Z`. Resolvers return and get a `DateTime`.
/// It is not a built-in scalar, so a schema has it only when a field or
/// argument uses it.
final ScalarType<DateTime> graphqlDateTime = _DateTimeType();

final class _DateTimeType extends ScalarType<DateTime> {
  _DateTimeType()
    : super(
        'DateTime',
        description: 'A date and time as ISO 8601 text.',
        specifiedByUrl: 'https://scalars.graphql.org/andimarek/date-time',
      );

  @override
  Object serialize(Object value) {
    if (value is DateTime) return value.toIso8601String();
    if (value is String && DateTime.tryParse(value) != null) return value;
    throw GraphQLError('DateTime cannot represent value: $value');
  }

  @override
  DateTime parseValue(Object value) {
    DateTime? date = value is String ? DateTime.tryParse(value) : null;
    if (date == null) {
      throw GraphQLError('DateTime cannot represent value: $value');
    }
    return date;
  }

  @override
  DateTime parseLiteral(ValueNode node) {
    if (node is StringValueNode) return parseValue(node.value);
    throw GraphQLError(
      'DateTime cannot represent a non string value: ${printNode(node)}',
    );
  }
}
