import 'package:example/src/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'example_harness.dart';

void main() {
  testWidgets('generated -> legacy -> generated delivers every result',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);

    const ProfileRoute(userId: 'u1').push(homeContext(tester)).ignore();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open legacy screen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm via typed route'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Legacy result: confirmed: true'), findsOneWidget);
  });
}
