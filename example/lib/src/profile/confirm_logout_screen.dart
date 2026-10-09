import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';

part 'confirm_logout_screen.g.dart';

/// Asks the user to confirm logging out; returns the answer.
@DBRoute<bool>(path: '/profile/logout', feature: 'profile')
class ConfirmLogoutScreen extends StatelessWidget {
  /// Create a [ConfirmLogoutScreen].
  const ConfirmLogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log out?')),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => ConfirmLogoutRoute.close(context, true),
              child: const Text('Yes'),
            ),
            ElevatedButton(
              onPressed: () => ConfirmLogoutRoute.close(context, false),
              child: const Text('No'),
            ),
          ],
        ),
      ),
    );
  }
}
