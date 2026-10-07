import 'package:db_navigator/db_navigator.dart';
import 'package:example/db_routes.g.dart';
import 'package:example/src/example_app.dart';
import 'package:example/src/home_page_builder.dart';
import 'package:example/src/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpExampleApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ExampleApp(
      initialPage: HomePageBuilder.initialPage,
      pageBuilders: <DBPageBuilder>[HomePageBuilder(), const ProfileRoutes()],
    ),
  );
  await tester.pumpAndSettle();
}

BuildContext homeContext(WidgetTester tester) {
  return tester.element(find.byType(HomeScreen));
}

DBRouterDelegate rootDelegate(WidgetTester tester) {
  return DBRouterDelegate.of(homeContext(tester));
}

Future<void> systemBack(WidgetTester tester) async {
  await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
  await tester.pumpAndSettle();
}
