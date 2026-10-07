import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/build_harness.dart';

final RegExp _expectError = RegExp(r'//\s*expect-error:\s*(\w+)');
final RegExp _expectErrorInPart = RegExp(r'//\s*expect-error-in-part:\s*(\w+)');
final RegExp _generatedFrom = RegExp(r'//\s*generated-from:\s*(\S+)');

late Directory _workspace;
late AnalysisContextCollection _analysis;

String get _appLib => p.join(_workspace.path, 'app', 'lib');

void main() {
  final Directory fixtures =
      Directory(p.join(fixturesDirectory, 'compile_errors'));
  final List<File> fixtureFiles = fixtures
      .listSync()
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  setUpAll(() async {
    _workspace = Directory.systemTemp.createTempSync('db_route_compile_');
    await _writeWorkspace(fixtureFiles);
    _analysis = AnalysisContextCollection(
      includedPaths: <String>[p.join(_workspace.path, 'app')],
    );
  });

  tearDownAll(() => _workspace.deleteSync(recursive: true));

  test('generated route compiles against the runtime API', () async {
    final List<AnalysisError> errors =
        await _errorsIn(p.join(_appLib, 'confirm_load_screen.g.dart'));

    expect(errors, isEmpty);
  });

  for (final File fixture in fixtureFiles) {
    final String name = p.basename(fixture.path);

    test('$name reports its expected compile errors', () async {
      final String source = fixture.readAsStringSync();
      final String path = p.join(_appLib, name);

      final RegExpMatch? inPart = _expectErrorInPart.firstMatch(source);
      if (inPart != null) {
        final List<AnalysisError> partErrors = await _errorsIn(
          p.setExtension(path, '.g.dart'),
        );
        expect(_codes(partErrors), contains(inPart.group(1)));
        return;
      }

      final List<AnalysisError> errors = await _errorsIn(path);
      final Map<int, String> expected = _expectedErrors(source);

      expect(expected, isNotEmpty, reason: '$name has no expect-error tags');
      for (final MapEntry<int, String> entry in expected.entries) {
        expect(
          _codesOnLine(errors, entry.key, source),
          contains(entry.value),
          reason: '$name:${entry.key + 1}',
        );
      }
    });
  }
}

Future<void> _writeWorkspace(List<File> fixtureFiles) async {
  final Directory stubs = Directory(p.join(fixturesDirectory, 'stubs'));
  Directory(_appLib).createSync(recursive: true);

  await _writeLibraryWithPart(
    'confirm_load_screen.dart',
    readFixture('confirm_load_screen.dart'),
  );

  for (final File fixture in fixtureFiles) {
    final String name = p.basename(fixture.path);
    final String source = fixture.readAsStringSync();
    final RegExpMatch? generatedFrom = _generatedFrom.firstMatch(source);

    if (generatedFrom == null) {
      File(p.join(_appLib, name)).writeAsStringSync(source);
    } else {
      await _writeLibraryWithPart(
        name,
        source,
        generateFrom: readFixture(generatedFrom.group(1)!),
      );
    }
  }

  final Map<String, Object?> packageConfig = <String, Object?>{
    'configVersion': 2,
    'packages': <Map<String, Object?>>[
      _package('fixture_app', p.join(_workspace.path, 'app')),
      _package('db_navigator', p.absolute(stubs.path, 'db_navigator')),
      _package('flutter', p.absolute(stubs.path, 'flutter')),
    ],
  };
  File(p.join(_workspace.path, 'app', '.dart_tool', 'package_config.json'))
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(packageConfig));
  File(p.join(_workspace.path, 'app', 'pubspec.yaml'))
      .writeAsStringSync('name: fixture_app\n');
}

Future<void> _writeLibraryWithPart(
  String name,
  String source, {
  String? generateFrom,
}) async {
  final String part = await generatedPart('lib/$name', generateFrom ?? source);
  File(p.join(_appLib, name)).writeAsStringSync(source);
  File(p.join(_appLib, p.setExtension(name, '.g.dart')))
      .writeAsStringSync("part of '$name';\n\n$part");
}

Map<String, Object?> _package(String name, String root) {
  return <String, Object?>{
    'name': name,
    'rootUri': p.toUri(root).toString(),
    'packageUri': 'lib/',
    'languageVersion': '3.6',
  };
}

Future<List<AnalysisError>> _errorsIn(String path) async {
  final SomeErrorsResult result =
      await _analysis.contextFor(path).currentSession.getErrors(path);
  return (result as ErrorsResult)
      .errors
      .where((AnalysisError error) =>
          error.errorCode.errorSeverity == ErrorSeverity.ERROR)
      .toList();
}

Map<int, String> _expectedErrors(String source) {
  final List<String> lines = const LineSplitter().convert(source);
  return <int, String>{
    for (int line = 0; line < lines.length; line++)
      if (_expectError.firstMatch(lines[line]) case final RegExpMatch match)
        line: match.group(1)!,
  };
}

Iterable<String> _codes(List<AnalysisError> errors) {
  return errors.map(
    (AnalysisError error) => error.errorCode.name.toLowerCase(),
  );
}

Iterable<String> _codesOnLine(
  List<AnalysisError> errors,
  int line,
  String source,
) {
  return _codes(
    errors
        .where(
          (AnalysisError error) =>
              '\n'.allMatches(source.substring(0, error.offset)).length == line,
        )
        .toList(),
  );
}
