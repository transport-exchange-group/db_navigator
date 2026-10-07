import 'package:db_navigator/db_navigator.dart';
import 'package:example/src/page_transitions/fade_in_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'about_screen.g.dart';

/// About page, shown with a custom page factory.
@DBRoute(path: '/settings/about', feature: 'settings', pageFactory: fadeInPage)
class AboutScreen extends StatelessWidget {
  /// App version shown.
  final String version;

  /// Create an [AboutScreen].
  const AboutScreen({this.version = 'unknown', super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(child: Text('Version $version')),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('version', version));
  }
}
