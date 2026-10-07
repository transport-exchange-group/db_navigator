import 'package:db_navigator/src/destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'toRouteInformation',
    () {
      test(
        'should contain exact same path and state '
        'as destination path and metadata',
        () {
          const Destination homeDestination = Destination(path: '/home');
          const List<Destination> history = <Destination>[homeDestination];
          const Destination destination = Destination(
            path: '/',
            metadata: DestinationMetadata(arguments: 0, history: history),
          );

          final RouteInformation routeInformation =
              destination.toRouteInformation();

          expect(routeInformation.uri.toString(), equals(destination.path));

          expect(routeInformation.state, isA<DestinationMetadata>());

          expect(
            identical(routeInformation.state, destination.metadata),
            isTrue,
          );
        },
      );
    },
  );

  group(
    'toSettings',
    () {
      test(
        'should contain exact same name and arguments '
        'as destination path and metadata arguments',
        () {
          const Destination destination = Destination(
            path: '/',
            metadata: DestinationMetadata(arguments: 0),
          );

          final RouteSettings settings = destination.toSettings();

          expect(settings.name, equals(destination.path));
          expect(settings.arguments, equals(destination.metadata.arguments));
        },
      );
    },
  );

  mapStateTests();
}

void mapStateTests() {
  test('fromRouteInformation keeps a non-metadata Map state as arguments', () {
    final Destination destination = Destination.fromRouteInformation(
      RouteInformation(
        uri: Uri.parse('/x'),
        state: <Object?, Object?>{'id': 1},
      ),
    );

    expect(destination.metadata.arguments, <Object?, Object?>{'id': 1});
  });

  test('fromRouteInformation keeps an invalid metadata Map as arguments', () {
    final Destination destination = Destination.fromRouteInformation(
      RouteInformation(
        uri: Uri.parse('/x'),
        state: <String, Object?>{'arguments': null},
      ),
    );

    expect(
        destination.metadata.arguments, <String, Object?>{'arguments': null});
  });

  test('fromRouteInformation accepts a Map state from the platform codec', () {
    final Destination destination = Destination.fromRouteInformation(
      RouteInformation(
        uri: Uri.parse('/b'),
        state: <Object?, Object?>{
          'arguments': <Object?, Object?>{'name': 'Ada'},
          'history': <Object?>[
            <Object?, Object?>{
              'path': '/a',
              'metadata': <Object?, Object?>{},
            },
          ],
        },
      ),
    );

    expect(destination.path, '/b');
    expect(destination.metadata.arguments, <String, Object?>{'name': 'Ada'});
    expect(destination.metadata.history?.single.path, '/a');
  });
}
