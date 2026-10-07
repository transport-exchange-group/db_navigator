import 'package:flutter/widgets.dart';

import 'confirm_load_screen.dart';

void done(BuildContext context) {
  ConfirmLoadRoute.close(
      context, 'x'); // expect-error: argument_type_not_assignable
}
