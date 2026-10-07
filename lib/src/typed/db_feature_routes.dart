import 'package:db_navigator/src/db_page.dart';
import 'package:db_navigator/src/destination.dart';
import 'package:db_navigator/src/exceptions.dart';
import 'package:db_navigator/src/scoped_page_builder.dart';
import 'package:db_navigator/src/typed/db_route_definition.dart';
import 'package:db_navigator/src/typed/db_typed_route.dart';
import 'package:flutter/widgets.dart';

/// Page builder for one feature's generated typed routes.
abstract class DBFeatureRoutes extends ScopedPageBuilder {
  /// Called with [scopeName] when the feature's entry route is pushed.
  final void Function(String scopeName)? onEntered;

  /// Called with [scopeName] when the feature's entry route is removed.
  final void Function(String scopeName)? onExited;

  /// Create a [DBFeatureRoutes].
  const DBFeatureRoutes({this.onEntered, this.onExited});

  /// Every route of the feature.
  List<DBRouteDefinition> get definitions;

  @override
  void onInitialDestinationEntered() => onEntered?.call(scopeName);

  @override
  void onInitialDestinationExited() => onExited?.call(scopeName);

  @override
  bool supportRoute(Destination destination) {
    return _definitionFor(destination) != null;
  }

  @override
  Future<DBPage> buildPage(Destination destination) async {
    final DBRouteDefinition? definition = _definitionFor(destination);

    if (definition == null) {
      throw PageNotFoundException(destination);
    }

    final DBTypedRoute<Object?> route = _routeFor(definition, destination);

    final Destination typedDestination = Destination(
      path: destination.path,
      metadata: DestinationMetadata(
        arguments: route,
        history: destination.metadata.history,
      ),
    );

    final Widget child = route.buildWidget();

    return definition.pageFactory?.call(typedDestination, child) ??
        DBMaterialPage(
          key: UniqueKey(),
          destination: typedDestination,
          child: child,
        );
  }

  DBRouteDefinition? _definitionFor(Destination destination) {
    for (final DBRouteDefinition definition in definitions) {
      if (definition.path == destination.path) {
        return definition;
      }
    }
    return null;
  }

  DBTypedRoute<Object?> _routeFor(
    DBRouteDefinition definition,
    Destination destination,
  ) {
    final Object? arguments = destination.metadata.arguments;

    if (arguments is DBTypedRoute<Object?>) {
      return arguments;
    }

    if (arguments is Map<String, Object?>) {
      return definition.decode(arguments);
    }

    final DBTypedRoute<Object?>? defaultRoute =
        arguments == null ? definition.defaultRoute?.call() : null;

    if (defaultRoute == null) {
      throw PageNotFoundException(destination);
    }

    return defaultRoute;
  }
}
