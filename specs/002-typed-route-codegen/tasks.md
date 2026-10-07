---

description: "Task list for Typed Route Code Generation"
---

# Tasks: Typed Route Code Generation

**Input**: Design documents from `/specs/002-typed-route-codegen/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included. FR-011 requires automated generator tests, SC-003 requires compile-error coverage, and the constitution requires tests for all new behaviour. Write each story's tests first and confirm they fail.

**Organization**: Tasks are grouped by user story so each story can be built and tested on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: The user story the task belongs to (US1–US5)

## Path Conventions

- Runtime package: `lib/`, `test/` at repo root
- Generator package: `db_navigator_generator/lib/`, `db_navigator_generator/test/`
- Example app: `example/lib/`, `example/test/`
- Docs: `doc/`, `README.md`, `CHANGELOG.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Package scaffolding and SDK floors

- [X] T001 Create `db_navigator_generator/pubspec.yaml` (name `db_navigator_generator`, version `1.1.0`, sdk `">=3.6.0 <4.0.0"`; deps `analyzer: ">=6.9.0 <8.0.0"`, `source_gen: ^2.0.0`, `build: ^2.4.1`, `code_builder`, `dart_style`, `db_navigator: {path: ../}`; dev deps `build_test`, `test`) and `db_navigator_generator/analysis_options.yaml` including `flutter_code_style`
- [X] T002 [P] Create `db_navigator_generator/build.yaml` matching contracts/build-config.md: builder `db_route` (input `.dart`, output `.db_route.g.part`, `auto_apply: dependents`, `build_to: cache`, `applies_builders: ["source_gen|combining_builder"]`), builder `db_route_descriptor` (input `.dart`, output `.db_route.json`, `auto_apply: dependents`, `build_to: cache`) and builder `db_feature_routes` (input `lib/$lib$`, output `lib/db_routes.g.dart`, `auto_apply: dependents`, `build_to: source`, `required_inputs: [".db_route.json"]`)
- [X] T003 Raise SDK floors in root `pubspec.yaml` to sdk `">=3.1.0 <4.0.0"`, flutter `">=3.13.0"` (FR-014, research R12) and, in the same commit, PATCH-amend `.specify/memory/constitution.md` to 1.0.1: Technical Constraints SDK → Dart `>=3.1.0 <4.0.0`, Flutter `>=3.13.0`; Development Workflow "tests in `test/`" → "tests in the owning package's `test/` (root, `db_navigator_generator/`, `example/`)"; update the Sync Impact Report
- [X] T004 [P] Update `example/pubspec.yaml`: sdk `">=3.1.0 <4.0.0"`; add dev deps `build_runner: ^2.4.0`, `db_navigator_generator: {path: ../db_navigator_generator}`, `integration_test: {sdk: flutter}`
- [X] T005 Run `flutter pub get` (root, `example/`) and `dart pub get` (`db_navigator_generator/`) under Flutter 3.38.8; pick the newest `build_test` that resolves with `build 2.5.x` and `analyzer <8` and record the chosen version in research.md R13

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Runtime typed-route API surface and generator internals every story builds on

**⚠️ CRITICAL**: No user story work starts until this phase is complete

