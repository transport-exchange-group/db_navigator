import 'package:db_navigator_generator/src/route_declaration.dart';
import 'package:test/test.dart';

import 'support/build_harness.dart';

const String _header = '''
import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';

part 'page.g.dart';
''';

Future<String> _generate(String body) {
  return generatedPart('lib/page.dart', '$_header\n$body');
}

Future<void> _expectGenerationError(
  String body,
  List<String> fragments,
) async {
  final String error =
      await generationError('lib/page.dart', '$_header\n$body');

  expect(error, allOf(fragments.map(contains).toList()));
}

String _page(String constructor, {String annotation = '', String fields = ''}) {
  return '''
${annotation.isEmpty ? "@DBRoute(path: '/page', feature: 'pages')" : annotation}
class PageScreen extends StatelessWidget {
  $constructor
  $fields
  @override
  Widget build(BuildContext context) => const Text('');
}
''';
}

void main() {
  group('route class name', () {
    test('strips Screen, View and Page and appends Route', () {
      expect(routeClassNameFor('ConfirmLoadScreen'), 'ConfirmLoadRoute');
      expect(routeClassNameFor('DiallerSheetView'), 'DiallerSheetRoute');
      expect(routeClassNameFor('ProfilePage'), 'ProfileRoute');
      expect(routeClassNameFor('Settings'), 'SettingsRoute');
    });
  });

  group('confirm load fixture', () {
    late String output;

    setUpAll(() async {
      output = await generatedPart(
        'lib/confirm_load_screen.dart',
        readFixture('confirm_load_screen.dart'),
      );
    });

    test('declares the typed route with path and definition', () {
      expect(
        output,
        contains('class ConfirmLoadRoute extends DBTypedRoute<bool>'),
      );
      expect(
        output,
        contains("static const String path = '/loads/confirm';"),
      );
      expect(
        output,
        contains('static const DBRouteDefinition definition'),
      );
      expect(output, contains('decode: ConfirmLoadRoute.fromJson'));
    });

    test('mirrors the page constructor including defaults', () {
      expect(output, contains('const ConfirmLoadRoute({'));
      expect(output, contains('required this.loadId,'));
      expect(output, contains("this.note = '',"));
      expect(output, contains('final Map<String, double> weights;'));
    });

    test('omits defaultRoute when an argument is required', () {
      expect(output, isNot(contains('defaultRoute')));
    });

    test('encodes every serialisable codec', () {
      expect(output, contains("'loadId': loadId,"));
      expect(output, contains("'status': status.name,"));
      expect(output, contains("'pickupAt': pickupAt.toIso8601String(),"));
      expect(
        output,
        contains("'stops': stops.map((DateTime e) => e.toIso8601String())"),
      );
      expect(output, contains("'weights': weights,"));
      expect(output, contains("'driver': driver.toJson(),"));
    });

    test('decodes every serialisable codec', () {
      expect(output, contains("loadId: (json['loadId'] as num).toInt(),"));
      expect(
        output,
        contains("status: LoadStatus.values.byName(json['status'] as String)"),
      );
      expect(
        output,
        contains("pickupAt: DateTime.parse(json['pickupAt'] as String)"),
      );
      expect(output, contains('(v as num).toDouble()'));
      expect(
        output,
        contains(
          "driver: Driver.fromJson(json['driver'] as Map<String, dynamic>)",
        ),
      );
      expect(output, contains("note: json['note'] as String,"));
    });

    test('builds the page widget from the fields', () {
      expect(output, contains('Widget buildWidget() => ConfirmLoadScreen('));
      expect(output, contains('loadId: loadId,'));
    });

    test('is restorable', () {
      expect(output, contains('bool get isRestorable => true;'));
      expect(output, isNot(contains('In-memory only')));
    });

    test('emits a typed close', () {
      expect(
        output,
        contains('static void close(BuildContext context, [bool? result])'),
      );
    });

    test('never serialises runtime type names', () {
      expect(output, isNot(contains('runtimeType')));
    });
  });

  group('arguments', () {
    test('no-argument void route still gets a typed class', () async {
      final String output = await _generate(
        _page('const PageScreen({super.key});'),
      );

      expect(output, contains('class PageRoute extends DBTypedRoute<void>'));
      expect(output, contains('defaultRoute: PageRoute._defaultRoute'));
      expect(output, contains('static void close(BuildContext context) =>'));
    });

    test('defaultRoute is present when every argument is optional', () async {
      final String output = await _generate(
        _page(
          "const PageScreen({this.note = '', super.key});",
          fields: 'final String note;',
        ),
      );

      expect(output, contains('defaultRoute: PageRoute._defaultRoute'));
    });

    test('required nullable and optional defaulted stay distinct', () async {
      final String required = await _generate(
        _page(
          'const PageScreen({required this.note, super.key});',
          fields: 'final String? note;',
        ),
      );
      final String optional = await _generate(
        _page(
          "const PageScreen({this.note = '', super.key});",
          fields: 'final String note;',
        ),
      );

      expect(required, contains('required this.note'));
      expect(required, contains("note: json['note'] as String?"));
      expect(optional, contains("this.note = ''"));
      expect(optional, isNot(contains('required this.note')));
    });

    test('positional arguments stay positional', () async {
      final String output = await _generate(
        _page(
          'const PageScreen(this.id, [this.count = 1]);',
          fields: 'final String id; final int count;',
        ),
      );

      expect(output, contains('const PageRoute(this.id, [this.count = 1]);'));
      expect(output, contains('PageScreen(id, count)'));
    });

    test('nullable codecs use null-aware access', () async {
      final String output = await _generate(
        _page(
          'const PageScreen({this.at, this.ids, super.key});',
          fields: 'final DateTime? at; final List<int>? ids;',
        ),
      );

      expect(output, contains("'at': at?.toIso8601String()"));
      expect(
        output,
        contains("(json['at'] == null ? null : "
            "DateTime.parse(json['at'] as String))"),
      );
      expect(output, contains("json['ids'] as List<Object?>?"));
    });
  });

  group('results', () {
    test('typed route emits close with an optional typed result', () async {
      final String output = await _generate(
        _page(
          'const PageScreen({super.key});',
          annotation: "@DBRoute<int>(path: '/page', feature: 'pages')",
        ),
      );

      expect(output, contains('extends DBTypedRoute<int>'));
      expect(
        output,
        contains('static void close(BuildContext context, [int? result])'),
      );
      expect(output, contains('.close<int?>(result)'));
    });
  });

  group('page factory', () {
    test('top-level page factory is referenced in definition', () async {
      final String output = await _generate('''
DBPage fadePage(Destination destination, Widget child) =>
    throw UnimplementedError();

${_page('const PageScreen({super.key});', annotation: "@DBRoute(path: '/page', feature: 'pages', pageFactory: fadePage)")}
''');

      expect(output, contains('pageFactory: fadePage'));
    });

    test('static page factory is referenced through its class', () async {
      final String output = await _generate('''
class Pages {
  static DBPage fade(Destination destination, Widget child) =>
      throw UnimplementedError();
}

${_page('const PageScreen({super.key});', annotation: "@DBRoute(path: '/page', feature: 'pages', pageFactory: Pages.fade)")}
''');

      expect(output, contains('pageFactory: Pages.fade'));
    });
  });

  group('in-memory routes', () {
    test('callback argument marks the route in-memory', () async {
      final String output = await _generate(
        _page(
          'const PageScreen({required this.onDone, super.key});',
          fields: 'final VoidCallback onDone;',
        ),
      );

      expect(
        output,
        contains(
          '// In-memory only (onDone: VoidCallback): '
          'not restored, not deep-linkable.\n'
          'class PageRoute',
        ),
      );
      expect(output, contains('bool get isRestorable => false;'));
      expect(output, contains('Map<String, Object?>? toJson() => null;'));
    });

    test('toJson without fromJson names parameter and type', () {
      return _expectGenerationError(
        '''
class Token {
  Map<String, Object?> toJson() => <String, Object?>{};
}
${_page('const PageScreen({required this.token, super.key});', fields: 'final Token token;')}
''',
        <String>['lib/page.dart', 'PageScreen', 'token', 'Token', 'fromJson'],
      );
    });

    test('fromJson without toJson names parameter and type', () {
      return _expectGenerationError(
        '''
class Token {
  Token();
  factory Token.fromJson(Map<String, Object?> json) => Token();
}
${_page('const PageScreen({required this.token, super.key});', fields: 'final Token token;')}
''',
        <String>['lib/page.dart', 'PageScreen', 'token', 'Token', 'toJson'],
      );
    });
  });

  group('generation errors', () {
    test('@DBRoute on a non-widget', () {
      return _expectGenerationError(
        "@DBRoute(path: '/page', feature: 'pages')\nclass NotAWidget {}",
        <String>['lib/page.dart', 'NotAWidget', 'not a widget'],
      );
    });

    test('widget with no unnamed constructor', () {
      return _expectGenerationError(
        _page('const PageScreen.named({super.key});'),
        <String>['lib/page.dart', 'PageScreen', 'unnamed constructor'],
      );
    });

    test('path not starting with /', () {
      return _expectGenerationError(
        _page(
          'const PageScreen({super.key});',
          annotation: "@DBRoute(path: 'page', feature: 'pages')",
        ),
        <String>['lib/page.dart', 'PageScreen', "'page'"],
      );
    });

    test('empty path', () {
      return _expectGenerationError(
        _page(
          'const PageScreen({super.key});',
          annotation: "@DBRoute(path: '', feature: 'pages')",
        ),
        <String>['lib/page.dart', 'PageScreen', 'path'],
      );
    });

    test('empty feature', () {
      return _expectGenerationError(
        _page(
          'const PageScreen({super.key});',
          annotation: "@DBRoute(path: '/page', feature: ' ')",
        ),
        <String>['lib/page.dart', 'PageScreen', 'feature'],
      );
    });

    test('map with non-String keys', () {
      return _expectGenerationError(
        _page(
          'const PageScreen({required this.byId, super.key});',
          fields: 'final Map<int, String> byId;',
        ),
        <String>['lib/page.dart', 'PageScreen', 'byId', 'Map<int, String>'],
      );
    });

    test('two widgets mapping to the same route class', () {
      return _expectGenerationError(
        '''
${_page('const PageScreen({super.key});')}

@DBRoute(path: '/other', feature: 'pages')
class PageView extends StatelessWidget {
  const PageView({super.key});

  @override
  Widget build(BuildContext context) => const Text('');
}
''',
        <String>['lib/page.dart', 'PageScreen', 'PageView', 'PageRoute'],
      );
    });

    test('argument clashing with a generated member', () {
      return _expectGenerationError(
        _page(
          'const PageScreen({required this.path, super.key});',
          fields: 'final String path;',
        ),
        <String>['lib/page.dart', 'PageScreen', 'path'],
      );
    });
  });

  test('libraries without @DBRoute produce no output', () async {
    await runRouteBuilder(
      <String, String>{
        fixtureAsset('lib/plain.dart'): 'class Plain {}',
      },
      outputs: <String, Object>{},
    );
  });
}
