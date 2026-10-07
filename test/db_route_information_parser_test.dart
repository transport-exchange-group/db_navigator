import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'typed_route_utils.dart';
import 'utils.dart';

void main() {
  group('restoreRouteInformation', () {
    test(
        'should return RouteInformation object '
        'with location being the destination path', () async {
      const DBRouteInformationParser parser = DBRouteInformationParser();
      final RouteInformation routeInfo = parser.restoreRouteInformation(
        const Destination(path: Page2.path),
      );

      expect(routeInfo.uri.toString(), equals(Page2.path));
    });
  });

  restorationTests();
}

void restorationTests() {
  const DBRouteInformationParser parser = DBRouteInformationParser();

  Destination stack(List<Destination> destinations) {
    final Destination top = destinations.last;
    return Destination(
      path: top.path,
      metadata: DestinationMetadata(
        arguments: top.metadata.arguments,
        history: destinations.sublist(0, destinations.length - 1),
      ),
    );
  }

  group('restoreRouteInformation state', () {
    test('is the metadata as JSON', () {
      final RouteInformation info = parser.restoreRouteInformation(
        const GreetingRoute(name: 'Ada', times: 2).destination,
      );

      expect(info.state, isA<Map<String, Object?>>());
      expect(
        info.state,
        <String, Object?>{
          'arguments': <String, Object?>{'name': 'Ada', 'times': 2},
        },
      );
    });

    test('cuts history at the first in-memory typed route', () {
      final RouteInformation info = parser.restoreRouteInformation(
        stack(<Destination>[
          const Destination(path: HomeRoute.path),
          const GreetingRoute(name: 'Ada').destination,
          CallbackRoute(onDone: () {}).destination,
          const GreetingRoute(name: 'Bob').destination,
        ]),
      );

      expect(info.uri.toString(), GreetingRoute.path);
      final Destination restored = Destination.fromRouteInformation(info);
      expect(restored.metadata.arguments, <String, Object?>{
        'name': 'Ada',
        'times': 1,
      });
      expect(
        restored.metadata.history?.map((Destination d) => d.path),
        <String>[HomeRoute.path],
      );
    });

    test('cuts history at a legacy argument that is not JSON', () {
      final RouteInformation info = parser.restoreRouteInformation(
        stack(<Destination>[
          const Destination(path: Page1.path),
          const Destination(
            path: Page2.path,
            metadata: DestinationMetadata(arguments: Duration.zero),
          ),
          const Destination(path: Page3.path),
        ]),
      );

      expect(info.uri.toString(), Page1.path);
    });

    test('restores the root when the first destination is in-memory', () {
      final RouteInformation info = parser.restoreRouteInformation(
        stack(<Destination>[
          CallbackRoute(onDone: () {}).destination,
          const GreetingRoute(name: 'Ada').destination,
        ]),
      );

      expect(info.uri.toString(), '/');
      expect(info.state, isNull);
    });

    test('cuts a typed route whose toJson is not plain JSON', () {
      final RouteInformation info = parser.restoreRouteInformation(
        stack(<Destination>[
          const Destination(path: Page1.path),
          const NestedObjectRoute().destination,
        ]),
      );

      expect(info.uri.toString(), Page1.path);
    });
  });
}