- [X] T006 [P] Create `DBRoute<R extends Object?>` annotation in `lib/src/typed/db_route.dart` with `required String path`, `required String feature`, `bool isFeatureEntry = false`, `DBPage Function(Destination destination, Widget child)? pageFactory` — signature exactly as contracts/public-api.md
- [X] T007 [P] Create `DBRouteDefinition` in `lib/src/typed/db_route_definition.dart` with `const` constructor: `required String path`, `required DBTypedRoute<Object?> Function(Map<String, Object?> json) decode`, `DBTypedRoute<Object?> Function()? defaultRoute`, `DBPage Function(Destination, Widget)? pageFactory`
- [X] T008 [P] Create abstract `DBTypedRoute<R extends Object?>` in `lib/src/typed/db_typed_route.dart` with `const` constructor and members `path`, `isRestorable`, `toJson()`, `buildWidget()`, `destination` (returns `Destination(path: path, metadata: DestinationMetadata(arguments: this))`); declare `push` (body in T026)
- [X] T009 Export `DBRoute`, `DBTypedRoute`, `DBRouteDefinition` from `lib/db_navigator.dart` (depends on T006–T008)
- [X] T010 [P] Create `db_navigator_generator/lib/src/generation_errors.dart`: one factory per row of the contracts/generated-code.md "Generation errors" table, each throwing `InvalidGenerationSourceError` whose message names the file and class (and parameter/type where the table says so)
- [X] T011 [P] Create `RouteDescriptor` in `db_navigator_generator/lib/src/route_descriptor.dart` with fields `path`, `feature`, `routeClass`, `library`, `isFeatureEntry`, `isRestorable` and `toJson`/`fromJson` matching the JSON in data-model.md §6; file holds a list of descriptors per library
- [X] T012 [P] Create `RouteArgument` model and `ArgumentCodec` enum (`primitive`, `enum`, `dateTime`, `list`, `map`, `json`, `inMemory`) in `db_navigator_generator/lib/src/route_argument.dart` with fields `name`, `type` (incl. nullability), `kind` (required positional / optional positional / required named / optional named), `defaultValueCode`, `codec`
- [X] T013 Create builder factories `dbRouteBuilder`, `dbRouteDescriptorBuilder` and `dbFeatureRoutesBuilder` in `db_navigator_generator/lib/builder.dart` (stub bodies) so `build.yaml` resolves
- [X] T014 [P] Create test helper `db_navigator_generator/test/support/build_harness.dart` wrapping `testBuilder` with in-memory `db_navigator` / `flutter` stub sources so output tests need no Flutter SDK

**Checkpoint**: `dart analyze` clean in both packages; typed API exported

---

## Phase 3: User Story 1 - Declare a typed route once (Priority: P1) 🎯 MVP

**Goal**: Annotate a page → generated typed route with compile-checked arguments, wired into the router with no hand-written builder

**Independent Test**: In the example app, declare one route with a required and a defaulted argument, run `build_runner`, navigate to it and read both arguments on the page with no cast (quickstart row 1)

### Tests for User Story 1 ⚠️ write first, confirm they fail

- [X] T015 [P] [US1] `test/db_typed_route_test.dart`: `push` calls `navigateTo` with `location == path` and `arguments` identical to the route instance; `destination` carries path and the route as arguments
- [X] T016 [P] [US1] `db_navigator_generator/test/route_generator_test.dart` + fixture `test/fixtures/confirm_load_screen.dart` (from contracts/generated-code.md): output has class `ConfirmLoadRoute` (widget name minus trailing `Screen`/`View`/`Page`, plus `Route`), `static const String path`, `static const DBRouteDefinition definition`, fields and constructor mirroring the page incl. default `this.note = ''`, `buildWidget`, `fromJson`/`toJson` for primitive, enum, `DateTime`, `List`, `Map<String, _>` and `toJson`+`fromJson` class arguments; `defaultRoute` present only when every argument is optional; a no-argument, no-result route still gets a typed class; `String? note` (required nullable) and `{String note = ''}` (optional defaulted) generate distinct constructors
- [X] T017 [US1] Generation-error tests in `db_navigator_generator/test/route_generator_test.dart`: `@DBRoute` on non-widget; widget with no unnamed constructor; path empty or not starting with `/`; feature empty; `Map` with non-`String` key; two annotated widgets in one library mapping to the same route class name
- [X] T018 [P] [US1] Compile-error harness `db_navigator_generator/test/compile_errors_test.dart` using `AnalysisContextCollection`: each fixture line tagged `// expect-error: <code>` must report that diagnostic; add fixtures `test/fixtures/compile_errors/missing_required_arg.dart`, `wrong_arg_type.dart`, `stale_constructor.dart` (page constructor changed, generated code not re-run → fails to compile)
- [X] T019 [P] [US1] `test/db_feature_routes_test.dart`: `supportRoute` true only for paths in `definitions`; `buildPage` uses `arguments` when it `is DBTypedRoute`, decodes when `is Map`, calls `defaultRoute` when `null`, else throws `PageNotFoundException`; page key is a `UniqueKey`; default page type is `DBMaterialPage`
- [X] T020 [P] [US1] `db_navigator_generator/test/feature_routes_builder_test.dart`: single feature `loads` emits `LoadsRoutes extends DBFeatureRoutes` with `const` constructor, `scopeName == 'loads'`, `initialDestination` = entry route path, `definitions` const list; a single-route feature is its own entry

