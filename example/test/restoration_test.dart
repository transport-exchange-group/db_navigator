import 'package:db_navigator/db_navigator.dart';
import 'package:example/db_routes.g.dart';
import 'package:example/src/home_page_builder.dart';
import 'package:example/src/home_screen.dart';
import 'package:example/src/not_found_screen.dart';
import 'package:example/src/settings/about_screen.dart';
import 'package:example/src/settings/feedback_screen.dart';
import 'package:example/src/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'example_harness.dart';

List<DBPageBuilder> _pageBuilders() {
  return <DBPageBuilder>[
    HomePageBuilder(),
    const ProfileRoutes(),
    const SettingsRoutes(),
  ];
}

DBRouterDelegate _delegate({
  DBPage Function(Destination destination)? notFoundPageFactory,
}) {
  return DBRouterDelegate(
    pageBuilders: _pageBuilders(),
    initialPage: HomePageBuilder.initialPage,
    reportPageUpdateToEngine: true,
    notFoundPageFactory: notFoundPageFactory,
  );
}

void main() {
  test('restore stops at the first in-memory route', () async {
    const DBRouteInformationParser parser = DBRouteInformationParser();
    final DBRouterDelegate saved = _delegate();

    for (final DBTypedRoute<Object?> route in <DBTypedRoute<Object?>>[
      const SettingsRoute(),
      FeedbackRoute(onSent: () {}),
      const AboutRoute(version: '9'),
    ]) {
      saved
          .navigateTo<Object?>(location: route.location, arguments: route)
          .ignore();
      await pumpEventQueue();
    }

    final RouteInformation state =
        parser.restoreRouteInformation(saved.currentConfiguration!);
    final DBRouterDelegate restored = _delegate();
    await restored.setInitialRoutePath(
      await parser.parseRouteInformation(state),
    );

    expect(
      restored.pages.map((DBPage page) => page.destination.path),
      <String>[HomeScreen.path, SettingsRoute.path],
    );
  });

  test('restored typed arguments are identical', () async {
    const DBRouteInformationParser parser = DBRouteInformationParser();
    final DBRouterDelegate saved = _delegate();
    const AboutRoute about = AboutRoute(version: '1.2.3');
    saved
        .navigateTo<Object?>(location: about.location, arguments: about)
        .ignore();
    await pumpEventQueue();

    final DBRouterDelegate restored = _delegate();
    await restored.setInitialRoutePath(
      await parser.parseRouteInformation(
        parser.restoreRouteInformation(saved.currentConfiguration!),
      ),
    );

    final AboutScreen screen = restored.pages.last.child as AboutScreen;
    expect(screen.version, '1.2.3');
  });

  testWidgets('unknown deep link shows the not-found page',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);

    await tester.binding.handlePushRoute('/nowhere');
    await tester.pumpAndSettle();

    expect(find.text('Not found: /nowhere'), findsOneWidget);
  });

  test('unknown deep link without a not-found page keeps the stack', () async {
    final DBRouterDelegate delegate = _delegate();

    await delegate.setNewRoutePath(const Destination(path: '/nowhere'));

    expect(delegate.pages, <DBPage>[HomePageBuilder.initialPage]);
    expect(notFoundPage, isNotNull);
  });
}
