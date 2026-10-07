import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:db_navigator_generator/builder.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

const String fixturePackage = 'fixture_app';

final String fixturesDirectory = p.join('test', 'fixtures');

Map<String, String> stubAssets() {
  final Directory stubs = Directory(p.join(fixturesDirectory, 'stubs'));
  final Map<String, String> assets = <String, String>{};

  for (final FileSystemEntity entity in stubs.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final List<String> segments =
          p.split(p.relative(entity.path, from: stubs.path));
      final String path = p.posix.joinAll(segments.skip(1));
      assets['${segments.first}|$path'] = entity.readAsStringSync();
    }
  }
  return assets;
}

String readFixture(String name) {
  return File(p.join(fixturesDirectory, name)).readAsStringSync();
}

String fixtureAsset(String path) => '$fixturePackage|$path';

Future<TestBuilderResult> runRouteBuilder(
  Map<String, String> libraries, {
  Map<String, Object>? outputs,
  void Function(LogRecord log)? onLog,
}) {
  return testBuilder(
    dbRouteBuilder(BuilderOptions.empty),
    <String, String>{...stubAssets(), ...libraries},
    generateFor: libraries.keys.toSet(),
    rootPackage: fixturePackage,
    outputs: outputs,
    onLog: onLog,
  );
}

Future<String> generationError(String path, String source) async {
  final List<String> errors = <String>[];
  await runRouteBuilder(
    <String, String>{fixtureAsset(path): source},
    onLog: (LogRecord log) {
      if (log.level >= Level.SEVERE) {
        errors.add('${log.message} ${log.error ?? ''}');
      }
    },
  );
  return errors.join('\n');
}

Future<String> generatedPart(String path, String source) async {
  final String asset = fixtureAsset(path);
  final TestBuilderResult result = await runRouteBuilder(
    <String, String>{asset: source},
  );
  return readOutput(result, p.posix.setExtension(path, '.db_route.g.part'));
}

Future<TestBuilderResult> runFeatureBuild(
  Map<String, String> libraries, {
  void Function(LogRecord log)? onLog,
}) {
  return testBuilders(
    <Builder>[
      dbRouteDescriptorBuilder(BuilderOptions.empty),
      dbFeatureRoutesBuilder(BuilderOptions.empty),
    ],
    <String, String>{...stubAssets(), ...libraries},
    rootPackage: fixturePackage,
    onLog: onLog,
  );
}

Future<String> generatedFeatureRoutes(Map<String, String> libraries) async {
  final TestBuilderResult result = await runFeatureBuild(libraries);
  return readOutput(result, 'lib/db_routes.g.dart');
}

Future<String> featureRoutesError(Map<String, String> libraries) async {
  final List<String> errors = <String>[];
  await runFeatureBuild(
    libraries,
    onLog: (LogRecord log) {
      if (log.level >= Level.SEVERE) {
        errors.add('${log.message} ${log.error ?? ''}');
      }
    },
  );
  return errors.join('\n');
}

String routePage(
  String widget, {
  required String path,
  required String feature,
  bool isFeatureEntry = false,
}) {
  return '''
import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';

part '${widget.toLowerCase()}.g.dart';

@DBRoute(path: '$path', feature: '$feature', isFeatureEntry: $isFeatureEntry)
class $widget extends StatelessWidget {
  const $widget({super.key});

  @override
  Widget build(BuildContext context) => const Text('');
}
''';
}

String readOutput(TestBuilderResult result, String path) {
  final AssetId output = result.readerWriter.testing.assets.firstWhere(
    (AssetId id) => id.package == fixturePackage && id.path.endsWith(path),
  );
  return result.readerWriter.testing.readString(output);
}