### Implementation for User Story 1

- [X] T021 [US1] Implement `RouteArgumentReader` in `db_navigator_generator/lib/src/route_argument_reader.dart`: read the widget's unnamed constructor parameters except `key` (V1 element model: `ClassElement`, `ConstructorElement`, `ParameterElement`); copy `defaultValueCode` verbatim; classify codec for serialisable types (primitives `String`/`int`/`double`/`bool`, enums, `DateTime`, `List`/`Map<String, _>` of these, classes with `toJson()` + `factory fromJson(Map)`); reject non-`String` map keys via T010
- [X] T022 [US1] Implement `ArgumentCodecWriter` in `db_navigator_generator/lib/src/argument_codec_writer.dart`: enum → `name` / `values.byName`; `DateTime` → `toIso8601String()` / `DateTime.parse`; nested list/map element mapping; custom class → `toJson()` / `fromJson(...)` casting to the declared `fromJson` parameter type; `num` → `int`/`double` conversion; nullable handling. No `runtimeType` use (FR-008)
- [X] T023 [US1] Implement `RouteGenerator` (`GeneratorForAnnotation<DBRoute>`) in `db_navigator_generator/lib/src/route_generator.dart`: validate per data-model §1 (`path` "Required, starts with `/`"; `feature` "Required, non-empty"; `R` "Omitted → `void`"), emit the typed route class via `code_builder` + `dart_style` with `path`, `definition` (incl. `defaultRoute` when all args optional), fields, constructor, `fromJson`, `toJson`, `buildWidget`, `isRestorable`
- [X] T024 [US1] Wire builders in `db_navigator_generator/lib/builder.dart`: `dbRouteBuilder` = `SharedPartBuilder([RouteGenerator()], 'db_route')`; `dbRouteDescriptorBuilder` = a plain `Builder` writing `<input>.db_route.json` (list of `RouteDescriptor`) for every library with `@DBRoute`, sharing the annotation reading with `RouteGenerator` (DRY); outputs exactly as T002
- [X] T025 [US1] Implement `DBFeatureRoutes extends ScopedPageBuilder` in `lib/src/typed/db_feature_routes.dart` (`const` constructor with optional `onEntered` / `onExited` (`void Function(String scopeName)?`), abstract `definitions`, `onInitialDestinationEntered` / `onInitialDestinationExited` implemented as `onEntered?.call(scopeName)` / `onExited?.call(scopeName)` (required — they are abstract on `ScopedPageBuilder`), `supportRoute`, `buildPage` rules from T019, `pageFactory ?? DBMaterialPage`, `UniqueKey()` per page — research R8) and export it from `lib/db_navigator.dart`
- [X] T026 [US1] Implement `DBTypedRoute.push` in `lib/src/typed/db_typed_route.dart`: resolve delegate (root when `useRootDelegate`), call `navigateTo<Object?>(location: path, arguments: this)`, return result as `R?` (narrowing rule refined in T040)
- [X] T027 [US1] Implement `FeatureRoutesBuilder` in `db_navigator_generator/lib/src/feature_routes_builder.dart` and wire `dbFeatureRoutesBuilder`: read `lib/**.db_route.json`, group by `feature`, emit `lib/db_routes.g.dart` with one `<PascalCaseFeature>Routes` per feature and imports by library URI (contracts/generated-code.md Output 2)
- [X] T028 [US1] Example: add `example/lib/src/profile/profile_screen.dart` annotated `@DBRoute(path: '/profile', feature: 'profile')` with `required String userId` and `int visits = 0`; add `part 'profile_screen.g.dart';`; run `dart run build_runner build --delete-conflicting-outputs` in `example/`
- [X] T029 [US1] Example: register `const ProfileRoutes()` in `example/lib/src/example_app.dart` and push `ProfileRoute(userId: 'u1').push(context)` from `example/lib/src/home_screen.dart`
- [X] T030 [US1] Example widget test `example/test/typed_route_arguments_test.dart`: push omitting `visits` → page shows `0` (quickstart row 1, US1-AS4)

