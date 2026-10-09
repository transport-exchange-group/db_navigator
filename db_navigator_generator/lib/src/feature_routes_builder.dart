import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:db_navigator_generator/src/generation_errors.dart';
import 'package:db_navigator_generator/src/route_descriptor.dart';
import 'package:db_navigator_generator/src/route_descriptor_builder.dart';
import 'package:glob/glob.dart';

const String featureRoutesFile = 'lib/db_routes.g.dart';

final Glob _descriptors = Glob('lib/**$routeDescriptorExtension');
final RegExp _wordSeparator = RegExp('[^A-Za-z0-9]+');

class FeatureRoutesBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => <String, List<String>>{
        r'lib/$lib$': <String>[featureRoutesFile],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final List<RouteDescriptor> routes = <RouteDescriptor>[];

    final List<AssetId> assets =
        await buildStep.findAssets(_descriptors).toList()
          ..sort((AssetId a, AssetId b) => a.path.compareTo(b.path));

    for (final AssetId asset in assets) {
      routes
          .addAll(decodeRouteDescriptors(await buildStep.readAsString(asset)));
    }

    if (routes.isEmpty) {
      return;
    }

    _checkUniquePaths(routes);

    final Map<String, List<RouteDescriptor>> features =
        groupBy(routes, (RouteDescriptor route) => route.feature);

    final String source = featureRoutesSource(features);

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, featureRoutesFile),
      DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
          .format(source),
    );
  }
}

String featureRoutesSource(Map<String, List<RouteDescriptor>> features) {
  final Set<String> libraries = <String>{
    'package:db_navigator/db_navigator.dart',
    for (final List<RouteDescriptor> routes in features.values)
      ...routes.map((RouteDescriptor route) => route.library),
  };

  final List<String> sortedLibraries = libraries.toList()..sort();
  final List<String> sortedFeatures = features.keys.toList()..sort();

  return <String>[
    '// GENERATED CODE - DO NOT MODIFY BY HAND',
    '',
    ...sortedLibraries.map((String library) => "import '$library';"),
    '',
    for (final String feature in sortedFeatures)
      _featureClass(feature, features[feature]!),
  ].join('\n');
}

String _featureClass(String feature, List<RouteDescriptor> routes) {
  final RouteDescriptor entry = _entryOf(feature, routes);
  final String definitions = routes
      .map((RouteDescriptor route) => '${route.routeClass}.definition')
      .join(', ');

  return '''
class ${featureClassName(feature)} extends DBFeatureRoutes {
  const ${featureClassName(feature)}({super.onEntered, super.onExited});

  @override
  String get scopeName => '$feature';

  @override
  Destination get initialDestination =>
      const Destination(path: ${entry.routeClass}.path);

  @override
  List<DBRouteDefinition> get definitions =>
      const <DBRouteDefinition>[$definitions];
}
''';
}

String featureClassName(String feature) {
  final String pascalCase = feature
      .split(_wordSeparator)
      .where((String word) => word.isNotEmpty)
      .map((String word) => word[0].toUpperCase() + word.substring(1))
      .join();
  return '${pascalCase}Routes';
}

RouteDescriptor _entryOf(String feature, List<RouteDescriptor> routes) {
  if (routes.length == 1) {
    return routes.single;
  }

  final List<RouteDescriptor> entries =
      routes.where((RouteDescriptor route) => route.isFeatureEntry).toList();

  if (entries.length != 1) {
    throw featureEntryCount(feature, routes);
  }
  return entries.single;
}

void _checkUniquePaths(List<RouteDescriptor> routes) {
  final Map<String, RouteDescriptor> byPath = <String, RouteDescriptor>{};

  for (final RouteDescriptor route in routes) {
    final RouteDescriptor? existing = byPath[route.path];

    if (existing != null) {
      throw duplicatePath(existing, route);
    }
    byPath[route.path] = route;
  }
}
