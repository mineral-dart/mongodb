import 'dart:core';

class SchemaException implements Exception {
  final String cause;

  SchemaException(this.cause);

  @override
  String toString () => cause;
}