**Checkpoint**: US1 independently demonstrable — typed push with arguments, no hand-written builder

---

## Phase 4: User Story 2 - Await a typed result (Priority: P1)

**Goal**: `await XRoute(...).push(context)` returns `R?` with no cast; FR-012 result defects fixed

**Independent Test**: Route returning `bool`, close with `true`, caller receives `true` typed as `bool`; system back → `null` (quickstart rows 2, 3)

### Tests for User Story 2 ⚠️ write first, confirm they fail

- [X] T031 [P] [US2] `test/pop_result_tracker_test.dart`: `track(page)` returns one future per page instance; `complete(page, result)` "no-op if absent or already completed"; `completeAll()` "completes pending with `null`, then clears"
- [X] T032 [P] [US2] Extend `test/db_router_delegate_test.dart`: same path pushed twice → each caller gets its own result; `reset` then `dispose` → no exception; `closeUntilLast(resultMap: ...)` delivers results; legacy page closed with wrong type → assertion message names route, expected and actual types; via the T039 helper with `assertionsEnabled: false` → caller gets `null` and a `BDLogger` warning is logged
- [X] T033 [P] [US2] Extend `test/db_router_delegate_widget_test.dart`: system back on a pushed page completes the caller with `null` (US2-AS3); `onPopPage` resolves the popped page by identity, not name
- [X] T034 [P] [US2] Extend `db_navigator_generator/test/route_generator_test.dart`: output contains `static void close(BuildContext context, [R? result])`; `void` route emits `close(BuildContext context)`
- [X] T035 [P] [US2] Add compile-error fixtures `db_navigator_generator/test/fixtures/compile_errors/wrong_result_assignment.dart` (push result assigned to wrong type) and `wrong_close_type.dart` (`ConfirmLoadRoute.close(context, 'x')`)

### Implementation for User Story 2

- [X] T036 [US2] Create `PopResultTracker` in `lib/src/pop_result_tracker.dart` per data-model §7, keyed by `DBPage` identity
- [X] T037 [US2] Replace `Map<String, Completer<Object?>> _popResultTracker` in `lib/src/db_router_delegate.dart` with `PopResultTracker`; change the `@visibleForTesting popResultTracker` constructor parameter type from `Map<String, Completer<Object?>>?` to `PopResultTracker?` and update `test/db_router_delegate_test.dart` (the "should not update page stack and popResultTracker" case) to inject a `PopResultTracker`
- [X] T038 [US2] In `lib/src/db_router_delegate.dart`: `reset` calls `completeAll()`; `dispose` is safe after `reset`; `closeUntilLast` forwards `resultMap` to `closeUntil`; `onPopPage` matches with `identical(page, route.settings)`
- [X] T039 [US2] Create result-narrowing helper in `lib/src/result_type_check.dart` taking `{bool assertionsEnabled = kDebugMode}` so tests can drive both paths: `is T` → value; otherwise debug assert naming route + expected + actual type, release returns `null` + `BDLogger().warning(...)`; use it in `DBRouterDelegate.navigateTo<T>` (store `Completer<Object?>`)
- [X] T040 [US2] Use the T039 helper in `DBTypedRoute.push` in `lib/src/typed/db_typed_route.dart` (DRY — one narrowing rule)
- [X] T041 [US2] Emit `static void close(BuildContext context, [R? result])` in `db_navigator_generator/lib/src/route_generator.dart`
- [X] T042 [US2] Example: add `example/lib/src/profile/confirm_logout_screen.dart` as `@DBRoute<bool>(path: '/profile/logout', feature: 'profile')`, closing via `ConfirmLogoutRoute.close(context, true)`; mark `ProfileScreen` `isFeatureEntry: true`; regenerate
- [X] T043 [US2] Example test `example/test/typed_result_test.dart`: quickstart rows 2 (gets `true` as `bool`), 3 (system back → `null`), 6 (same route pushed twice, each caller gets own result)
- [X] T044 [US2] Confirm `lib/src/db_router_delegate.dart` stays under 800 lines after extraction

