import 'package:db_navigator/src/db_page.dart';
import 'package:db_navigator/src/destination.dart';
import 'package:db_navigator/src/typed/db_typed_route.dart';
import 'package:flutter/widgets.dart';

/// Generated description of a typed route, consumed by feature route groups.
class DBRouteDefinition {
  /// Path of the route.
  final String path;

  /// Rebuilds the route from its JSON arguments.
  final DBTypedRoute<Object?> Function(Map<String, Object?> json) decode;

  /// Route opened without arguments; only set when every argument is optional.
  final DBTypedRoute<Object?> Function()? defaultRoute;

  /// Custom page factory; `null` builds a `DBMaterialPage`.
  final DBPage Function(Destination destination, Widget child)? pageFactory;

  /// Create a [DBRouteDefinition].
  const DBRouteDefinition({
    required this.path,
    required this.decode,
    this.defaultRoute,
    this.pageFactory,
  });
}
