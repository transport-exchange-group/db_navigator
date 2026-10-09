import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shown for deep links no page builder can open.
class NotFoundScreen extends StatelessWidget {
  /// Path that could not be opened.
  final String path;

  /// Create a [NotFoundScreen].
  const NotFoundScreen({required this.path, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Not found: $path')));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('path', path));
  }
}

/// `DBRouterDelegate.notFoundPageFactory` for the example app.
DBPage notFoundPage(Destination destination) {
  return DBMaterialPage(
    key: UniqueKey(),
    destination: destination,
    child: NotFoundScreen(path: destination.path),
  );
}
