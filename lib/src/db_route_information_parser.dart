import 'package:db_navigator/src/db_router_delegate.dart';
import 'package:db_navigator/src/destination.dart';
import 'package:db_navigator/src/destination_argument_converter.dart';
import 'package:db_navigator/src/typed/db_typed_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Transport Exchange Group Route Information parser.
///
/// Parse route information sent from the system to a [Destination], that's
/// suitable for [DBRouterDelegate].
class DBRouteInformationParser extends RouteInformationParser<Destination> {
  /// Const constructor. This constructor this class
  /// to be used in const expressions.
  const DBRouteInformationParser();

  @override
  Future<Destination> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    return SynchronousFuture<Destination>(
      Destination.fromRouteInformation(routeInformation),
    );
  }

  @override
  RouteInformation restoreRouteInformation(Destination configuration) {
    final List<Destination> stack = <Destination>[
      ...?configuration.metadata.history,
      configuration,
    ];
    final int firstUnrestorable = stack.indexWhere(
      (Destination destination) => !_isRestorable(destination),
    );
    final List<Destination> restorable = firstUnrestorable < 0
        ? stack
        : stack.sublist(0, firstUnrestorable);

    if (restorable.isEmpty) {
      return RouteInformation(uri: Uri.parse(configuration.path));
    }

    final Destination top = restorable.last;
    final List<Destination> history = restorable
        .sublist(0, restorable.length - 1)
        .map(_withoutHistory)
        .toList();

    return RouteInformation(
      uri: Uri.parse(top.path),
      state: DestinationMetadata(
        arguments: top.metadata.arguments,
        history: history.isEmpty ? null : history,
      ).toJson(),
    );
  }

  Destination _withoutHistory(Destination destination) {
    return Destination(
      path: destination.path,
      metadata: DestinationMetadata(arguments: destination.metadata.arguments),
    );
  }

  bool _isRestorable(Destination destination) {
    final Object? arguments = destination.metadata.arguments;

    if (arguments is DBTypedRoute<Object?>) {
      return arguments.isRestorable;
    }

    return _isJson(DestinationArgumentConverter.pojoToJson(arguments));
  }

  bool _isJson(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return true;
    }
    if (value is List<Object?>) {
      return value.every(_isJson);
    }
    if (value is Map<String, Object?>) {
      return value.values.every(_isJson);
    }
    return false;
  }
}
