# Contract: Runtime Public API (`package:db_navigator/db_navigator.dart`)

Additive only. Every existing export keeps its signature (FR-006, SC-004).

## New exports

```dart
class DBRoute<R extends Object?> {
  const DBRoute({
    required String path,
    required String feature,
    bool isFeatureEntry = false,
    DBPage Function(Destination destination, Widget child)? pageFactory,
  });
}

abstract class DBTypedRoute<R extends Object?> {
  const DBTypedRoute();
  String get path;
  bool get isRestorable;
  Map<String, Object?>? toJson();
  Widget buildWidget();
  Destination get destination;
  Future<R?> push(BuildContext context, {bool useRootDelegate = false});
}

class DBRouteDefinition {
  const DBRouteDefinition({
    required String path,
    required DBTypedRoute<Object?> Function(Map<String, Object?> json) decode,
    DBTypedRoute<Object?> Function()? defaultRoute,
    DBPage Function(Destination destination, Widget child)? pageFactory,
  });
}

abstract class DBFeatureRoutes extends ScopedPageBuilder {
  const DBFeatureRoutes({this.onEntered, this.onExited});
  final void Function(String scopeName)? onEntered;
  final void Function(String scopeName)? onExited;
  List<DBRouteDefinition> get definitions;
}
```

## Changed (non-breaking)

| Symbol | Change |
|--------|--------|
| `DBRouterDelegate(...)` | new optional `notFoundPageFactory: DBPage Function(Destination)?`; `@visibleForTesting popResultTracker` type `Map<String, Completer<Object?>>?` → `PopResultTracker?` (test-only) |
| `DBRouterDelegate.navigateTo<T>` | wrong-typed result → debug assert (route + expected + actual type); release → `null` + warning. Previously a `TypeError`. |
| `DBRouterDelegate.close` / `closeUntil` / `closeUntilLast` | results delivered per pushed page, not per path; `closeUntilLast` honours `resultMap` |
| `DBRouterDelegate.dispose` | safe after `reset` |
| `DBRouterDelegate.setNewRoutePath` / `setInitialRoutePath` | unknown path → not-found page or warning (was: silently ignored) |
| `DBRouteInformationParser.restoreRouteInformation` | `state` is JSON (`metadata.toJson()`), history cut at the first non-restorable destination |
| `Destination.fromRouteInformation` | also accepts a `Map` state |
| `DestinationArgumentConverter.pojoToJson` | `DBTypedRoute` → its `toJson()` (no type-name key) |

## Behavioural guarantees

- Generated and legacy pages coexist in one `DBRouterDelegate`, in either push order (FR-007).
- Dismissal without a result (system back) completes the caller's future with `null` (US2-AS3).
- No API uses `runtimeType.toString()` for generated routes (FR-008).
