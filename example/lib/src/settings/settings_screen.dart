import 'package:db_navigator/db_navigator.dart';
import 'package:example/src/settings/about_screen.dart';
import 'package:example/src/settings/feedback_screen.dart';
import 'package:flutter/material.dart';

part 'settings_screen.g.dart';

/// Settings home, the entry of the settings feature.
@DBRoute(path: '/settings', feature: 'settings', isFeatureEntry: true)
class SettingsScreen extends StatelessWidget {
  /// Create a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: () => const AboutRoute(version: '1.1.0').push(context),
            child: const Text('About'),
          ),
          ElevatedButton(
            onPressed: () => FeedbackRoute(
              onSent: () => debugPrint('feedback sent'),
            ).push(context),
            child: const Text('Feedback'),
          ),
        ],
      ),
    );
  }
}
