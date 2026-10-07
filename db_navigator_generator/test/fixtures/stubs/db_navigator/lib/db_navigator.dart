import 'package:flutter/widgets.dart';

export 'src/typed/db_route.dart';

abstract class DBPage {}

class DestinationMetadata {
  const DestinationMetadata({this.arguments});

  final Object? arguments;
}

class Destination {
  const Destination({
    required this.path,
    this.metadata = const DestinationMetadata(),
  });

  final String path;
  final DestinationMetadata metadata;
}

class DBRouterDelegate {
  static DBRouterDelegate of(BuildContext context, {bool root = false}) =>
      throw UnimplementedError();

  void close<T extends Object?>([T? result]) {}
}

class DBRouteDefinition {
  const DBRouteDefinition({
    required this.path,
    required this.decode,
    this.defaultRoute,
    this.pageFactory,
  });

  final String path;
  final DBTypedRoute<Object?> Function(Map<String, Object?> json) decode;
  final DBTypedRoute<Object?> Function()? defaultRoute;
  final DBPage Function(Destination destination, Widget child)? pageFactory;
}

abstract class DBTypedRoute<R extends Object?> {
  const DBTypedRoute();

  String get location;
  bool get isRestorable;
  Map<String, Object?>? toJson();
  Widget buildWidget();

  Future<R?> push(BuildContext context, {bool useRootDelegate = false}) =>
      throw UnimplementedError();
}

abstract class DBFeatureRoutes {
  const DBFeatureRoutes({this.onEntered, this.onExited});

  final void Function(String scopeName)? onEntered;
  final void Function(String scopeName)? onExited;

  String get scopeName;
  Destination get initialDestination;
  List<DBRouteDefinition> get definitions;
}
