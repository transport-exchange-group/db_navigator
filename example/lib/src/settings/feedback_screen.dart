import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'feedback_screen.g.dart';

/// Feedback form; its callback argument makes the route in-memory only.
@DBRoute(path: '/settings/feedback', feature: 'settings')
class FeedbackScreen extends StatelessWidget {
  /// Called when the feedback is sent.
  final VoidCallback onSent;

  /// Create a [FeedbackScreen].
  const FeedbackScreen({required this.onSent, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            onSent();
            FeedbackRoute.close(context);
          },
          child: const Text('Send'),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onSent', onSent));
  }
}
