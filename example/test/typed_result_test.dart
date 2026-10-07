import 'package:example/src/profile/confirm_logout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'example_harness.dart';

void main() {
  testWidgets('closing with true gives the caller true as bool',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);

    final Future<bool?> result =
        const ConfirmLogoutRoute().push(homeContext(tester));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Yes'));
    await tester.pumpAndSettle();

    final bool? confirmed = await result;
    expect(confirmed, isTrue);
  });

  testWidgets('system back gives the caller null',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);

    final Future<bool?> result =
        const ConfirmLogoutRoute().push(homeContext(tester));
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(await result, isNull);
  });

  testWidgets('same route pushed twice gives each caller its own result',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);

    final Future<bool?> first =
        const ConfirmLogoutRoute().push(homeContext(tester));
    await tester.pumpAndSettle();
    final Future<bool?> second = const ConfirmLogoutRoute()
        .push(tester.element(find.byType(ConfirmLogoutScreen)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'No'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Yes'));
    await tester.pumpAndSettle();

    expect(await second, isFalse);
    expect(await first, isTrue);
  });
}
