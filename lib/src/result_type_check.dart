import 'package:bdlogging/bdlogging.dart';
import 'package:flutter/foundation.dart';

/// Narrows a page [result] to [T]; a mismatch asserts in debug and
/// returns `null` with a warning in release.
T? checkResultType<T extends Object?>(
  Object? result, {
  required String location,
  bool assertionsEnabled = kDebugMode,
}) {
  if (result is T?) {
    return result;
  }

  final String message = 'Route $location was closed with a result of type '
      '${result.runtimeType}, expected $T';

  if (assertionsEnabled) {
    throw AssertionError(message);
  }

  BDLogger().warning(message);
  return null;
}
