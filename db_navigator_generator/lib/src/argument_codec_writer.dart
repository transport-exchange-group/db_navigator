import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:db_navigator_generator/src/route_argument.dart';
import 'package:db_navigator_generator/src/route_argument_reader.dart';

String encodeArgument(DartType type, String value) {
  final InterfaceType interface = type as InterfaceType;
  final String q = _isNullable(type) ? '?' : '';

  if (_isPassThrough(type)) {
    return value;
  }
  if (interface.element is EnumElement) {
    return '$value$q.name';
  }
  if (isDateTime(type)) {
    return '$value$q.toIso8601String()';
  }
  if (interface.isDartCoreList) {
    final DartType element = interface.typeArguments.first;
    return '$value$q.map((${_name(element)} e) => '
        '${encodeArgument(element, 'e')}).toList()';
  }
  if (interface.isDartCoreMap) {
    final DartType element = interface.typeArguments.last;
    return '$value$q.map((String k, ${_name(element)} v) => '
        'MapEntry<String, Object?>(k, ${encodeArgument(element, 'v')}))';
  }
  return '$value$q.toJson()';
}

String decodeArgument(DartType type, String json) {
  final InterfaceType interface = type as InterfaceType;
  final bool nullable = _isNullable(type);
  final String q = nullable ? '?' : '';

  if (type.isDartCoreInt) {
    return '($json as num$q)$q.toInt()';
  }
  if (type.isDartCoreDouble) {
    return '($json as num$q)$q.toDouble()';
  }
  if (isPrimitive(type)) {
    return '$json as ${_name(type)}';
  }
  if (interface.isDartCoreList) {
    final DartType element = interface.typeArguments.first;
    final String mapper = "(Object? e) => ${decodeArgument(element, 'e')}";
    return '($json as List<Object?>$q)$q'
        '.map<${_name(element)}>($mapper).toList()';
  }
  if (interface.isDartCoreMap) {
    final DartType element = interface.typeArguments.last;
    final String elementName = _name(element);
    final String entry =
        "MapEntry<String, $elementName>(k, ${decodeArgument(element, 'v')})";
    return '($json as Map<String, Object?>$q)$q'
        '.map<String, $elementName>((String k, Object? v) => $entry)';
  }

  final String decoded = _decodeNonNullObject(interface, json);
  return nullable ? '($json == null ? null : $decoded)' : decoded;
}

String _decodeNonNullObject(InterfaceType type, String json) {
  final String className = type.element.name;

  if (type.element is EnumElement) {
    return '$className.values.byName($json as String)';
  }
  if (isDateTime(type)) {
    return 'DateTime.parse($json as String)';
  }
  return '$className.fromJson($json as ${fromJsonParameterType(type)})';
}

bool _isPassThrough(DartType type) {
  if (isPrimitive(type)) {
    return true;
  }
  if (type is InterfaceType && (type.isDartCoreList || type.isDartCoreMap)) {
    return _isPassThrough(type.typeArguments.last);
  }
  return false;
}

bool _isNullable(DartType type) {
  return type.nullabilitySuffix == NullabilitySuffix.question;
}

String _name(DartType type) => typeNameOf(type);
