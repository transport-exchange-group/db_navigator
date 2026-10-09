import 'package:db_navigator/src/db_router_delegate.dart';
import 'package:db_navigator/src/destination.dart';
import 'package:db_navigator/src/result_type_check.dart';
import 'package:flutter/widgets.dart';

/// Base class of generated typed routes returning [R].
abstract class DBTypedRoute<R extends Object?> {
  /// Const constructor for generated subclasses.
  const DBTypedRoute();

  /// Path of the route.
  String get location;

  /// Whether every argument survives state restoration and deep links.
  bool get isRestorable;

  /// JSON arguments; `null` when the route is in-memory only.
  Map<String, Object?>? toJson();

  /// Builds the page widget from the route's arguments.
  Widget buildWidget();

  /// Destination carrying this route as its arguments.
  Destination get destination {
    return Destination(
      path: location,
      metadata: DestinationMetadata(arguments: this),
    );
  }

  /// Navigate to this route and wait for its result.
  Future<R?> push(
    BuildContext context, {
    bool useRootDelegate = false,
  }) async {
    final Object? result = await DBRouterDelegate.of(
      context,
      root: useRootDelegate,
    ).navigateTo<Object?>(location: location, arguments: this);

    return checkResultType<R>(result, location: location);
  }
}
