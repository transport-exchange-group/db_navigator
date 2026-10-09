import 'package:db_navigator/src/db_page.dart';
import 'package:db_navigator/src/destination.dart';
import 'package:flutter/widgets.dart';

/// Declares a page widget as a typed route returning [R].
///
/// The widget's unnamed constructor parameters (except `key`) become the
/// route's arguments.
class DBRoute<R extends Object?> {
  /// Path of the route; starts with `/` and is unique in the app.
  final String path;

  /// Feature the route belongs to; routes sharing it are registered together.
  final String feature;

  /// Whether the route is its feature's initial destination.
  final bool isFeatureEntry;

  /// Builds the page; a top-level or static function. Defaults to
  /// a `DBMaterialPage`.
  final DBPage Function(Destination destination, Widget child)? pageFactory;

  /// Create a [DBRoute].
  const DBRoute({
    required this.path,
    required this.feature,
    this.isFeatureEntry = false,
    this.pageFactory,
  });
}
