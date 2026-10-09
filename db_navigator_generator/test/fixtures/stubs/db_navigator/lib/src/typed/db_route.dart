import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/widgets.dart';

class DBRoute<R extends Object?> {
  const DBRoute({
    required this.path,
    required this.feature,
    this.isFeatureEntry = false,
    this.pageFactory,
  });

  final String path;
  final String feature;
  final bool isFeatureEntry;
  final DBPage Function(Destination destination, Widget child)? pageFactory;
}
