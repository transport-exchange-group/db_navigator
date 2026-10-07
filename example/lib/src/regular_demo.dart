import 'package:db_navigator/db_navigator.dart';
import 'package:example/src/profile/confirm_logout_screen.dart';
import 'package:flutter/material.dart';

/// Regular demo screen.
class RegularDemo extends StatelessWidget {
  /// Navigation path of the [RegularDemo].
  static const String path = '/regular';

  /// Create a [RegularDemo] in a const expression.
  const RegularDemo({Key? key}) : super(key: key);

  Future<void> _confirmThenClose(BuildContext context) async {
    final DBRouterDelegate delegate = DBRouterDelegate.of(context);
    final bool? confirmed = await const ConfirmLogoutRoute().push(context);
    // close() mistakes a not-yet-rebuilt page for a dialog; let it rebuild.
    await WidgetsBinding.instance.endOfFrame;
    delegate.close<String>('confirmed: $confirmed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _confirmThenClose(context),
          child: const Text('Confirm via typed route'),
        ),
      ),
    );
  }
}
