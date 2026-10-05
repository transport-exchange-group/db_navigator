# Feature Specification: Typed Route Code Generation

**Feature Branch**: `002-typed-route-codegen`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "Improve db_navigator: (1) cut the boilerplate needed to use db_navigator inside TEGFlutterApp, (2) make parameters passed to navigation routes strongly typed — likely via code generation. Research auto_route and go_router to pick a direction, surface other improvements. Scope: upgrade the package developer experience and produce a detailed migration guide. Migrating TEGFlutterApp itself is a separate spec."

## Context & Direction

Research (2026-10-05) compared three directions:

| Option | Verdict | Reason |
|--------|---------|--------|
| Adopt auto_route | Rejected | Replaces the router core, nested navigation and every call site; three breaking majors in ~2 years |
| Adopt go_router (+ builder) | Rejected | ~205 call sites to rewrite; URL-first model clashes with push-and-await-result; latest major needs a newer Flutter than the app's pinned version; complex objects cannot travel in a deep link |
| **Own generator inside db_navigator, borrowing the typed-route pattern** | **Chosen** | Additive, adoptable one feature at a time, keeps push-with-result semantics and existing restoration |

Baseline evidence from TEGFlutterApp today: 34 page builders (largely copy-pasted), 71 path constants, 22 argument classes, 34 forced casts of untyped arguments, and 3–4 files / ~40–60 lines touched to add one route.

## User Scenarios & Testing *(mandatory)*

The "user" throughout is an app developer consuming db_navigator.

### User Story 1 - Declare a typed route once (Priority: P1)

A developer declares a route, its arguments and its result type in one place. The package generates everything else needed to navigate to it: the destination, argument serialisation and the page-builder wiring.

**Why this priority**: This is the core boilerplate and type-safety win; everything else builds on it.

**Independent Test**: In the package example app, declare one route with two arguments (one required, one with a default), run generation, navigate to it and read the arguments on the page without any cast.

**Acceptance Scenarios**:

1. **Given** a declared route with a required argument, **When** a developer navigates to it without supplying that argument, **Then** the project fails to compile.
2. **Given** a declared route with an argument of type A, **When** a developer passes a value of another type, **Then** the project fails to compile.
3. **Given** a declared route, **When** generation runs, **Then** no hand-written page builder, path-matching check, argument cast or argument registration is needed for that route.
4. **Given** an argument with a default value, **When** the developer omits it, **Then** the page receives the default.

---

### User Story 2 - Await a typed result (Priority: P1)

A developer navigates to a route and awaits a result whose type is declared with the route, without casting.

**Why this priority**: Push-and-await-result is used heavily in the app and is the main reason the router alternatives were rejected; typing it closes the second half of the type-safety gap.

**Independent Test**: Declare a route returning a boolean, navigate, close with `true`, and confirm the caller receives `true` typed as a boolean.

**Acceptance Scenarios**:

1. **Given** a route declared to return type R, **When** the page closes with a value of type R, **Then** the caller receives it typed as R.
2. **Given** a route declared to return type R, **When** the page is closed with a value not of type R, **Then** the project fails to compile wherever the close is expressed through the generated API.
3. **Given** the page is dismissed without a result (e.g. system back), **Then** the caller receives "no result" rather than an error.

---

### User Story 3 - Register a feature's routes with no hand-written builder (Priority: P2)

A developer groups a feature's routes and registers them with the router as one generated unit, rather than writing and repeating a page builder per feature and per tab.

**Why this priority**: Removes the largest volume of copy-paste (34 builders, builder lists repeated across tab delegates) but depends on Story 1.

**Independent Test**: In the example app, register two features through their generated units in both the root and a nested navigator; all routes resolve.

**Acceptance Scenarios**:

1. **Given** a feature with several declared routes, **When** generation runs, **Then** a single registrable unit is produced for that feature.
2. **Given** two features declare the same path, **When** generation runs, **Then** it fails with a message naming both declarations.
3. **Given** a developer needs custom per-feature behaviour (scope name, dependency setup, page transition), **Then** it can be expressed on the declaration without writing a full builder.

---

### User Story 4 - Adopt incrementally with a migration guide (Priority: P2)

A developer migrates an existing app one feature at a time, guided by a step-by-step document, while unmigrated features keep working unchanged.

**Why this priority**: Makes the follow-up TEGFlutterApp migration spec low-risk and plannable.

**Independent Test**: In the example app, keep one feature on the existing API and one on generated routes; both navigate correctly and can navigate to each other. A developer new to the package migrates one sample feature using only the guide.

**Acceptance Scenarios**:

1. **Given** an app using the existing API, **When** it upgrades to the new package version without other changes, **Then** it compiles and behaves as before (deprecation warnings allowed).
2. **Given** a mixed app, **When** a generated route navigates to a legacy route (and vice versa), **Then** navigation and results work.
3. **Given** the migration guide, **Then** it covers: setup, before/after for each existing pattern found in TEGFlutterApp (plain route, route with arguments, modal/bottom sheet, nested/tab navigation, routes with callbacks or services in their arguments), a per-feature checklist, verification steps and rollback.

---

### User Story 5 - Clear errors for unrestorable arguments (Priority: P3)

