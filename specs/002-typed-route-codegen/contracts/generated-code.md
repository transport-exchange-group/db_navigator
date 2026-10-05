# Contract: Generator Input → Output

## Input (developer-authored, 1 file — SC-001)

```dart
import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';

part 'confirm_load_screen.g.dart';

@DBRoute<bool>(path: '/loads/confirm', feature: 'loads', isFeatureEntry: true)
class ConfirmLoadScreen extends StatelessWidget {
  const ConfirmLoadScreen({required this.loadId, this.note = '', super.key});

  final int loadId;
  final String note;
  // build(...) — returns via ConfirmLoadRoute.close(context, true)
}
```

## Output 1 — `confirm_load_screen.g.dart` (part, shape only)

```dart
class ConfirmLoadRoute extends DBTypedRoute<bool> {
  const ConfirmLoadRoute({required this.loadId, this.note = ''});
  static const String path = '/loads/confirm';
  static const DBRouteDefinition definition = DBRouteDefinition(/* ... */);
  final int loadId;
  final String note;
  static void close(BuildContext context, [bool? result]);
  static ConfirmLoadRoute fromJson(Map<String, Object?> json);
  // push, toJson, buildWidget, destination, isRestorable
}
```

Naming: `<WidgetName>` minus a trailing `Screen` / `View` / `Page`, plus `Route`. Collisions within a library → generation error.

In-memory only routes get one comment line above the class:
`// In-memory only (onDone: VoidCallback): not restored, not deep-linkable.`

## Output 2 — `lib/db_routes.g.dart` (aggregate)

```dart
class LoadsRoutes extends DBFeatureRoutes {
  const LoadsRoutes({super.onEntered, super.onExited});
  @override String get scopeName => 'loads';
  @override Destination get initialDestination => const Destination(path: ConfirmLoadRoute.path);
  @override List<DBRouteDefinition> get definitions => const [ConfirmLoadRoute.definition, /* ... */];
}
```

Feature class name: feature name in PascalCase + `Routes`.

## Compile-time guarantees (SC-003)

| Misuse | Result |
|--------|--------|
| Missing required argument | compile error |
| Argument of the wrong type | compile error |
| `push` result assigned to wrong type | compile error |
| `ConfirmLoadRoute.close(context, 'x')` | compile error |
| Page constructor changed, generation not re-run | generated code fails to compile |

## Generation errors (FR-005) — each names file + class

| Condition | Message names |
|-----------|---------------|
| Duplicate path | both classes and libraries |
| Feature with 0 or >1 entries (multi-route feature) | feature + routes |
| `@DBRoute` on a non-widget / no unnamed constructor | class |
| `Map` with non-`String` keys | parameter |
| `toJson` without `fromJson` (or reverse) | parameter + type |
| Path empty or not starting with `/` | class |