**Checkpoint**: US1 + US2 = full typed push-and-await; FR-012 defects closed

---

## Phase 5: User Story 3 - Register a feature's routes with no hand-written builder (Priority: P2)

**Goal**: One generated `const` unit per feature, usable in root and nested navigators, with scope callbacks and custom page factories

**Independent Test**: Register two generated features in both the root and a nested navigator; all routes resolve (quickstart row 4)

### Tests for User Story 3 ⚠️ write first, confirm they fail

- [X] T045 [P] [US3] Extend `db_navigator_generator/test/feature_routes_builder_test.dart`: two features emit two classes; duplicate path across any two declarations → error naming both classes and libraries (US3-AS2); multi-route feature with zero or multiple `isFeatureEntry: true` → error naming feature + routes ("Exactly one per feature when the feature has >1 route")
- [X] T046 [P] [US3] Extend `test/db_feature_routes_test.dart`: `onEntered` / `onExited` called with `scopeName`; definition `pageFactory` used instead of `DBMaterialPage`
- [X] T047 [P] [US3] Extend `db_navigator_generator/test/route_generator_test.dart`: `pageFactory: fadeInFadeOutPage` (top-level or static) is referenced in `definition`; a non-top-level/non-static reference → actionable error

### Implementation for User Story 3

- [X] T048 [US3] Add duplicate-path and entry-count validation to `db_navigator_generator/lib/src/feature_routes_builder.dart` using T010 messages
- [ ] T049 [US3] Example: pass `onEntered` to `ProfileRoutes` in `example/lib/src/example_app.dart` to run the feature's dependency setup and log scope entry; `onExited` logs scope exit (H2 — DI lives in `onEntered`)
- [X] T050 [US3] Read and validate `pageFactory` in `db_navigator_generator/lib/src/route_generator.dart` and emit it into `definition`
- [ ] T051 [US3] Example: add second generated feature `settings` with two routes (one entry) in `example/lib/src/settings/`, one using a page factory from `example/lib/src/page_transitions/`; regenerate
- [ ] T052 [US3] Example: register `ProfileRoutes` and `SettingsRoutes` in the root delegate (`example/lib/src/example_app.dart`) and in the nested delegate (`example/lib/src/nested/nested_home_screen.dart`)
- [ ] T053 [US3] Example test `example/test/feature_routes_test.dart`: quickstart row 4 — every route of both features resolves in root and nested navigators

**Checkpoint**: Feature registration fully generated; duplicate/entry errors actionable

---

## Phase 6: User Story 4 - Adopt incrementally with a migration guide (Priority: P2)

**Goal**: Legacy and generated routes coexist; an existing app upgrades with zero changes; a guide covers every TEGFlutterApp pattern

**Independent Test**: Example app keeps a legacy feature next to generated ones, navigating both ways with results; a newcomer migrates one feature using only the guide in <30 min

### Tests for User Story 4 ⚠️ write first, confirm they fail

- [ ] T054 [P] [US4] `test/db_router_delegate_interop_test.dart`: legacy page → generated route → legacy page in one `DBRouterDelegate`, results delivered in both directions and either push order (FR-007)
- [X] T055 [P] [US4] Example test `example/test/mixed_navigation_test.dart`: quickstart row 5

### Implementation for User Story 4

- [X] T056 [US4] Example: keep the legacy feature (`example/lib/src/home_page_builder.dart`, `example/lib/src/ui/screen_page_builder.dart`) unchanged; add a push from `ProfileScreen` to a legacy route and from the legacy screen to `ConfirmLogoutRoute`, awaiting results
- [ ] T057 [US4] Write `doc/migration-guide.md`: setup (from contracts/build-config.md); before/after for plain route, route with arguments, modal / bottom sheet (typed `destination` + app-owned `showModal` overload — research R10), nested / tab navigation, callback / service arguments (in-memory only — FR-009); `AnalyticsPageBuilder` and per-feature dependency setup → `onEntered`/`onExited`; `fadeInFadeOutPage` → `pageFactory`; per-feature checklist; verification steps; rollback
- [ ] T058 [P] [US4] Add typed-routes quick-start to `README.md` (install, annotate, generate, register, push/await)
- [ ] T059 [US4] SC-004 check per quickstart §4: point TEGFlutterApp's `db_navigator` at this branch with no other edits, run `flutter pub get && flutter analyze && flutter test`, record result (any test passing `popResultTracker:` is an expected, test-only break — list them), revert the pubspec
- [ ] T060 [US4] SC-005 dry run: a developer new to the package migrates one example feature using only `doc/migration-guide.md`; time it (<30 min) and fold gaps back into the guide — **blocker: needs a named volunteer before T057 finishes**

