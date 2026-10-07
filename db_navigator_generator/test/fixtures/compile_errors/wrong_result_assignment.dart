import 'package:flutter/widgets.dart';

import 'confirm_load_screen.dart';

Future<void> open(BuildContext context, ConfirmLoadRoute route) async {
  final String result =
      await route.push(context); // expect-error: invalid_assignment
  print(result);
}
