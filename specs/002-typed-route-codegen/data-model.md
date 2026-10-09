# Data Model: Typed Route Code Generation

**Feature**: `002-typed-route-codegen` | **Date**: 2026-10-05

Entities from the spec (Key Entities), mapped to concrete types. Runtime types live in `db_navigator`; generator-internal types live in `db_navigator_generator`.

## 1. Route declaration — `DBRoute<R>` (runtime, annotation)

| Field | Type | Rule |
|-------|------|------|
| `R` (type argument) | result type | Omitted → `void` (route returns no result) |
| `path` | `String` | Required, starts with `/`, unique across the package (generator-checked) |
| `feature` | `String` | Required, non-empty; groups routes into one `DBFeatureRoutes` |
| `isFeatureEntry` | `bool` | Default `false`. Exactly one per feature when the feature has >1 route; a single-route feature is its own entry |
| `pageFactory` | `DBPage Function(Destination, Widget)?` | Optional top-level or static function; default builds `DBMaterialPage` |

**Applies to**: a `StatelessWidget` / `StatefulWidget` class with an unnamed constructor. That constructor's parameters (except `key`) are the route's arguments.

## 2. Route argument (generator-internal `RouteArgument`)

| Field | Source |
|-------|--------|
| `name` | constructor parameter name |
| `type` | declared type, including nullability |
| `kind` | required positional / optional positional / required named / optional named |
| `defaultValueCode` | copied verbatim from the constructor |
| `codec` | one of `primitive`, `enum`, `dateTime`, `list`, `map`, `json`, `inMemory` |

**Validation (FR-005, generation fails with an actionable message):**
- Widget has no unnamed constructor.
- `Map` key type is not `String`.
- Class with `toJson()` but no `fromJson` factory (or vice versa) — reported as a likely mistake, not silently treated as in-memory.

**Nullable vs optional**: `String? note` (required, may be null) and `{String note = ''}` (optional, defaulted) stay distinct because the generated constructor mirrors the page's constructor exactly.

## 3. Typed route — generated `<Page>Route extends DBTypedRoute<R>`

| Member | Purpose |
|--------|---------|
| `static const String path` | the declared path |
| fields + constructor | mirror of the page's arguments |
| `Future<R?> push(BuildContext context, {bool useRootDelegate = false})` | typed navigation (FR-002) |
| `static void close(BuildContext context, [R? result])` | typed close (US2-AS2) |
| `Destination get destination` | for app-owned presenters (e.g. `showModal`) |
| `bool get isRestorable` | `false` when any argument is in-memory |
| `Map<String, Object?>? toJson()` | `null` when in-memory only |
| `static <Page>Route fromJson(Map<String, Object?> json)` | decode for restoration / deep link |
| `Widget buildWidget()` | builds the page widget from the fields |

**Runtime base** `DBTypedRoute<R>` (in `db_navigator`) owns `push`'s shared logic: calls `navigateTo<Object?>(location: path, arguments: this)`, then narrows the result to `R?` with the FR-012 debug-assert / release-warn rule.

## 4. Route definition — `DBRouteDefinition` (runtime)

The const record each typed route exposes as `static const definition`, consumed by feature units.

| Field | Type |
|-------|------|
| `path` | `String` |
| `decode` | `DBTypedRoute<Object?> Function(Map<String, Object?> json)` |
| `defaultRoute` | `DBTypedRoute<Object?> Function()?` — present only when every argument is optional, so a bare deep link can still open it |
| `pageFactory` | `DBPage Function(Destination, Widget)?` |

## 5. Feature route group — generated `<Feature>Routes extends DBFeatureRoutes`

`DBFeatureRoutes` (runtime) extends `ScopedPageBuilder`.

| Member | Rule |
|--------|------|
| `scopeName` | the feature name |
| `initialDestination` | the entry route's path |
| `definitions` | `List<DBRouteDefinition>` — every route in the feature |
| `onEntered` / `onExited` | optional `void Function(String scopeName)` passed to the `const` constructor; `onEntered` is where the app runs the feature's dependency setup |
| `supportRoute(d)` | `d.path` is in `definitions` |
| `buildPage(d)` | `arguments is DBTypedRoute` → use it; `is Map` → `decode`; `null` → `defaultRoute`; otherwise throw `PageNotFoundException` |

**Validation (aggregate builder):** duplicate `path` across any two declarations → error naming both classes and libraries (US3-AS2); zero or multiple entries in a multi-route feature → error naming the feature.

## 6. Route descriptor — `*.db_route.json` (generator-internal, phase 1 → phase 2)

```json
{
  "path": "/dialler",
  "feature": "dialler",
  "routeClass": "DiallerBottomSheetRoute",
  "library": "package:fx/src/dialler/ui/dialler_bottom_sheet_view.dart",
  "isFeatureEntry": true,
  "isRestorable": true
}
```

One file per page library, holding a list of descriptors. Not checked in (build cache only).

## 7. Pop result tracker — `PopResultTracker` (runtime, internal)

| Operation | Rule |
|-----------|------|
| `track(DBPage page)` → `Future<Object?>` | one completer per page instance |
| `complete(DBPage page, Object? result)` | no-op if absent or already completed |
| `completeAll()` | completes pending with `null`, then clears |

Replaces `Map<String, Completer<Object?>> _popResultTracker`. The `@visibleForTesting popResultTracker` constructor parameter changes type to `PopResultTracker?`: a per-path map cannot hold two pushes of the same path. Test-only, so app code is unaffected (SC-004); noted in CHANGELOG.

## State transitions — navigation stack on restore

```
Saved stack:   [A] → [B] → [C*] → [D]        (* = in-memory only)
Restored:      [A] → [B]                     (C and everything above dropped)
```

Deep link to a path with no builder, or a generated route whose `decode` throws:

```
notFoundPageFactory set?  ── yes → push not-found page
                          └─ no  → keep stack, BDLogger().warning(...)
```
