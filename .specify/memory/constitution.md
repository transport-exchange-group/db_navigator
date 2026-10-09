<!--
Sync Impact Report
- Version change: 1.0.0 → 1.0.1 (PATCH, 2026-10-07)
  - Technical Constraints: SDK floors raised to Dart >=3.1.0 <4.0.0, Flutter >=3.13.0 (FR-014)
  - Development Workflow: tests live in the owning package's test/ (root,
    db_navigator_generator/, example/)
- Previous: (unversioned template) → 1.0.0
- Principles defined:
  - [PRINCIPLE_1_NAME] → I. Keep It Simple (KISS)
  - [PRINCIPLE_2_NAME] → II. Don't Repeat Yourself (DRY)
  - [PRINCIPLE_3_NAME] → III. SOLID Design
  - [PRINCIPLE_4_NAME] → IV. Self-Documenting Code
  - [PRINCIPLE_5_NAME] → removed (four principles requested)
- Added sections: Technical Constraints, Development Workflow, Governance
- Removed sections: none
- Follow-up TODOs: none
- Decision: Principle IV vs `public_member_api_docs` / `package_api_docs` lints resolved
  by keeping a narrow public-API doc-comment exception (confirmed by owner 2026-10-05).
-->

# db_navigator Constitution

## Core Principles

### I. Keep It Simple (KISS)

- Every change MUST use the simplest design that satisfies the current requirement.
- Speculative abstractions, configuration knobs, and extension points MUST NOT be added
  until a concrete use case requires them (YAGNI).
- Any added complexity (new layer, indirection, or dependency) MUST be justified in the
  plan's Complexity Tracking table or the PR description.

**Rationale**: A navigation package is consumed by many apps; simple code is easier to
reason about, debug, and keep backward compatible.

### II. Don't Repeat Yourself (DRY)

- A piece of logic or knowledge MUST have a single authoritative implementation.
- Duplication found during a change MUST be extracted into a shared function, class, or
  extension when it is genuine repetition, not coincidental similarity.
- Extraction MUST NOT violate Principle I: prefer two clear copies over one premature,
  hard-to-follow abstraction.

**Rationale**: Duplicated routing and page-building logic drifts and produces
inconsistent navigation behaviour.

### III. SOLID Design

- **Single Responsibility**: each class and file MUST have one reason to change.
- **Open/Closed**: behaviour MUST be extended via new types (e.g. new `DBPageBuilder`
  implementations), not by editing existing ones with conditionals.
- **Liskov Substitution**: subtypes MUST honour the contracts of the types they extend.
- **Interface Segregation**: public interfaces MUST stay small and focused; consumers
  MUST NOT depend on members they do not use.
- **Dependency Inversion**: core navigation logic MUST depend on abstractions, enabling
  substitution with fakes or mocks in tests.

**Rationale**: SOLID keeps the router delegate and page builders modular, testable, and
safe to extend without breaking consumers.

### IV. Self-Documenting Code

- Class, file, function, and variable names MUST explain intent without a comment.
- Code comments and doc comments MUST NOT be added by default. A comment is permitted
  only when it records a non-obvious constraint that naming cannot express (e.g. a
  framework quirk or a workaround), and MUST be at most 1–3 lines.
- Comments MUST NOT restate what the code shows. Design rationale belongs in the commit
  message or PR description.
- **Public API exception**: symbols exported from `lib/db_navigator.dart` MAY carry a
  short doc comment where the `public_member_api_docs` / `package_api_docs` lints
  require one. These MUST be concise and MUST NOT duplicate the symbol name.

**Rationale**: Comments rot; names are checked by the compiler and read on every use.

## Technical Constraints

- Language and SDK: Dart `>=3.1.0 <4.0.0`, Flutter `>=3.13.0`, as declared in `pubspec.yaml`.
- Linting: `flutter_code_style` via `analysis_options.yaml`; `flutter analyze` MUST report
  no errors or warnings.
- Generated code (`*.g.dart`) MUST be produced by `build_runner` and MUST NOT be edited by hand.
- New runtime dependencies MUST be justified under Principle I.

## Development Workflow

- Every change MUST pass `flutter analyze` and `flutter test` before merge.
- New or changed behaviour MUST be covered by tests in the owning package's `test/`
  (root, `db_navigator_generator/`, `example/`).
- Reviews MUST check each change against Principles I–IV and reject unjustified
  complexity, duplication, SOLID violations, or unnecessary comments.
- Breaking changes to the public API MUST be recorded in `CHANGELOG.md` with a matching
  semantic version bump of the package.

## Governance

- This constitution supersedes other project practices where they conflict.
- Amendments MUST be made via a PR that updates this file, states the version bump, and
  describes any migration required for existing code.
- Versioning follows semantic versioning: MAJOR for removed or redefined principles,
  MINOR for new principles or sections, PATCH for clarifications.
- Compliance is verified at plan time (Constitution Check) and at code review.

**Version**: 1.0.1 | **Ratified**: 2026-10-05 | **Last Amended**: 2026-10-07
