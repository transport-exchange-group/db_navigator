import 'package:bdlogging/bdlogging.dart';
import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: diagnostic_describe_all_properties
// ignore_for_file: prefer_constructors_over_static_methods
// Hand-written mirror of generated code, which uses static fromJson.

class GreetingScreen extends StatelessWidget {
  final String name;
  final int times;

  const GreetingScreen({required this.name, this.times = 1, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('$name x$times'),
        TextButton(
          onPressed: () => GreetingRoute.close(context, true),
          child: const Text('confirm'),
        ),
      ],
    );
  }
}

class GreetingRoute extends DBTypedRoute<bool> {
  static const String path = '/greeting';

  static const DBRouteDefinition definition = DBRouteDefinition(
    path: path,
    decode: GreetingRoute.fromJson,
  );

  final String name;
  final int times;

  const GreetingRoute({required this.name, this.times = 1});

  @override
  String get location => path;

  @override
  bool get isRestorable => true;

  // Mirrors the generated signature.
  // ignore: avoid_positional_boolean_parameters
  static void close(BuildContext context, [bool? result]) {
    DBRouterDelegate.of(context).close<bool?>(result);
  }

  static GreetingRoute fromJson(Map<String, Object?> json) {
    return GreetingRoute(
      name: json['name']! as String,
      times: (json['times']! as num).toInt(),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'name': name, 'times': times};
  }

  @override
  Widget buildWidget() => GreetingScreen(name: name, times: times);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const Text('home');
}

class HomeRoute extends DBTypedRoute<void> {
  static const String path = '/home';

  static const DBRouteDefinition definition = DBRouteDefinition(
    path: path,
    decode: HomeRoute.fromJson,
    defaultRoute: HomeRoute._defaultRoute,
  );

  const HomeRoute();

  @override
  String get location => path;

  @override
  bool get isRestorable => true;

  static HomeRoute fromJson(Map<String, Object?> json) => const HomeRoute();

  static HomeRoute _defaultRoute() => const HomeRoute();

  @override
  Map<String, Object?> toJson() => <String, Object?>{};

  @override
  Widget buildWidget() => const HomeScreen();
}

class CallbackRoute extends DBTypedRoute<void> {
  static const String path = '/callback';

  static const DBRouteDefinition definition = DBRouteDefinition(
    path: path,
    decode: CallbackRoute.fromJson,
  );

  final VoidCallback onDone;

  const CallbackRoute({required this.onDone});

  @override
  String get location => path;

  @override
  bool get isRestorable => false;

  static CallbackRoute fromJson(Map<String, Object?> json) {
    throw UnsupportedError('CallbackRoute is in-memory only');
  }

  @override
  Map<String, Object?>? toJson() => null;

  @override
  Widget buildWidget() => const SizedBox();
}

DBPage fadePage(Destination destination, Widget child) {
  return DBMaterialPage(
    key: ValueKey<String>('fade${destination.path}'),
    destination: destination,
    child: child,
  );
}

class GreetingRoutes extends DBFeatureRoutes {
  const GreetingRoutes({super.onEntered, super.onExited});

  @override
  String get scopeName => 'greeting';

  @override
  Destination get initialDestination => const Destination(path: HomeRoute.path);

  @override
  List<DBRouteDefinition> get definitions => const <DBRouteDefinition>[
        HomeRoute.definition,
        GreetingRoute.definition,
        CallbackRoute.definition,
      ];
}

class FadeRoutes extends DBFeatureRoutes {
  const FadeRoutes();

  @override
  String get scopeName => 'fade';

  @override
  Destination get initialDestination => const Destination(path: '/fade');

  @override
  List<DBRouteDefinition> get definitions => const <DBRouteDefinition>[
        DBRouteDefinition(
          path: '/fade',
          decode: HomeRoute.fromJson,
          defaultRoute: HomeRoute._defaultRoute,
          pageFactory: fadePage,
        ),
      ];
}

Future<DBRouterDelegate> pumpRouter(
  WidgetTester tester,
  List<DBPageBuilder> pageBuilders, {
  Destination initial = const Destination(path: HomeRoute.path),
}) async {
  final DBPage? initialPage = await pageBuilders.getPage(initial);

  final DBRouterDelegate delegate = DBRouterDelegate(
    pageBuilders: pageBuilders,
    initialPage: initialPage!,
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerDelegate: delegate,
      routeInformationParser: const DBRouteInformationParser(),
    ),
  );

  return delegate;
}

BuildContext contextOf(WidgetTester tester, Finder finder) {
  return tester.element(finder.last);
}

class RecordingLogHandler extends BDLogHandler {
  final List<BDLogRecord> records = <BDLogRecord>[];

  @override
  bool supportLevel(BDLevel level) => true;

  @override
  Future<void> handleRecord(BDLogRecord record) async => records.add(record);
}
