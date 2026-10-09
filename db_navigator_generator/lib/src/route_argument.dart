import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

enum ArgumentCodec {
  primitive,
  enumeration,
  dateTime,
  list,
  map,
  json,
  inMemory
}

enum ArgumentKind {
  requiredPositional,
  optionalPositional,
  requiredNamed,
  optionalNamed;

  bool get isNamed => this == requiredNamed || this == optionalNamed;

  bool get isOptional => this == optionalPositional || this == optionalNamed;
}

class RouteArgument {
  final String name;
  final DartType type;
  final ArgumentKind kind;
  final String? defaultValueCode;
  final ArgumentCodec codec;

  const RouteArgument({
    required this.name,
    required this.type,
    required this.kind,
    required this.defaultValueCode,
    required this.codec,
  });

  String get typeName => typeNameOf(type);
}

String typeNameOf(DartType type) {
  final InstantiatedTypeAliasElement? alias = type.alias;

  if (alias == null) {
    return type.getDisplayString();
  }

  final String arguments = alias.typeArguments.isEmpty
      ? ''
      : '<${alias.typeArguments.map(typeNameOf).join(', ')}>';
  final String suffix =
      type.nullabilitySuffix == NullabilitySuffix.question ? '?' : '';
  return '${alias.element.name}$arguments$suffix';
}
