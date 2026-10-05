# Research: Typed Route Code Generation

**Feature**: `002-typed-route-codegen` | **Date**: 2026-10-05

Router direction (own generator vs auto_route / go_router) was settled in the spec. This file resolves the technical unknowns left for planning.

## R1 — Where the generator lives

- **Decision**: A separate package, `db_navigator_generator/`, in this repository. Apps add it as a `dev_dependency` via the same git URL with `path: db_navigator_generator`.
- **Rationale**: Keeps `analyzer`, `build`, `source_gen` out of the runtime package (spec assumption: no significant new runtime dependency). Same split TEG already uses for `json_annotation` / `json_serializable` and `freezed_annotation` / `freezed`.
- **Alternatives**: Builder inside `db_navigator` itself — rejected; would make every consumer resolve analyzer as a runtime dependency.

## R2 — Analyzer / source_gen version window

- **Decision**: `analyzer: ">=6.9.0 <8.0.0"`, `source_gen: ^2.0.0`, `build: ^2.4.1`, generator SDK `>=3.6.0 <4.0.0`. Use the V1 element model (`ClassElement`, `ConstructorElement`, `ParameterElement`).
- **Rationale**: TEGFlutterApp's lockfile resolves analyzer 7.6.0, source_gen 2.0.0, build 2.5.4, build_runner 2.5.4. Its `freezed 2.5.8` caps analyzer `<8.0.0`, so the app cannot move to analyzer 8 yet. source_gen 2.0.0 only exposes the V1 element model; analyzer 8.0 removed V1.
- **Risk / follow-up**: When the app upgrades freezed (→ analyzer 8+), the generator needs a port to the new element model as a separate release. Logged in plan → Risks.
- **Alternatives**: Target analyzer 8+ element model now — rejected, the app could not resolve it.

## R3 — Generation pipeline shape

- **Decision**: Two builders.
  1. **`db_route`** (per library, `SharedPartBuilder` → `*.g.dart`): for each `@DBRoute` widget, emits the typed route class and its argument codec into the page's part file, plus a small JSON descriptor `*.db_route.json` (path, feature, class name, library URI, entry flag, restorable flag).
  2. **`db_feature_routes`** (aggregate, input `lib/$lib$`, output `lib/db_routes.g.dart`): reads all descriptors, validates (duplicate paths, one entry per feature), and emits one `DBFeatureRoutes` subclass per feature.
- **Rationale**: Types stay in the per-library part, where they are already resolved — no type serialisation across phases. The aggregate only needs names and URIs, so it is cheap (SC-007) and is the one place that sees every path (FR-005 duplicate detection, US3-AS2). Same two-phase pattern used by injectable and auto_route.
- **Alternatives**:
  - Single aggregate builder that resolves every library under `lib/` — rejected, resolves the whole app each build (SC-007).
  - Developer-written `@DBFeature(routes: [A, B])` list — rejected, reintroduces manual registration (FR-003) and silent omissions.

## R4 — How typed arguments travel

- **Decision**: The typed route instance *is* the `arguments` object passed to `navigateTo`. The generated `DBFeatureRoutes.buildPage` accepts it directly; if `arguments` is a `Map` (restored state / deep link), it decodes via the route's generated `fromJson`, keyed by **path**, not type name.
- **Rationale**: No global registry, no `runtimeType.toString()` (FR-008, obfuscation-safe). Legacy routes untouched.
- **Alternatives**: Register generated decoders in `DestinationArgumentConverter` — rejected; it keys by runtime type name, which breaks under obfuscation.

## R5 — Serialisable vs in-memory arguments

- **Decision**: Generator classifies each constructor parameter against the spec's serialisable set (primitives, enums, `DateTime`, `List`/`Map<String, _>` of these, classes with `toJson()` + `factory fromJson(Map)`). Any other type marks the route **in-memory only**: its `toJson()` returns `null`, and the generated class carries a 1-line comment naming the offending parameter (FR-009).
- **Encoding**: enum → `name`; `DateTime` → ISO-8601 string; custom class → `toJson()` / `fromJson(...)`, casting to the declared `fromJson` parameter type.
- **Rationale**: Mirrors json_serializable conventions the team already knows.

## R6 — State restoration and the in-memory cut-off

- **Finding**: Restoration today is router-level — `currentConfiguration` returns the top destination whose `metadata.history` holds the stack, and `DBRouteInformationParser.restoreRouteInformation` puts the `DestinationMetadata` *object* into `RouteInformation.state`. Router restoration needs primitive state, so any non-primitive argument breaks it.
- **Decision**: `restoreRouteInformation` stores `metadata.toJson()`, truncating the history at the first destination whose arguments are not JSON-primitive (generated in-memory routes, or legacy objects without `HasToJson`). `Destination.fromRouteInformation` accepts a `Map` state. Spec clarification: restore up to the first in-memory route, drop it and everything above.
- **Alternatives**: Page-level `restorationId` per page — rejected; restoration ids must be unique per navigator and the same path can be pushed twice.

