# Contract: Consumer Setup & Builder Configuration

## Consumer `pubspec.yaml`

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

Run: `dart run build_runner build --delete-conflicting-outputs`

## `db_navigator_generator/build.yaml`

| Builder | Input | Output | Applies |
|---------|-------|--------|---------|
| `db_route` | `.dart` | `.db_route.g.part` (combined into `.g.dart`), `.db_route.json` | `auto_apply: dependents`, `build_to: cache` |
| `db_feature_routes` | `lib/$lib$` | `lib/db_routes.g.dart` | `auto_apply: dependents`, `build_to: source`, `required_inputs: [".db_route.json"]` |

`db_route` uses source_gen's shared part builder, so it shares `*.g.dart` with json_serializable / freezed.

## Version constraints

| Package | SDK | Key constraints |
|---------|-----|-----------------|
| `db_navigator` 1.1.0 | `>=3.1.0 <4.0.0`, Flutter `>=3.13.0` | unchanged runtime deps |
| `db_navigator_generator` 1.1.0 | `>=3.6.0 <4.0.0` | `analyzer >=6.9.0 <8.0.0`, `source_gen ^2.0.0`, `build ^2.4.1` |

Must resolve alongside TEGFlutterApp's lock: analyzer 7.6.0, source_gen 2.0.0, build 2.5.4, build_runner 2.5.4, freezed 2.5.8, json_serializable 6.9.5.
