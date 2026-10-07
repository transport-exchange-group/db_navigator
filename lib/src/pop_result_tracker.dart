import 'dart:async';

import 'package:db_navigator/src/db_page.dart';

/// Tracks the result each pushed page completes with, keyed by page identity.
class PopResultTracker {
  final Map<DBPage, Completer<Object?>> _trackers =
      Map<DBPage, Completer<Object?>>.identity();

  /// Number of pages still waiting for a result.
  int get length => _trackers.length;

  /// Future completed with [page]'s result; one per page instance.
  Future<Object?> track(DBPage page) {
    return _trackers.putIfAbsent(page, Completer<Object?>.new).future;
  }

  /// Complete [page]'s future with [result]; no-op if it is not tracked.
  void complete(DBPage page, Object? result) {
    final Completer<Object?>? tracker = _trackers.remove(page);

    if (tracker != null && !tracker.isCompleted) {
      tracker.complete(result);
    }
  }

  /// Complete every pending future with `null` and stop tracking.
  void completeAll() {
    final List<Completer<Object?>> pending = _trackers.values.toList();
    _trackers.clear();

    for (final Completer<Object?> tracker in pending) {
      if (!tracker.isCompleted) {
        tracker.complete();
      }
    }
  }
}