## R7 — Result tracking defects (FR-012)

| Defect | Root cause (in `db_router_delegate.dart`) | Fix |
|--------|-------------------------------------------|-----|
| Same path pushed twice loses first result | `_popResultTracker` keyed by `path` | Key trackers by the `DBPage` instance (identity) |
| Crash on dispose after reset | `reset` completes trackers but keeps them; `dispose` calls `complete()` again | Complete only if not completed; `reset` clears the map |
| `closeUntilLast` ignores results | `resultMap` not forwarded to `closeUntil` | Forward it |
| Mistyped result crashes caller | `Completer<T?>` stored as `Completer<Object?>`, completed with wrong type → `TypeError` | Store `Completer<Object?>`; `navigateTo<T>` checks `is T`: debug assert naming route + both types, release returns `null` + `BDLogger` warning |

- **Decision**: Extract tracking into a small `PopResultTracker` class (SRP; the delegate is already 654 lines).
- `onPopPage` matches the popped route by `identical(page, route.settings)` instead of name.

## R8 — Page keys for generated routes

- **Decision**: Generated pages use `UniqueKey()` — fixed at build time and held in `_pages`.
- **Rationale**: Pushing the same path twice with `ValueKey(path)` trips Navigator's duplicate-key assertion.

## R9 — Unknown deep links (FR-015)

- **Decision**: New optional `DBRouterDelegate(notFoundPageFactory: DBPage Function(Destination)?)`. Used by `setInitialRoutePath` / `setNewRoutePath` when no builder supports the path **or** a generated route fails to decode its arguments. If absent: keep stack, `BDLogger().warning(...)`.

## R10 — Presentation (transitions, modal)

- **Finding**: TEGFlutterApp wraps pages with app-owned factories (`fadeInFadeOutPage(...)`) and shows modals through its own `showModal` extension, which builds a nested delegate inside a bottom sheet.
- **Decision**: `@DBRoute(pageFactory: fadeInFadeOutPage)` — an optional top-level/static function `DBPage Function(Destination destination, Widget child)`. Default is `DBMaterialPage`. Modals stay app-owned: the typed route exposes `destination` so the app's `showModal` gains a typed overload (documented in the migration guide, not built here).
- **Alternatives**: A `presentation: modal` enum in the package — rejected (KISS); modal sheets are app UI.

## R11 — Feature scope behaviour

- **Finding**: App builders extend `AnalyticsPageBuilder` (a `ScopedPageBuilder`) only to log scope enter/exit.
- **Decision**: Generated feature units are `const` and take optional `onEntered` / `onExited` callbacks (`void Function(String scopeName)`). Scope name defaults to the feature name. Composition replaces the base-class hierarchy.

## R12 — Minimum SDK (FR-014)

- **Finding**: Runtime package uses `RouteInformation.uri` (Flutter 3.13) but declares `flutter: ">=3.0.0"`. Generic annotations (`@DBRoute<bool>`) need Dart 2.14+.
- **Decision**: Runtime `sdk: ">=3.1.0 <4.0.0"`, `flutter: ">=3.13.0"`. Generator `sdk: ">=3.6.0 <4.0.0"`. Both ≤ app pin (Flutter 3.38.8 / Dart 3.10.7). `onPopPage` stays (deprecated upstream but present in 3.38; swapping it is a behaviour change, out of scope).

## R13 — Testing the generator

- **Decision**:
  - Output tests with `build_test` (`testBuilder`) — exact-output checks per scenario (FR-011).
  - Compile-error tests (SC-003): fixture files using generated routes wrongly, analysed with `AnalysisContextCollection`; each fixture line tagged `// expect-error: <code>` must report that diagnostic.
  - Pick the newest `build_test` whose constraints accept `build 2.5.x` and `analyzer <8` at implementation time.

## R14 — Deprecations in this release

- **Decision**: None. FR-006 allows them, but SC-004 requires zero changes; the app may run analyze with infos as fatal. Deprecate legacy APIs in the release after TEGFlutterApp migrates.

## R15 — Release line (FR-013)

- **Finding**: `release/0.2.0` (v1.0.0, `34176cc`) is an ancestor of this branch with no code differences.
- **Decision**: Ship as **v1.1.0**; open the PR against `release/0.2.0`.
