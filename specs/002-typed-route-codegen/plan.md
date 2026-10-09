# Implementation Plan: Typed Route Code Generation

**Branch**: `002-typed-route-codegen` | **Date**: 2026-10-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-typed-route-codegen/spec.md`

## Summary

Add a `@DBRoute<R>` annotation on page widgets and a companion `db_navigator_generator` package. Per page, it generates a typed route class (compile-checked arguments and result, obfuscation-safe JSON codec). Per feature, it generates a `const` `DBFeatureRoutes` page builder that replaces the hand-written one. The same release fixes the four result-handling defects (FR-012), adds a not-found fallback (FR-015), makes router restoration JSON-safe with the in-memory cut-off, and ships a migration guide. It is additive: v1.1.0 on `release/0.2.0`, no deprecations.

## Technical Context

**Language/Version**: Dart ≥3.1 (runtime pkg) / ≥3.6 (generator); Flutter ≥3.13; validated on app pin Flutter 3.38.8 / Dart 3.10.7

**Primary Dependencies**: runtime — `flutter`, `bdlogging`, `collection`, `json_annotation` (unchanged). Generator — `analyzer >=6.9 <8`, `source_gen ^2.0.0`, `build ^2.4.1`, `code_builder`, `dart_style`

**Storage**: N/A (navigation state persisted through Flutter router restoration only)

**Testing**: `flutter_test` + `mocktail` (runtime); `build_test` output tests + analyzer-driven compile-error fixtures (generator); example app widget/integration tests

**Target Platform**: Flutter apps (iOS, Android, web); generator runs on the Dart VM under `build_runner`

**Project Type**: Flutter library + build_runner code generator (two packages, one repo)

**Performance Goals**: generation adds <10% to a clean `build_runner build` in the example app (SC-007)

**Constraints**: zero required changes for existing apps (SC-004); no runtime-type-name serialisation (FR-008); must resolve with TEGFlutterApp's lock (analyzer 7.6.0, source_gen 2.0.0, build 2.5.4, freezed 2.5.8)

**Scale/Scope**: built for TEGFlutterApp scale — 34 builders, 71 paths, 22 argument classes; ~10 new runtime files, ~8 generator files

No NEEDS CLARIFICATION remain — all resolved in [research.md](./research.md).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Constraint | Pre-research | Post-design | Notes |
|---|---|---|---|
| I. KISS / YAGNI | ⚠️ Justified | ⚠️ Justified | New package + two-phase builder → Complexity Tracking. Rejected: presentation enum, global registry, deprecations, guards, path params |
| II. DRY | ✅ | ✅ | Removes 34 copy-pasted builders; one codec writer per type kind; `DBTypedRoute` base owns shared `push` logic |
| III. SOLID | ✅ | ✅ | Open/Closed: `DBFeatureRoutes` is a new `DBPageBuilder` subtype, no edits to existing builders. SRP: `PopResultTracker` extracted from the 654-line delegate. DIP: generated code depends on `DBTypedRoute` / `DBRouteDefinition` abstractions |
| IV. Self-documenting | ✅ | ✅ | Only the 1-line in-memory marker comment in generated output (FR-009 requires it); public API docs per the lint exception |
| Tech: SDK as declared in pubspec | ⚠️ | ⚠️ | FR-014 raises floors to Dart 3.1 / Flutter 3.13. Constitution text quotes `>=3.0.0` → **PATCH amendment needed** (see Risks) |
| Tech: `flutter analyze` clean | ✅ | ✅ | Quickstart §1 gate |
| Tech: `*.g.dart` only from build_runner | ✅ | ✅ | Generator output is `*.g.dart` / `db_routes.g.dart` |
| Tech: new runtime deps justified | ✅ | ✅ | None added; generator deps are dev-only |
| Workflow: tests for new behaviour | ✅ | ✅ | Runtime, generator and example tests planned |
| Workflow: CHANGELOG + semver | ✅ | ✅ | Additive → 1.1.0 |

**Gate result**: PASS — both ⚠️ items are justified below or tracked as a follow-up.

## Project Structure

### Documentation (this feature)

```text
specs/002-typed-route-codegen/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── public-api.md
│   ├── generated-code.md
│   └── build-config.md
└── tasks.md             # /speckit-tasks (not created here)
```

### Source Code (repository root)

```text
lib/
├── db_navigator.dart                     # + new exports
└── src/
    ├── db_router_delegate.dart           # FR-012 fixes, notFoundPageFactory
    ├── db_route_information_parser.dart  # JSON state + in-memory cut-off
    ├── destination.dart                  # Map state in fromRouteInformation
    ├── destination_argument_converter.dart  # DBTypedRoute branch in pojoToJson
    ├── pop_result_tracker.dart           # NEW
    └── typed/                            # NEW
        ├── db_route.dart                 # annotation
        ├── db_typed_route.dart
        ├── db_route_definition.dart
        └── db_feature_routes.dart