**Checkpoint**: Mixed app works; guide ready for the TEGFlutterApp migration spec

---

## Phase 7: User Story 5 - Clear errors for unrestorable arguments (Priority: P3)

**Goal**: Non-serialisable arguments are flagged in-memory at generation time; restoration and deep links behave predictably

**Independent Test**: Declare a route with a callback argument; generated output marks it in-memory, and a restore with it mid-stack restores up to it (quickstart row 10)

### Tests for User Story 5 ⚠️ write first, confirm they fail

- [X] T061 [P] [US5] Extend `db_navigator_generator/test/route_generator_test.dart`: `VoidCallback onDone` → `isRestorable` false, `toJson()` returns `null`, exact comment line `// In-memory only (onDone: VoidCallback): not restored, not deep-linkable.` above the class; descriptor `isRestorable: false`; class with `toJson` but no `fromJson` (or reverse) → error naming parameter + type
- [ ] T062 [P] [US5] Extend `test/db_route_information_parser_test.dart`: `restoreRouteInformation` state is `metadata.toJson()` (a `Map`); history truncated at the first destination whose arguments are not JSON-primitive (generated in-memory route, or legacy object without `HasToJson`)
- [ ] T063 [P] [US5] Extend `test/destination_test.dart`: `Destination.fromRouteInformation` accepts a `Map` state
- [ ] T064 [P] [US5] Extend `test/destination_argument_converter_test.dart`: `pojoToJson(DBTypedRoute)` returns its `toJson()` with no type-name key
- [ ] T065 [P] [US5] `test/db_router_delegate_not_found_test.dart`: unknown deep-link path with `notFoundPageFactory` → not-found page pushed; without → stack kept + `BDLogger` warning; generated route whose `decode` throws → same handling

### Implementation for User Story 5

- [X] T066 [US5] Classify every other type as `ArgumentCodec.inMemory` and add the `toJson`/`fromJson` mismatch check in `db_navigator_generator/lib/src/route_argument_reader.dart`
- [X] T067 [US5] Emit in-memory routes in `db_navigator_generator/lib/src/route_generator.dart`: the single comment line, `isRestorable => false`, `toJson() => null`, descriptor `isRestorable: false`
- [ ] T068 [US5] `lib/src/db_route_information_parser.dart`: store `metadata.toJson()` in `RouteInformation.state`, cutting history at the first non-restorable destination (research R6)
- [ ] T069 [US5] `lib/src/destination.dart`: accept `Map` state in `fromRouteInformation`
- [ ] T070 [US5] `lib/src/destination_argument_converter.dart`: add `DBTypedRoute` branch in `pojoToJson`
- [ ] T071 [US5] `lib/src/db_router_delegate.dart`: optional `notFoundPageFactory: DBPage Function(Destination)?` used by `setInitialRoutePath` / `setNewRoutePath` when no builder supports the path or decode fails; otherwise keep stack and `BDLogger().warning(...)` (FR-015, research R9)
- [ ] T072 [US5] Example: add an in-memory route with a `VoidCallback` argument under `example/lib/src/settings/` and a not-found page passed to the root delegate; regenerate
- [ ] T073 [US5] Example tests `example/test/restoration_test.dart`: quickstart rows 10 (restore stops at in-memory route) and 11 (unknown deep link with / without not-found page)
- [ ] T074 [US5] Quickstart row 12: `flutter build apk --obfuscate --split-debug-info=build/sym` in `example/`, restore on device/emulator, confirm argument values identical (FR-008)

