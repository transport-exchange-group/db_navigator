import 'package:db_navigator/db_navigator.dart';
import 'package:example/src/profile/confirm_logout_screen.dart';
import 'package:example/src/regular_demo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'profile_screen.g.dart';

/// Profile of a user, opened through the generated [ProfileRoute].
@DBRoute(path: '/profile', feature: 'profile', isFeatureEntry: true)
class ProfileScreen extends StatefulWidget {
  /// Id of the user shown.
  final String userId;

  /// Number of visits shown.
  final int visits;

  /// Create a [ProfileScreen].
  const ProfileScreen({required this.userId, this.visits = 0, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('userId', userId))
      ..add(IntProperty('visits', visits));
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _lastResult = '';

  Future<void> _confirmLogout() async {
    final bool? confirmed = await const ConfirmLogoutRoute().push(context);
    setState(() => _lastResult = 'Logout confirmed: $confirmed');
  }

  Future<void> _openLegacy() async {
    final String? result = await DBRouterDelegate.of(context)
        .navigateTo<String>(location: RegularDemo.path);
    setState(() => _lastResult = 'Legacy result: $result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('User: ${widget.userId}'),
            Text('Visits: ${widget.visits}'),
            ElevatedButton(
              onPressed: _confirmLogout,
              child: const Text('Log out'),
            ),
            ElevatedButton(
              onPressed: _openLegacy,
              child: const Text('Open legacy screen'),
            ),
            Text(_lastResult),
          ],
        ),
      ),
    );
  }
}
