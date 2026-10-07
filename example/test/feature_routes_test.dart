import 'package:db_navigator/db_navigator.dart';
import 'package:example/src/nested/screen.dart';
import 'package:example/src/profile/confirm_logout_screen.dart';
import 'package:example/src/profile/profile_screen.dart';
import 'package:example/src/settings/about_screen.dart';
import 'package:example/src/settings/feedback_screen.dart';
import 'package:example/src/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'example_harness.dart';

final List<DBTypedRoute<Object?>> _everyRoute = <DBTypedRoute<Object?>>[
  const ProfileRoute(userId: 'u1'),
  const ConfirmLogoutRoute(),
  const SettingsRoute(),
  const AboutRoute(),
  FeedbackRoute(onSent: () {}),
];

Future<void> _expectEveryRouteResolves(
  WidgetTester tester,
  DBRouterDelegate delegate,
) async {
  for (final DBTypedRoute<Object?> route in _everyRoute) {
    delegate
        .navigateTo<Object?>(location: route.location, arguments: route)
        .ignore();
    await tester.pumpAndSettle();

    expect(delegate.pages.last.destination.path, route.location);
    expect(delegate.pages.last.destination.metadata.arguments, same(route));
  }
}

void main() {
  testWidgets('every generated route resolves in the root navigator',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);

    await _expectEveryRouteResolves(tester, rootDelegate(tester));
  });

  testWidgets('every generated route resolves in a nested navigator',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);
    await tester.tap(find.text('Nested'));
    await tester.pumpAndSettle();

    final DBRouterDelegate nested =
        DBRouterDelegate.of(tester.element(find.byType(Screen).first));
    expect(nested, isNot(same(rootDelegate(tester))));

    await _expectEveryRouteResolves(tester, nested);
  });

  testWidgets('pageFactory routes use the custom page route',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);

    const AboutRoute().push(homeContext(tester)).ignore();
    await tester.pumpAndSettle();

    final DBMaterialPage page =
        rootDelegate(tester).pages.last as DBMaterialPage;
    expect(page.customPageRouteFactory, isNotNull);
    expect(find.text('Version unknown'), findsOneWidget);
  });
}
