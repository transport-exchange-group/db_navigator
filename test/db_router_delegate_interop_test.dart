import 'package:db_navigator/db_navigator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'typed_route_utils.dart';
import 'utils.dart';

DBRouterDelegate _delegate() {
  return DBRouterDelegate(
    pageBuilders: <DBPageBuilder>[
      const TestPageBuilder(),
      const GreetingRoutes(),
    ],
    initialPage: TestPageBuilder.initialPage,
  );
}

Future<bool?> _pushGreeting(DBRouterDelegate delegate) {
  const GreetingRoute route = GreetingRoute(name: 'Ada');
  return delegate.navigateTo<bool>(location: route.location, arguments: route);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy -> generated -> legacy delivers results both ways', () async {
    final DBRouterDelegate delegate = _delegate();

    final Future<String?> legacy =
        delegate.navigateTo<String>(location: Page2.path);
    await pumpEventQueue();
    final Future<bool?> typed = _pushGreeting(delegate);
    await pumpEventQueue();
    final Future<int?> innerLegacy =
        delegate.navigateTo<int>(location: Page3.path);
    await pumpEventQueue();

    delegate
      ..close<int>(3)
      ..close<bool>(true)
      ..close<String>('two');

    expect(await innerLegacy, 3);
    expect(await typed, isTrue);
    expect(await legacy, 'two');
  });

  test('generated -> legacy -> generated delivers results', () async {
    final DBRouterDelegate delegate = _delegate();

    final Future<bool?> typed = _pushGreeting(delegate);
    await pumpEventQueue();
    final Future<String?> legacy =
        delegate.navigateTo<String>(location: Page2.path);
    await pumpEventQueue();
    final Future<bool?> innerTyped = _pushGreeting(delegate);
    await pumpEventQueue();

    delegate
      ..close<bool>(false)
      ..close<String>('two')
      ..close<bool>(true);

    expect(await innerTyped, isFalse);
    expect(await legacy, 'two');
    expect(await typed, isTrue);
  });
}
