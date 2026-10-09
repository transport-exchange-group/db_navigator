import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:db_navigator_generator/src/generation_errors.dart';
import 'package:db_navigator_generator/src/route_argument.dart';

const Set<String> _reservedNames = <String>{
  'buildWidget',
  'close',
  'definition',
  'destination',
  'fromJson',
  'isRestorable',
  'location',
  'path',
  'push',
  'toJson',
};

class RouteArgumentReader {
  final ClassElement widget;
  final String file;

  const RouteArgumentReader(this.widget, this.file);

  List<RouteArgument> read() {
    final ConstructorElement? constructor = widget.unnamedConstructor;

    if (constructor == null) {
      throw noUnnamedConstructor(widget, file);
    }

    return <RouteArgument>[
      for (final ParameterElement parameter in constructor.parameters)
        if (parameter.name != 'key') _readArgument(parameter),
    ];
  }

  RouteArgument _readArgument(ParameterElement parameter) {
    if (_reservedNames.contains(parameter.name)) {
      throw reservedArgumentName(widget, file, parameter);
    }

    return RouteArgument(
      name: parameter.name,
      type: parameter.type,
      kind: _kindOf(parameter),
      defaultValueCode: parameter.defaultValueCode,
      codec: _codecOf(parameter.type, parameter),
    );
  }

  ArgumentKind _kindOf(ParameterElement parameter) {
    if (parameter.isRequiredPositional) {
      return ArgumentKind.requiredPositional;
    }
    if (parameter.isOptionalPositional) {
      return ArgumentKind.optionalPositional;
    }
    return parameter.isRequiredNamed
        ? ArgumentKind.requiredNamed
        : ArgumentKind.optionalNamed;
  }

  ArgumentCodec _codecOf(DartType type, ParameterElement parameter) {
    if (type is! InterfaceType) {
      return ArgumentCodec.inMemory;
    }

    if (isPrimitive(type)) {
      return ArgumentCodec.primitive;
    }
    if (type.element is EnumElement) {
      return ArgumentCodec.enumeration;
    }
    if (isDateTime(type)) {
      return ArgumentCodec.dateTime;
    }
    if (type.isDartCoreList) {
      return _allSerialisable(type.typeArguments, parameter)
          ? ArgumentCodec.list
          : ArgumentCodec.inMemory;
    }
    if (type.isDartCoreMap) {
      if (!type.typeArguments.first.isDartCoreString ||
          type.typeArguments.first.nullabilitySuffix ==
              NullabilitySuffix.question) {
        throw nonStringMapKey(widget, file, parameter);
      }
      return _allSerialisable(type.typeArguments.skip(1), parameter)
          ? ArgumentCodec.map
          : ArgumentCodec.inMemory;
    }
    return _jsonCodecOf(type, parameter);
  }

  bool _allSerialisable(Iterable<DartType> types, ParameterElement parameter) {
    return types.every(
      (DartType type) => _codecOf(type, parameter) != ArgumentCodec.inMemory,
    );
  }

  ArgumentCodec _jsonCodecOf(InterfaceType type, ParameterElement parameter) {
    final bool hasToJson = hasToJsonMethod(type);
    final bool hasFromJson = fromJsonParameterType(type) != null;

    if (hasToJson && hasFromJson) {
      return ArgumentCodec.json;
    }
    if (hasToJson || hasFromJson) {
      throw toJsonFromJsonMismatch(
        widget,
        file,
        parameter,
        type.getDisplayString(),
        hasToJson: hasToJson,
      );
    }
    return ArgumentCodec.inMemory;
  }
}

bool isPrimitive(DartType type) {
  return type.isDartCoreString ||
      type.isDartCoreInt ||
      type.isDartCoreDouble ||
      type.isDartCoreNum ||
      type.isDartCoreBool;
}

bool isDateTime(DartType type) {
  final Element? element = type.element;
  return element != null &&
      element.name == 'DateTime' &&
      (element.library?.isDartCore ?? false);
}

bool hasToJsonMethod(InterfaceType type) {
  return <InterfaceType>[type, ...type.allSupertypes]
      .where((InterfaceType candidate) => !candidate.isDartCoreObject)
      .any((InterfaceType candidate) {
    final MethodElement? method = candidate.getMethod('toJson');
    return method != null && !method.isStatic;
  });
}

String? fromJsonParameterType(InterfaceType type) {
  final InterfaceElement element = type.element;
  final ExecutableElement? fromJson =
      element.getNamedConstructor('fromJson') ?? _staticFromJson(element);

  if (fromJson == null || fromJson.parameters.isEmpty) {
    return null;
  }
  return fromJson.parameters.first.type.getDisplayString();
}

MethodElement? _staticFromJson(InterfaceElement element) {
  final MethodElement? method = element.getMethod('fromJson');
  return method != null && method.isStatic ? method : null;
}