db_navigator_generator/                   # NEW package
├── pubspec.yaml
├── build.yaml
├── lib/
│   ├── builder.dart                      # builder factories
│   └── src/
│       ├── route_generator.dart          # phase 1: typed route part + descriptor
│       ├── route_argument_reader.dart    # constructor → RouteArgument
│       ├── argument_codec_writer.dart    # toJson/fromJson per codec kind
│       ├── route_descriptor.dart         # *.db_route.json model
│       ├── feature_routes_builder.dart   # phase 2: lib/db_routes.g.dart
│       └── generation_errors.dart        # FR-005 messages
└── test/
    ├── route_generator_test.dart
    ├── feature_routes_builder_test.dart
    ├── compile_errors_test.dart
    └── fixtures/

test/                                     # runtime tests (existing + new)
├── pop_result_tracker_test.dart
├── db_feature_routes_test.dart
├── db_typed_route_test.dart
└── db_router_delegate_*_test.dart        # extended for FR-012 / FR-015

example/                                  # every generated capability (FR-011)
└── lib/src/ ...                          # one legacy + two generated features, nested tab

doc/migration-guide.md                    # NEW (FR-010)
README.md, CHANGELOG.md                   # quick-start, 1.1.0 entry
```

**Structure Decision**: The runtime package stays at the repo root (unchanged consumer URL). The generator is a sibling package in `db_navigator_generator/`, consumed via git `path:`. This mirrors the `json_annotation` / `json_serializable` split.

## Delivery Flow

```
[Runtime fixes FR-012/015 + restoration] ──┐
                                           ├─► [Example app + generator tests] ─► [Guide + README + CHANGELOG] ─► [SC-004 check on TEGFlutterApp]
[Runtime typed API] ─► [Generator ph1] ─► [Generator ph2] ┘
```

Runtime fixes are independent of codegen, so they can flow first as their own slice.

## Dependencies & Blockers

| Item | Type | Countermeasure |
|------|------|----------------|
| TEGFlutterApp lock (analyzer <8 via freezed 2.5.8) | Hard constraint | Generator pinned to V1 element model; verify in Quickstart §4 |
| `build_test` version compatible with build 2.5 / analyzer <8 | Unknown at plan time | Choose at implementation; fall back to `testBuilder` from an older line |
| SC-005 needs a person new to the package | People dependency | Line up a volunteer before the guide task starts |
| PR target `release/0.2.0`, not `master` | Process | Raise the PR against `release/0.2.0` |

## Risks

- **Analyzer 8 port**: once the app upgrades freezed, the generator needs a new-element-model release. It is not blocking now. → Follow-up ticket.
- **Restoration behaviour change**: router restoration state moves from an object to JSON. Apps relying on today's (broken) object state could see different restored stacks. → Covered by Quickstart rows 10–12 and called out in CHANGELOG.
- **Constitution drift**: Technical Constraints still quote Dart/Flutter `>=3.0.0`. → PATCH amendment PR alongside this work.
- **Delegate size**: 654 lines → extracting `PopResultTracker` keeps it under 800.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Second package (`db_navigator_generator`) | Keeps analyzer/build out of every consumer's runtime graph | Builder inside `db_navigator` forces analyzer onto all apps as a runtime dep |
| Two-phase builder (per-library + aggregate) | Feature units span many files; duplicate-path check needs a global view | Single aggregate builder resolves every library each build (breaks SC-007); hand-listed routes reintroduce manual registration (FR-003) |
| `DBRouteDefinition` indirection | Lets a `const` feature unit reference per-route decoders without a runtime registry | A runtime-type-keyed registry breaks under obfuscation (FR-008) |
