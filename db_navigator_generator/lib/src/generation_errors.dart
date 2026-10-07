import 'package:analyzer/dart/element/element.dart';
import 'package:db_navigator_generator/src/route_descriptor.dart';
import 'package:source_gen/source_gen.dart';

InvalidGenerationSourceError notAWidget(Element element, String file) {
  return InvalidGenerationSourceError(
    '@DBRoute in $file is on ${element.displayName}, which is not a widget '
    'class. Annotate a StatelessWidget or StatefulWidget.',
    element: element,
  );
}

InvalidGenerationSourceError noUnnamedConstructor(
  ClassElement widget,
  String file,
) {
  return InvalidGenerationSourceError(
    '${widget.name} in $file has no unnamed constructor. @DBRoute reads the '
    "route's arguments from the unnamed constructor.",
    element: widget,
  );
}

InvalidGenerationSourceError invalidPath(
  ClassElement widget,
  String file,
  String path,
) {
  return InvalidGenerationSourceError(
    "@DBRoute path '$path' on ${widget.name} in $file must start with '/'.",
    element: widget,
  );
}

InvalidGenerationSourceError emptyFeature(ClassElement widget, String file) {
  return InvalidGenerationSourceError(
    '@DBRoute feature on ${widget.name} in $file must not be empty.',
    element: widget,
  );
}

InvalidGenerationSourceError nonStringMapKey(
  ClassElement widget,
  String file,
  ParameterElement parameter,
) {
  return InvalidGenerationSourceError(
    'Argument ${parameter.name} of ${widget.name} in $file is a Map with '
    'non-String keys (${parameter.type.getDisplayString()}). Route arguments '
    'must use Map<String, _>.',
    element: parameter,
  );
}

InvalidGenerationSourceError toJsonFromJsonMismatch(
  ClassElement widget,
  String file,
  ParameterElement parameter,
  String typeName, {
  required bool hasToJson,
}) {
  final String missing = hasToJson ? 'fromJson factory' : 'toJson() method';
  return InvalidGenerationSourceError(
    'Argument ${parameter.name} of ${widget.name} in $file has type '
    '$typeName, which has ${hasToJson ? 'toJson()' : 'fromJson'} but no '
    '$missing. Add the missing member, or remove both to keep the route '
    'in-memory only.',
    element: parameter,
  );
}

InvalidGenerationSourceError reservedArgumentName(
  ClassElement widget,
  String file,
  ParameterElement parameter,
) {
  return InvalidGenerationSourceError(
    'Argument ${parameter.name} of ${widget.name} in $file clashes with a '
    'generated route member. Rename the constructor parameter.',
    element: parameter,
  );
}

InvalidGenerationSourceError duplicateRouteClass(
  ClassElement widget,
  ClassElement other,
  String file,
  String routeClass,
) {
  return InvalidGenerationSourceError(
    '${widget.name} and ${other.name} in $file both generate $routeClass. '
    'Rename one of the widgets.',
    element: widget,
  );
}

InvalidGenerationSourceError invalidPageFactory(
  ClassElement widget,
  String file,
) {
  return InvalidGenerationSourceError(
    '@DBRoute pageFactory on ${widget.name} in $file must be a top-level or '
    'static function.',
    element: widget,
  );
}

InvalidGenerationSourceError duplicatePath(
  RouteDescriptor first,
  RouteDescriptor second,
) {
  return InvalidGenerationSourceError(
    "Path '${first.path}' is declared twice: ${first.routeClass} in "
    '${first.library} and ${second.routeClass} in ${second.library}.',
  );
}

InvalidGenerationSourceError featureEntryCount(
  String feature,
  List<RouteDescriptor> routes,
) {
  final Iterable<String> names = routes.map(
    (RouteDescriptor route) => '${route.routeClass} (${route.library})'
        '${route.isFeatureEntry ? ' [entry]' : ''}',
  );
  return InvalidGenerationSourceError(
    "Feature '$feature' must have exactly one route with "
    'isFeatureEntry: true. Routes: ${names.join(', ')}.',
  );
}
