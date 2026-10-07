import 'package:db_navigator/db_navigator.dart';
import 'package:db_navigator/src/pop_result_tracker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

DBPage _page(String path) {
  return DBMaterialPage(
    key: UniqueKey(),
    destination: Destination(path: path),
    child: const SizedBox(),
  );
}

void main() {
  late PopResultTracker tracker;

  setUp(() => tracker = PopResultTracker());

  test('track returns one future per page instance', () {
    final DBPage page = _page('/a');

    expect(tracker.track(page), same(tracker.track(page)));
    expect(tracker.track(_page('/a')), isNot(same(tracker.track(page))));
    expect(tracker.length, 2);
  });

  test('complete delivers the result to that page only', () async {
    final DBPage first = _page('/a');
    final DBPage second = _page('/a');
    final Future<Object?> firstResult = tracker.track(first);
    final Future<Object?> secondResult = tracker.track(second);

    tracker
      ..complete(second, 2)
      ..complete(first, 1);

    expect(await firstResult, 1);
    expect(await secondResult, 2);
    expect(tracker.length, 0);
  });

  test('complete is a no-op if absent or already completed', () async {
    final DBPage page = _page('/a');
    final Future<Object?> result = tracker.track(page);

    tracker
      ..complete(_page('/b'), 'other')
      ..complete(page, 'first')
      ..complete(page, 'second');

    expect(await result, 'first');
  });

  test('completeAll completes pending with null, then clears', () async {
    final Future<Object?> result = tracker.track(_page('/a'));

    tracker
      ..completeAll()
      ..completeAll();

    expect(await result, isNull);
    expect(tracker.length, 0);
  });
}
