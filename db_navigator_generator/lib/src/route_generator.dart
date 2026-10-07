import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:db_navigator_generator/src/argument_codec_writer.dart';
import 'package:db_navigator_generator/src/route_argument.dart';
import 'package:db_navigator_generator/src/route_declaration.dart';
import 'package:source_gen/source_gen.dart';

class RouteGenerator extends Generator {
  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final List<RouteDeclaration> declarations =
        readRouteDeclarations(library, buildStep.inputId.path);

    if (declarations.isEmpty) {
      return null;
    }

    final DartEmitter emitter = DartEmitter(useNullSafetySyntax: true);
    return declarations
        .map((RouteDeclaration route) => _routeSource(route, emitter))
        .join('\n\n');
  }

  String _routeSource(RouteDeclaration route, DartEmitter emitter) {
    final String source = _routeClass(route).accept(emitter).toString();

    if (route.isRestorable) {
      return source;
    }

    final String inMemory = route.inMemoryArguments
        .map((RouteArgument argument) =>
            '${argument.name}: ${argument.typeName}')
        .join(', ');
    return '// In-memory only ($inMemory): not restored, not deep-linkable.\n'
        '$source';
  }

  Class _routeClass(RouteDeclaration route) {
    final String resultType = route.resultType ?? 'void';

    return Class(
      (ClassBuilder builder) => builder
        ..name = route.routeClass
        ..extend = refer('DBTypedRoute<$resultType>')
        ..constructors.add(_constructor(route))
        ..fields.addAll(<Field>[
          _staticConst('String', 'path', literalString(route.path).code),
          _staticConst('DBRouteDefinition', 'definition', _definition(route)),
          ...route.arguments.map(_argumentField),
        ])
        ..methods.addAll(<Method>[
          _getter('String', 'location', 'path'),
          _getter('bool', 'isRestorable', '${route.isRestorable}'),
          _close(route.resultType),
          _fromJson(route),
          if (route.arguments.every(_isOptional)) _defaultRoute(route),
          _toJson(route),
          _buildWidget(route),
        ]),
    );
  }

  Constructor _constructor(RouteDeclaration route) {
    return Constructor(
      (ConstructorBuilder builder) => builder
        ..constant = true
        ..requiredParameters.addAll(
          route.arguments
              .where((RouteArgument a) => !a.kind.isOptional && !a.kind.isNamed)
              .map(_parameter),
        )
        ..optionalParameters.addAll(
          route.arguments
              .where((RouteArgument a) => a.kind.isOptional || a.kind.isNamed)
              .map(_parameter),
        ),
    );
  }

  Parameter _parameter(RouteArgument argument) {
    final String? defaultValue = argument.defaultValueCode;

    return Parameter(
      (ParameterBuilder builder) => builder
        ..name = argument.name
        ..toThis = true
        ..named = argument.kind.isNamed
        ..required = argument.kind == ArgumentKind.requiredNamed
        ..defaultTo = defaultValue == null ? null : Code(defaultValue),
    );
  }

  Field _staticConst(String type, String name, Code value) {
    return Field(
      (FieldBuilder builder) => builder
        ..static = true
        ..modifier = FieldModifier.constant
        ..type = refer(type)
        ..name = name
        ..assignment = value,
    );
  }

  Code _definition(RouteDeclaration route) {
    final String? pageFactory = route.pageFactory;
    final bool hasDefault = route.arguments.every(_isOptional);

    return Code(
      'DBRouteDefinition('
      'path: path, '
      'decode: ${route.routeClass}.fromJson, '
      '${hasDefault ? 'defaultRoute: ${route.routeClass}._defaultRoute, ' : ''}'
      '${pageFactory == null ? '' : 'pageFactory: $pageFactory, '}'
      ')',
    );
  }

  Field _argumentField(RouteArgument argument) {
    return Field(
      (FieldBuilder builder) => builder
        ..modifier = FieldModifier.final$
        ..type = refer(argument.typeName)
        ..name = argument.name,
    );
  }

  Method _getter(String type, String name, String body) {
    return Method(
      (MethodBuilder builder) => builder
        ..annotations.add(refer('override'))
        ..returns = refer(type)
        ..type = MethodType.getter
        ..name = name
        ..lambda = true
        ..body = Code(body),
    );
  }

  Method _close(String? resultType) {
    return Method(
      (MethodBuilder builder) => builder
        ..static = true
        ..returns = refer('void')
        ..name = 'close'
        ..requiredParameters.add(_typedParameter('BuildContext', 'context'))
        ..optionalParameters.addAll(<Parameter>[
          if (resultType != null)
            _typedParameter(_nullable(resultType), 'result'),
        ])
        ..lambda = true
        ..body = Code(
          resultType == null
              ? 'DBRouterDelegate.of(context).close<Object?>()'
              : 'DBRouterDelegate.of(context)'
                  '.close<${_nullable(resultType)}>(result)',
        ),
    );
  }

  Method _fromJson(RouteDeclaration route) {
    final String body = route.isRestorable
        ? '${route.routeClass}(${_invocationArguments(
            route.arguments,
            (RouteArgument a) => decodeArgument(a.type, "json['${a.name}']"),
          )})'
        : "throw UnsupportedError('${route.routeClass} is in-memory only')";

    return Method(
      (MethodBuilder builder) => builder
        ..static = true
        ..returns = refer(route.routeClass)
        ..name = 'fromJson'
        ..requiredParameters.add(
          _typedParameter('Map<String, Object?>', 'json'),
        )
        ..lambda = true
        ..body = Code(body),
    );
  }

  Method _defaultRoute(RouteDeclaration route) {
    return Method(
      (MethodBuilder builder) => builder
        ..static = true
        ..returns = refer(route.routeClass)
        ..name = '_defaultRoute'
        ..lambda = true
        ..body = Code('${route.routeClass}()'),
    );
  }

  Method _toJson(RouteDeclaration route) {
    final String body = route.isRestorable
        ? '<String, Object?>{${route.arguments.map(
              (RouteArgument a) =>
                  "'${a.name}': ${encodeArgument(a.type, a.name)}",
            ).join(', ')}}'
        : 'null';

    return Method(
      (MethodBuilder builder) => builder
        ..annotations.add(refer('override'))
        ..returns = refer('Map<String, Object?>?')
        ..name = 'toJson'
        ..lambda = true
        ..body = Code(body),
    );
  }

  Method _buildWidget(RouteDeclaration route) {
    return Method(
      (MethodBuilder builder) => builder
        ..annotations.add(refer('override'))
        ..returns = refer('Widget')
        ..name = 'buildWidget'
        ..lambda = true
        ..body = Code(
          '${route.widget.name}(${_invocationArguments(
            route.arguments,
            (RouteArgument a) => a.name,
          )})',
        ),
    );
  }

  String _invocationArguments(
    List<RouteArgument> arguments,
    String Function(RouteArgument argument) valueOf,
  ) {
    return arguments
        .map(
          (RouteArgument a) =>
              a.kind.isNamed ? '${a.name}: ${valueOf(a)}' : valueOf(a),
        )
        .join(', ');
  }

  Parameter _typedParameter(String type, String name) {
    return Parameter(
      (ParameterBuilder builder) => builder
        ..type = refer(type)
        ..name = name,
    );
  }

  bool _isOptional(RouteArgument argument) => argument.kind.isOptional;

  String _nullable(String type) {
    return type.endsWith('?') || type == 'dynamic' ? type : '$type?';
  }
}
