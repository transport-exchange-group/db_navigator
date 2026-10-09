import 'package:bdlogging/bdlogging.dart';
import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'typed_route_utils.dart';
import 'utils.dart';

DBPage _notFoundPage(Destination destination) {
  return DBMaterialPage(
    key: UniqueKey(),
    destination: destination,
    child: Text('not found ${destination.path}'),
  );
}

DBRouterDelegate _delegate({
  DBPage Function(Destination destination)? notFoundPageFactory,
}) {
  return DBRouterDelegate(
    pageBuilders: <DBPageBuilder>[
      const TestPageBuilder(),
      const GreetingRoutes(),
    ],
    initialPage: TestPageBuilder.initialPage,
    notFoundPageFactory: notFoundPageFactory,
  );
}

const Destination _undecodable = Destination(
  path: GreetingRoute.path,
  metadata: DestinationMetadata(
    arguments: <String, Object?>{'name': 42},
  ),
);

void main() {
  late RecordingLogHandler logs;

  setUp(() {
    logs = RecordingLogHandler();
    BDLogger().addHandler(logs);
  });

  tearDown(() => BDLogger().removeHandler(logs));

  Future<Iterable<String>> warnings() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return logs.records
        .where((BDLogRecord record) => record.level == BDLevel.warning)
        .map((BDLogRecord record) => record.message);
  }

  for (final Destination destination in <Destination>[
    const Destination(path: unknownPath),
    _undecodable,
  ]) {
    group('${destination.path} with arguments '
        '${destination.metadata.arguments}', () {
      test('setNewRoutePath pushes the not-found page', () async {
        final DBRouterDelegate delegate =
            _delegate(notFoundPageFactory: _notFoundPage);

        await delegate.setNewRoutePath(destination);

        expect(delegate.pages, hasLength(2));
        expect(
          (delegate.pages.last.child as Text).data,
          'not found ${destination.path}',
        );
      });

      test('setInitialRoutePath shows the not-found page', () async {
        final DBRouterDelegate delegate =
            _delegate(notFoundPageFactory: _notFoundPage);

        await delegate.setInitialRoutePath(destination);

        expect(delegate.pages, hasLength(1));
        expect(delegate.pages.single.child, isA<Text>());
      });

      test('without a factory keeps the stack and warns', () async {
        final DBRouterDelegate delegate = _delegate();

        await delegate.setNewRoutePath(destination);
        await delegate.setInitialRoutePath(destination);

        expect(delegate.pages, <DBPage>[TestPageBuilder.initialPage]);
        expect(await warnings(), contains(contains(destination.path)));
      });
    });
  }
}
