import 'package:db_navigator_generator/src/feature_routes_builder.dart';
import 'package:test/test.dart';

import 'support/build_harness.dart';

Map<String, String> _pages(Map<String, String> pages) {
  return <String, String>{
    for (final MapEntry<String, String> page in pages.entries)
      fixtureAsset('lib/${page.key.toLowerCase()}.dart'): page.value,
  };
}

void main() {
  group('feature class name', () {
    test('is the feature in PascalCase plus Routes', () {
      expect(featureClassName('loads'), 'LoadsRoutes');
      expect(featureClassName('load_board'), 'LoadBoardRoutes');
      expect(featureClassName('load-board'), 'LoadBoardRoutes');
      expect(featureClassName('loadBoard'), 'LoadBoardRoutes');
    });
  });

  test('single feature emits a const DBFeatureRoutes unit', () async {
    final String output = await generatedFeatureRoutes(
      _pages(<String, String>{
        'ConfirmScreen': routePage(
          'ConfirmScreen',
          path: '/loads/confirm',
          feature: 'loads',
          isFeatureEntry: true,
        ),
        'DetailScreen': routePage(
          'DetailScreen',
          path: '/loads/detail',
          feature: 'loads',
        ),
      }),
    );

    expect(
        output, contains("import 'package:db_navigator/db_navigator.dart';"));
    expect(
        output, contains("import 'package:fixture_app/confirmscreen.dart';"));
    expect(output, contains('class LoadsRoutes extends DBFeatureRoutes {'));
    expect(
      output,
      contains('const LoadsRoutes({super.onEntered, super.onExited});'),
    );
    expect(output, contains("String get scopeName => 'loads';"));
    expect(
      output,
      contains('const Destination(path: ConfirmRoute.path)'),
    );
    expect(output, contains('ConfirmRoute.definition'));
    expect(output, contains('DetailRoute.definition'));
  });

  test('a single-route feature is its own entry', () async {
    final String output = await generatedFeatureRoutes(
      _pages(<String, String>{
        'ProfileScreen': routePage(
          'ProfileScreen',
          path: '/profile',
          feature: 'profile',
        ),
      }),
    );

    expect(output, contains('const Destination(path: ProfileRoute.path)'));
  });

  test('two features emit two classes', () async {
    final String output = await generatedFeatureRoutes(
      _pages(<String, String>{
        'ProfileScreen': routePage(
          'ProfileScreen',
          path: '/profile',
          feature: 'profile',
        ),
        'SettingsScreen': routePage(
          'SettingsScreen',
          path: '/settings',
          feature: 'settings',
        ),
      }),
    );

    expect(output, contains('class ProfileRoutes extends DBFeatureRoutes'));
    expect(output, contains('class SettingsRoutes extends DBFeatureRoutes'));
  });

  test('duplicate path names both classes and libraries', () async {
    final String error = await featureRoutesError(
      _pages(<String, String>{
        'ProfileScreen': routePage(
          'ProfileScreen',
          path: '/same',
          feature: 'profile',
        ),
        'SettingsScreen': routePage(
          'SettingsScreen',
          path: '/same',
          feature: 'settings',
        ),
      }),
    );

    expect(
      error,
      allOf(
        contains("'/same'"),
        contains('ProfileRoute'),
        contains('SettingsRoute'),
        contains('package:fixture_app/profilescreen.dart'),
        contains('package:fixture_app/settingsscreen.dart'),
      ),
    );
  });

  test('multi-route feature without an entry is an error', () async {
    final String error = await featureRoutesError(
      _pages(<String, String>{
        'AScreen': routePage('AScreen', path: '/a', feature: 'letters'),
        'BScreen': routePage('BScreen', path: '/b', feature: 'letters'),
      }),
    );

    expect(
      error,
      allOf(contains("'letters'"), contains('ARoute'), contains('BRoute')),
    );
  });

  test('multi-route feature with two entries is an error', () async {
    final String error = await featureRoutesError(
      _pages(<String, String>{
        'AScreen': routePage(
          'AScreen',
          path: '/a',
          feature: 'letters',
          isFeatureEntry: true,
        ),
        'BScreen': routePage(
          'BScreen',
          path: '/b',
          feature: 'letters',
          isFeatureEntry: true,
        ),
      }),
    );

    expect(error, allOf(contains("'letters'"), contains('[entry]')));
  });
}
