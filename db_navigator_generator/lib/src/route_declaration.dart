import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:db_navigator_generator/src/generation_errors.dart';
import 'package:db_navigator_generator/src/route_argument.dart';
import 'package:db_navigator_generator/src/route_argument_reader.dart';
import 'package:db_navigator_generator/src/route_descriptor.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker dbRouteChecker = TypeChecker.fromUrl(
  'package:db_navigator/src/typed/db_route.dart#DBRoute',
);

const TypeChecker _widgetChecker = TypeChecker.fromUrl(
  'package:flutter/src/widgets/framework.dart#Widget',
);

final RegExp _routeClassSuffix = RegExp(r'(Screen|View|Page)$');
final RegExp _explicitResultType = RegExp(r'^@(\w+\.)?DBRoute<');

class RouteDeclaration {
  final ClassElement widget;
  final String routeClass;
  final String path;
  final String feature;
  final bool isFeatureEntry;
  final String? resultType;
  final String? pageFactory;
  final List<RouteArgument> arguments;

  const RouteDeclaration({
    required this.widget,
    required this.routeClass,
    required this.path,
    required this.feature,
    required this.isFeatureEntry,
    required this.resultType,
    required this.pageFactory,
    required this.arguments,
  });

  Iterable<RouteArgument> get inMemoryArguments => arguments.where(
        (RouteArgument argument) => argument.codec == ArgumentCodec.inMemory,
      );

  bool get isRestorable => inMemoryArguments.isEmpty;

  RouteDescriptor toDescriptor(String library) {
    return RouteDescriptor(
      path: path,
      feature: feature,
      routeClass: routeClass,
      library: library,
      isFeatureEntry: isFeatureEntry,
      isRestorable: isRestorable,
    );
  }
}

String routeClassNameFor(String widgetName) {
  return '${widgetName.replaceFirst(_routeClassSuffix, '')}Route';
}

List<RouteDeclaration> readRouteDeclarations(
  LibraryReader library,
  String file,
) {
  final Map<String, RouteDeclaration> byRouteClass =
      <String, RouteDeclaration>{};

  for (final AnnotatedElement annotated
      in library.annotatedWith(dbRouteChecker)) {
    final RouteDeclaration declaration = _readDeclaration(annotated, file);
    final RouteDeclaration? clash = byRouteClass[declaration.routeClass];

    if (clash != null) {
      throw duplicateRouteClass(
        declaration.widget,
        clash.widget,
        file,
        declaration.routeClass,
      );
    }
    byRouteClass[declaration.routeClass] = declaration;
  }

  return byRouteClass.values.toList();
}

RouteDeclaration _readDeclaration(AnnotatedElement annotated, String file) {
  final Element element = annotated.element;

  if (element is! ClassElement || !_widgetChecker.isAssignableFrom(element)) {
    throw notAWidget(element, file);
  }

  final ConstantReader annotation = annotated.annotation;
  final String path = annotation.read('path').stringValue;
  final String feature = annotation.read('feature').stringValue;

  if (!path.startsWith('/')) {
    throw invalidPath(element, file, path);
  }
  if (feature.trim().isEmpty) {
    throw emptyFeature(element, file);
  }

  return RouteDeclaration(
    widget: element,
    routeClass: routeClassNameFor(element.name),
    path: path,
    feature: feature,
    isFeatureEntry: annotation.read('isFeatureEntry').boolValue,
    resultType: _resultType(element, annotation),
    pageFactory: _pageFactory(element, annotation, file),
    arguments: RouteArgumentReader(element, file).read(),
  );
}

String? _resultType(ClassElement widget, ConstantReader annotation) {
  final bool isExplicit = widget.metadata.any(
    (ElementAnnotation metadata) =>
        _explicitResultType.hasMatch(metadata.toSource()),
  );

  if (!isExplicit) {
    return null;
  }

  final InterfaceType type = annotation.objectValue.type! as InterfaceType;
  final DartType resultType = type.typeArguments.first;
  return resultType is VoidType ? null : resultType.getDisplayString();
}

String? _pageFactory(
  ClassElement widget,
  ConstantReader annotation,
  String file,
) {
  final DartObject? value = annotation.peek('pageFactory')?.objectValue;

  if (value == null) {
    return null;
  }

  final ExecutableElement? function = value.toFunctionValue();

  if (function is FunctionElement && function.isStatic) {
    return function.name;
  }
  if (function is MethodElement && function.isStatic) {
    return '${function.enclosingElement3.name}.${function.name}';
  }
  throw invalidPageFactory(widget, file);
}
