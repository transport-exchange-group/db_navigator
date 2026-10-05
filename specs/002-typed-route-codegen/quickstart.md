# Quickstart: Validating Typed Route Code Generation

Runnable checks that prove the feature end-to-end. Shapes: [contracts/](./contracts/). Entities: [data-model.md](./data-model.md).

## Prerequisites

- Flutter 3.38.8 via fvm (TEGFlutterApp's pin): `fvm use 3.38.8`
- Repo root: `db_navigator/`

## 1. Package gates

```bash
flutter pub get && flutter analyze && flutter test
cd db_navigator_generator && dart pub get && dart analyze && dart test
```

**Expect**: zero analyzer errors/warnings; all tests pass, including compile-error fixtures (SC-003) and output tests (FR-011).

## 2. Example app generation

```bash
cd example && flutter pub get
time dart run build_runner build --delete-conflicting-outputs
```

**Expect**: `lib/db_routes.g.dart` plus a `*.g.dart` per annotated page. Compare timing with generation disabled — under 10% extra (SC-007).

## 3. Scenario checks (example app, `flutter test integration_test` or manual run)

| # | Scenario | Expected | Spec ref |
|---|----------|----------|----------|
| 1 | Push typed route, omit defaulted arg | page shows default | US1-AS4 |
| 2 | Push route returning `bool`, close with `true` | caller gets `true` as `bool` | US2-AS1 |
| 3 | System back on typed route | caller gets `null` | US2-AS3 |
| 4 | Two features registered in root + nested delegate | all routes resolve | US3 |
| 5 | Legacy page → generated route → legacy page, with results | all results delivered | US4-AS2, FR-007 |
| 6 | Same route pushed twice, close both | each caller gets own result | FR-012 |
| 7 | `reset` then dispose delegate | no exception | FR-012 |
| 8 | `closeUntilLast(resultMap: ...)` | results delivered | FR-012 |
| 9 | Legacy page closes with wrong type (debug) | assertion names route + both types | FR-012 |
| 10 | Restore with in-memory route mid-stack | stack restored up to it | FR-009, US5 |
| 11 | Deep link to unknown path, with / without not-found page | not-found shown / stack kept + warning | FR-015 |
| 12 | `flutter build apk --obfuscate --split-debug-info=build/sym` then restore | arguments identical | FR-008 |

## 4. Backward compatibility (SC-004)

```bash
cd ../TEGFlutterApp
# point db_navigator at this branch (git ref or local path), no other edits
flutter pub get && flutter analyze && flutter test
```

**Expect**: resolves alongside analyzer 7.6 / freezed 2.5.8; compiles; tests pass. Revert the pubspec afterwards.

## 5. Migration guide dry run (SC-005, SC-006)

- Someone new to the package migrates one example feature using only `doc/migration-guide.md`. **Expect**: < 30 min.
- Guide has a before/after for: plain route, route with arguments, modal / bottom sheet, nested / tab navigation, callback / service arguments.
