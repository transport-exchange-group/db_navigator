import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'typed_route_utils.dart';

void main() {
  test('destination carries the path and the route as arguments', () {
    const GreetingRoute route = GreetingRoute(name: 'Ada');

    final Destination destination = route.destination;

    expect(destination.path, GreetingRoute.path);
    expect(destination.metadata.arguments, same(route));
  });

  testWidgets('push navigates to the path with the route as arguments',
      (WidgetTester tester) async {
    final DBRouterDelegate delegate =
        await pumpRouter(tester, <DBPageBuilder>[const GreetingRoutes()]);
    const GreetingRoute route = GreetingRoute(name: 'Ada', times: 2);

    route.push(contextOf(tester, find.byType(HomeScreen))).ignore();
    await tester.pumpAndSettle();

    final DBPage top = delegate.pages.last;
    expect(top.destination.path, GreetingRoute.path);
    expect(top.destination.metadata.arguments, same(route));
    expect(find.text('Ada x2'), findsOneWidget);
  });

  testWidgets('push completes with the typed result',
      (WidgetTester tester) async {
    await pumpRouter(tester, <DBPageBuilder>[const GreetingRoutes()]);

    final Future<bool?> result = const GreetingRoute(name: 'Ada')
        .push(contextOf(tester, find.byType(HomeScreen)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('system back completes the caller with null',
      (WidgetTester tester) async {
    await pumpRouter(tester, <DBPageBuilder>[const GreetingRoutes()]);

    final Future<bool?> result = const GreetingRoute(name: 'Ada')
        .push(contextOf(tester, find.byType(HomeScreen)));
    await tester.pumpAndSettle();

    final NavigatorState navigator = tester.state(find.byType(Navigator).last);
    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
