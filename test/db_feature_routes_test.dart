import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'typed_route_utils.dart';

void main() {
  const GreetingRoutes routes = GreetingRoutes();

  test('supports only the paths in definitions', () {
    expect(
      routes.supportRoute(const Destination(path: GreetingRoute.path)),
      isTrue,
    );
    expect(routes.supportRoute(const Destination(path: '/other')), isFalse);
  });

  test('uses typed route arguments as they are', () async {
    const GreetingRoute route = GreetingRoute(name: 'Ada');

    final DBPage page = await routes.buildPage(route.destination);

    expect(page.destination.metadata.arguments, same(route));
    expect(page.child, isA<GreetingScreen>());
  });

  test('decodes map arguments', () async {
    final DBPage page = await routes.buildPage(
      const Destination(
        path: GreetingRoute.path,
        metadata: DestinationMetadata(
          arguments: <String, Object?>{'name': 'Ada', 'times': 3},
        ),
      ),
    );

    final GreetingScreen screen = page.child as GreetingScreen;
    expect(screen.name, 'Ada');
    expect(screen.times, 3);
    expect(page.destination.metadata.arguments, isA<GreetingRoute>());
  });

  test('uses the default route when arguments are null', () async {
    final DBPage page =
        await routes.buildPage(const Destination(path: HomeRoute.path));

    expect(page.child, isA<HomeScreen>());
  });

  test('throws PageNotFoundException without a default route', () {
    expect(
      () => routes.buildPage(const Destination(path: GreetingRoute.path)),
      throwsA(isA<PageNotFoundException>()),
    );
  });

  test('throws PageNotFoundException for other argument types', () {
    expect(
      () => routes.buildPage(
        const Destination(
          path: GreetingRoute.path,
          metadata: DestinationMetadata(arguments: 42),
        ),
      ),
      throwsA(isA<PageNotFoundException>()),
    );
  });

  test('builds a DBMaterialPage with a unique key per page', () async {
    final DBPage first = await routes.buildPage(
      const GreetingRoute(name: 'Ada').destination,
    );
    final DBPage second = await routes.buildPage(
      const GreetingRoute(name: 'Ada').destination,
    );

    expect(first, isA<DBMaterialPage>());
    expect(first.key, isA<UniqueKey>());
    expect(first.key, isNot(second.key));
  });

  test('uses the definition page factory', () async {
    final DBPage page =
        await const FadeRoutes().buildPage(const Destination(path: '/fade'));

    expect(page.key, const ValueKey<String>('fade/fade'));
  });

  test('calls onEntered and onExited with the scope name', () {
    final List<String> events = <String>[];
    GreetingRoutes(
      onEntered: (String scope) => events.add('entered $scope'),
      onExited: (String scope) => events.add('exited $scope'),
    )
      ..onInitialDestinationEntered()
      ..onInitialDestinationExited();

    expect(events, <String>['entered greeting', 'exited greeting']);
  });

  test('is a no-op without scope callbacks', () {
    expect(routes.onInitialDestinationEntered, returnsNormally);
    expect(routes.onInitialDestinationExited, returnsNormally);
  });
}