When a route's arguments cannot be saved for state restoration or deep links (e.g. callbacks, services), the developer is told at generation time how that route will behave, instead of discovering it at runtime.

**Why this priority**: 22 app argument classes carry callbacks/services; silent failures here are today's runtime risk, but this is refinement on top of Stories 1–3.

**Independent Test**: Declare a route with a callback argument and observe the generator's outcome as defined in FR-009.

**Acceptance Scenarios**:

1. **Given** a route whose arguments are all serialisable, **Then** it survives state restoration with identical argument values.
2. **Given** a route with a non-serialisable argument, **Then** behaviour follows FR-009 and is documented in the generated output.

### Edge Cases

- App restored while routes with in-memory-only arguments are on the stack: the restored stack must omit or fall back for those routes in a documented way, never crash.

- Same route pushed twice in one stack: both callers must receive their own results (today the first never completes).
- Router reset then disposed: must not throw (today it does).
- Generation run on a route whose page constructor changed: stale generated code must fail to compile, not misbehave at runtime.
- Release builds with obfuscation: argument serialisation must not rely on runtime type names.
- Deep link to an unknown path: a defined fallback is used instead of silently ignoring it.
- Nullable argument vs optional argument: both are expressible and distinct.
- Route with no arguments and no result: still gets a generated typed entry point.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The package MUST let a developer declare a route's path, arguments (names, types, required/optional, defaults) and result type in a single declaration.
- **FR-002**: The package MUST generate, from each declaration, a typed navigation entry point whose arguments and result are checked at compile time.
- **FR-003**: The package MUST generate argument serialisation and its registration for each route; developers MUST NOT write manual registration or casts for generated routes.
- **FR-004**: The package MUST generate, per feature, a single registrable unit that replaces the hand-written page builder, usable in both root and nested navigators.
- **FR-005**: Generation MUST fail with an actionable message on duplicate paths, unsupported argument types, or invalid declarations.
- **FR-006**: The existing public navigation API MUST keep working unchanged in the release that introduces generation; superseded APIs MAY be marked deprecated but MUST NOT be removed in that release.
- **FR-007**: Generated and legacy routes MUST interoperate in the same navigator, including results.
- **FR-008**: Argument serialisation MUST NOT depend on runtime type names, so it works with obfuscated release builds.
- **FR-009**: Routes with non-serialisable arguments (e.g. callbacks, services) MUST be allowed, and MUST be marked by the generator as in-memory only: they are excluded from state restoration and deep links, and this is stated in the generated output and the migration guide.
- **FR-010**: The package MUST ship a migration guide meeting User Story 4, scenario 3, plus an updated README with a quick-start for typed routes.
- **FR-011**: The example app MUST demonstrate every generated-route capability, and the generator MUST have automated tests over its output.
- **FR-012**: This spec MUST resolve the known result-handling defects: results lost when the same path is pushed twice, crash on dispose after reset, `closeUntilLast` ignoring supplied results, and runtime crashes from mistyped results.
- **FR-013**: The work MUST be based on `release/0.2.0` (package v1.0.0), the line TEGFlutterApp consumes; the resulting release MUST be versioned above 1.0.0.
- **FR-014**: The package's declared minimum Flutter/Dart versions MUST match the APIs it uses and MUST NOT exceed the version TEGFlutterApp is pinned to.

### Key Entities

- **Route declaration**: A developer-authored description of one route — path, arguments, result type, optional presentation (transition, modal).
- **Typed route**: The generated, compile-time-checked entry point for navigating to one route and awaiting its result.
- **Feature route group**: The generated registrable unit bundling one feature's routes, scope name and dependency setup.
- **Route arguments**: The values a route needs; either serialisable (restorable, deep-linkable) or in-memory only.
- **Migration guide**: The document mapping every current usage pattern to its generated equivalent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Adding a new route with arguments touches **1 developer-authored file** (down from 3–4) and **≤15 hand-written lines** (down from ~40–60).
- **SC-002**: **Zero** casts of navigation arguments or results are needed in code using generated routes (baseline: 34+ in the app).
- **SC-003**: **100%** of argument/result type mismatches on generated routes are caught at compile time in the generator test suite.
- **SC-004**: An existing app upgrades to the new version with **zero** required code changes.
- **SC-005**: A developer unfamiliar with the package migrates one sample feature using only the guide in **under 30 minutes**.
- **SC-006**: The migration guide covers **100%** of the usage patterns catalogued in TEGFlutterApp (plain, arguments, modal, nested/tab, callback/service arguments).
- **SC-007**: Generation adds **under 10%** to a clean code-generation run in the example app.

## Assumptions

- Code generation runs via the standard Dart build tooling already used by the package; language-level macros are not available (cancelled upstream).
- Generation dependencies are development-only; no significant new runtime dependency is added.
- The new capability ships as an additive minor release; removal of deprecated APIs is a later major.
- Out of scope for this spec (candidate follow-ups): route guards/redirects, path and query parameter parsing, testing helpers / fake navigator, nested-navigation widget fixes, and migrating TEGFlutterApp itself.
- The 404/unknown-deep-link fallback is limited to a defined, documented default behaviour; richer handling belongs with guards/redirects.
