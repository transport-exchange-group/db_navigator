import 'package:example/src/profile/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'example_harness.dart';

void main() {
  testWidgets('omitted defaulted argument shows its default',
      (WidgetTester tester) async {
    await pumpExampleApp(tester);

    const ProfileRoute(userId: 'u1').push(homeContext(tester)).ignore();
    await tester.pumpAndSettle();

    expect(find.text('User: u1'), findsOneWidget);
    expect(find.text('Visits: 0'), findsOneWidget);
  });
}
