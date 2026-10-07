# Migrating to typed routes

Move one feature at a time. Legacy page builders and generated routes live in the same `DBRouterDelegate`, so the app keeps working between steps.

## 1. Set up (once per app)

```yaml
dependencies:
  db_navigator:
    git:
      url: git@github.com:transport-exchange-group/db_navigator.git
      ref: release/0.2.0   # v1.1.0+

dev_dependencies:
  build_runner: ^2.4.0
  db_navigator_generator:
    git:
      url: git@github.com:transport-exchange-group/db_navigator.git
      ref: release/0.2.0
      path: db_navigator_generator
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

Output:

- `<page>.g.dart` — one typed route class per annotated page (shared with json_serializable / freezed parts).
- `lib/db_routes.g.dart` — one `<Feature>Routes` page builder per feature.

## 2. Plain route

**Before** — path constant, routing map entry, page builder:

```dart
class SettingsView extends StatelessWidget {
  static const String location = '/settings';
  const SettingsView({super.key});
}

AsyncRoutingMap settingsRoutingMap = {
  SettingsView.location: (Destination destination) async => DBMaterialPage(
        key: ValueKey<String>(destination.path),
        destination: destination,
        child: const SettingsView(),
      ),
};

DBRouterDelegate.of(context).navigateTo(location: SettingsView.location);
```

**After** — annotate the page; delete the map entry:

```dart
part 'settings_view.g.dart';

@DBRoute(path: '/settings', feature: 'settings', isFeatureEntry: true)
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
}

const SettingsRoute().push(context);
```

The route class is the widget name minus `Screen` / `View` / `Page`, plus `Route`.

## 3. Route with arguments and a result

**Before** — untyped argument, cast in the routing map, untyped result:

```dart
DiallerBottomSheetView.location: (Destination destination) async {
  final String phoneNumber = destination.metadata.arguments! as String;
  return fadeInFadeOutPage(
    destination: destination,
    pageContent: DiallerBottomSheetView(phoneNumber: phoneNumber),
  );
},

final bool? called = await DBRouterDelegate.of(context)
    .navigateTo<bool>(location: DiallerBottomSheetView.location, arguments: number);
```

**After** — the constructor is the contract:

```dart
@DBRoute<bool>(path: '/dialler', feature: 'dialler', pageFactory: fadePage)
class DiallerBottomSheetView extends StatelessWidget {
  const DiallerBottomSheetView({required this.phoneNumber, super.key});
  final String phoneNumber;
  // ...
  DiallerBottomSheetRoute.close(context, true);
}

final bool? called = await DiallerBottomSheetRoute(phoneNumber: number).push(context);
```

- Missing or wrongly typed arguments, and wrongly typed results, are **compile errors**.
- Defaults (`this.count = 0`) and nullability carry over exactly.
- System back still completes the caller with `null`.
- Serialisable argument types: `String`, `int`, `double`, `num`, `bool`, enums, `DateTime`, `List` / `Map<String, _>` of these, and classes with `toJson()` plus `fromJson(Map)` (json_serializable / freezed).

## 4. Page transitions (`fadeInFadeOutPage` → `pageFactory`)

`pageFactory` takes `DBPage Function(Destination, Widget)` and must be top-level or static. Wrap the app's existing helper once:

```dart
DBPage fadePage(Destination destination, Widget child) =>
    fadeInFadeOutPage(destination: destination, pageContent: child);
```

> `fadeInFadeOutPage` keys pages with `ValueKey(destination.path)`. Pushing the same route twice then trips Navigator's duplicate-key assertion. Use `UniqueKey()` in new factories; generated default pages already do.

## 5. Modal / bottom sheet

Modals stay app-owned. Each typed route exposes `destination` (path + the route as arguments), so add one typed overload next to the existing `showModal`:

```dart
extension TypedModal on BuildContext {
  Future<R?> showTypedModal<R>(DBTypedRoute<R> route, {DBPageBuilder? pageBuilder}) {
    return showModal<R>(
      location: route.location,
      arguments: route,
      pageBuilder: pageBuilder,
    );
  }
}

final bool? called = await context.showTypedModal(DiallerBottomSheetRoute(phoneNumber: number));
```

Pass the feature's generated `<Feature>Routes` as `pageBuilder` when the modal's nested delegate needs it.

## 6. Nested / tab navigation

Generated feature units are ordinary page builders. Register them in any delegate, root or nested:

```dart
DBRouterDelegate(
  initialPage: TabPageBuilder.initialPage,
  pageBuilders: <DBPageBuilder>[
    const LoadsRoutes(),
    const BookingsRoutes(),
    TabPageBuilder(), // catch-all legacy builders last
  ],
);
```

`push(context)` uses the nearest delegate; pass `useRootDelegate: true` to push on the root.

## 7. Callback / service arguments (in-memory only)

Any other argument type (callbacks, services, controllers, streams) is allowed, but the route becomes **in-memory only**:

```dart
// In-memory only (onDone: VoidCallback): not restored, not deep-linkable.
class FeedbackRoute extends DBTypedRoute<void> { ... }
```

- State restoration rebuilds the stack **up to** the first in-memory route; it and everything above are dropped.
- Deep links to it open the not-found page (see below).
- Prefer passing ids and resolving services from DI inside the page.
- A class with `toJson()` but no `fromJson` (or the reverse) is a generation error, not silently in-memory.

## 8. Feature scope: `AnalyticsPageBuilder` and per-feature DI

**Before** — subclass to hook scope events:

```dart
class DiallerPageBuilder extends AnalyticsPageBuilder { ... }
```

**After** — pass callbacks to the generated unit:

```dart
void logFeatureOpened(String scope) {
  BDLogger().info('Feature $scope opened', tag: 'feature_analytics');
  TegDI.backend<AnalyticsService>().logScreenView(screenName: scope);
}

DiallerRoutes(
  onEntered: (String scope) {
    setUpDiallerDependencies(); // per-feature DI that lived in the builder
    logFeatureOpened(scope);
  },
  onExited: logFeatureClosed,
);
```

`scope` is the `feature` name. `onEntered` / `onExited` fire when the feature's entry route is pushed / removed.

## 9. Unknown deep links

```dart
DBRouterDelegate(
  // ...
  notFoundPageFactory: (Destination destination) => DBMaterialPage(
    key: UniqueKey(),
    destination: destination,
    child: NotFoundView(path: destination.path),
  ),
);
```

Without it, an unknown path (or arguments that fail to decode) keeps the current stack and logs a `BDLogger` warning.

## 10. Per-feature checklist

1. Add `part '<file>.g.dart';` and `@DBRoute(...)` to every page in the feature.
2. Mark exactly one page `isFeatureEntry: true` (single-page features are their own entry).
3. Run `build_runner`.
4. Replace the feature's page builder in every delegate with `const <Feature>Routes(...)`.
5. Replace `navigateTo(location: X.location, arguments: ...)` with `XRoute(...).push(context)` and drop result casts.
6. Replace `DBRouterDelegate.of(context).close(result)` with `XRoute.close(context, result)`.
7. Delete the routing map, the page builder and the `location` constants.
8. Move scope logic (`AnalyticsPageBuilder`, DI setup) into `onEntered` / `onExited`.

## 11. Verify

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Then, manually: open every route, check arguments show, results return, system back returns `null`, and a deep link to each path opens (or shows not-found for in-memory routes).

## 12. Roll back

Each feature migrates independently. To roll one back, revert its commit: the legacy builder and map return, and the generated `<Feature>Routes` disappears on the next `build_runner` run. Other migrated features are unaffected.