**Checkpoint**: All five stories independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T075 Bump root `pubspec.yaml` to `1.1.0`; add `CHANGELOG.md` 1.1.0 entry: typed routes, generator package, FR-012 fixes, not-found fallback, the restoration-state behaviour change (object → JSON), and the test-only `popResultTracker` parameter type change (`Map` → `PopResultTracker`)
- [ ] T076 [P] SC-007: time a clean `dart run build_runner build --delete-conflicting-outputs` in `example/` with and without `db_navigator_generator`; confirm <10% extra
- [ ] T077 Run quickstart §1–3 gates: `flutter analyze` + `flutter test` (root, `example/`), `dart analyze` + `dart test` (`db_navigator_generator/`); SC-002: `grep -rnE '\bas [A-Z]' example/lib` finds no argument/result casts in code using generated routes
- [ ] T078 Constitution IV sweep: no doc comments beyond the public-API exception; only the FR-009 comment in generated output
- [ ] T079 Code review (pr-review-toolkit:code-reviewer) and security review of the branch diff; fix CRITICAL/HIGH
- [ ] T080 Open PR against `release/0.2.0` (not `master`)
- [ ] T081 [P] Raise follow-up ticket: port generator to analyzer 8 element model once TEGFlutterApp upgrades freezed

---

## Dependencies & Execution Order

### Flow

```
Setup ─► Foundational ─► US1 ─┬─► US2 ─┐
                              ├─► US3 ─┼─► US4 ─► Polish
                              └─► US5 ─┘
```

| Story | Depends on | Why |
|-------|-----------|-----|
| US1 (P1) | Foundational | — |
| US2 (P1) | US1 | `close` emission + example result route need the generator |
| US3 (P2) | US1 | Extends the aggregate builder and `DBFeatureRoutes` |
| US4 (P2) | US1–US3 (US5 for guide's callback section) | Guide covers all patterns |
| US5 (P3) | US1 | Extends reader/generator; runtime parts (T068–T071) only need Foundational |

**Slice-first option**: FR-012 runtime fixes (T031–T033, T036–T039) touch no generator code and can start right after Foundational as their own slice (plan → Delivery Flow).

### Within each story

Tests → generator model/reader → writer/generator → runtime → example → example test.

### Blockers

| Item | Countermeasure |
|------|----------------|
| `build_test` compatibility (T005) | Resolve before T014; fall back to an older `testBuilder` line |
| SC-005 volunteer (T060) | Name someone before T057 starts |
| T059 needs TEGFlutterApp checkout | Already under `teg/projects/` |

---

## Parallel Examples

```text
# Foundational
T006 db_route.dart | T007 db_route_definition.dart | T008 db_typed_route.dart
T010 generation_errors.dart | T011 route_descriptor.dart | T012 route_argument.dart | T014 build_harness.dart

# US1 tests
T015 db_typed_route_test | T016 route_generator_test | T018 compile_errors_test | T019 db_feature_routes_test | T020 feature_routes_builder_test

# US2 tests
T031 pop_result_tracker_test | T032 delegate_test | T033 delegate_widget_test | T035 compile fixtures

# US5 runtime (independent of generator work)
T062 parser_test | T063 destination_test | T064 converter_test | T065 not_found_test
```

---

## Implementation Strategy

### MVP — US1 + US2 (both P1)

1. Setup → Foundational
2. US1 → validate quickstart row 1
3. US2 → validate rows 2, 3, 6–9
4. **Stop and demo**: typed push-and-await on one feature

### Incremental delivery

| Increment | Adds | Validates |
|-----------|------|-----------|
| 1 | US1 + US2 | Rows 1–3, 6–9 |
| 2 | US3 | Row 4 |
| 3 | US5 | Rows 10–12 |
| 4 | US4 | Row 5, SC-004, SC-005 |
| 5 | Polish | SC-007, PR |

Keep WIP to one story at a time; finish its checkpoint before pulling the next.

---

## Notes

- [P] = different files, no dependency on incomplete tasks
- Generated `*.g.dart` / `db_routes.g.dart` come from `build_runner` only — never hand-edit
- Commit after each task or logical group, conventional commit messages
