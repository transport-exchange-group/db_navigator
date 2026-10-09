import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:db_navigator_generator/src/route_declaration.dart';
import 'package:db_navigator_generator/src/route_descriptor.dart';
import 'package:source_gen/source_gen.dart';

const String routeDescriptorExtension = '.db_route.json';

class RouteDescriptorBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => <String, List<String>>{
        '.dart': <String>[routeDescriptorExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final LibraryElement? library = await readAnnotatedLibrary(buildStep);

    if (library == null) {
      return;
    }

    final List<RouteDeclaration> declarations = readRouteDeclarations(
      LibraryReader(library),
      buildStep.inputId.path,
    );

    if (declarations.isEmpty) {
      return;
    }

    final String libraryUri = buildStep.inputId.uri.toString();
    final List<Map<String, Object?>> descriptors = <Map<String, Object?>>[
      for (final RouteDeclaration declaration in declarations)
        declaration.toDescriptor(libraryUri).toJson(),
    ];

    await buildStep.writeAsString(
      buildStep.inputId.changeExtension(routeDescriptorExtension),
      jsonEncode(descriptors),
    );
  }
}

Future<LibraryElement?> readAnnotatedLibrary(BuildStep buildStep) async {
  final String source = await buildStep.readAsString(buildStep.inputId);

  if (!source.contains('DBRoute') ||
      !await buildStep.resolver.isLibrary(buildStep.inputId)) {
    return null;
  }

  return buildStep.resolver.libraryFor(buildStep.inputId);
}

List<RouteDescriptor> decodeRouteDescriptors(String json) {
  return <RouteDescriptor>[
    for (final Object? entry in jsonDecode(json) as List<Object?>)
      RouteDescriptor.fromJson(entry! as Map<String, Object?>),
  ];
}
