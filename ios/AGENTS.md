# Repository Guidelines

## Project Structure & Module Organization
HealthBuddy follows a layered flow `App → Feature(Impl) → Feature(Api) → Domain → Library`. SwiftUI entry points live in `App/Sources/AppMain`, while dependency wiring is under `App/Sources/Composition`. Feature demos reside in `Packages/Feature/<Name>/{api,impl}`; each subfolder is an independent Swift package. Shared business logic goes in `Packages/Domain`, and reusable utilities live in `Packages/Library`. Register new demos through `App/Sources/Composition/AppComposition.swift` so they surface in the catalog.

## Build, Test, and Development Commands
- `scripts/generate_project.sh` regenerates `HealthBuddy.xcodeproj` via XcodeGen; run after adding modules or adjusting `project.yml`.
- `scripts/build.sh [--clean|--verbose]` wraps `xcodebuild` for simulator builds (default `iPhone 17 Pro`).
- `xcodebuild test -project HealthBuddy.xcodeproj -scheme HealthBuddy -destination "platform=iOS Simulator,name=iPhone 17 Pro"` runs UI + integration tests from Xcode.
- `swift test --package-path Packages/Feature/<Module>/api` (or `impl`) executes package-level XCTest suites when developing in isolation.

## Coding Style & Naming Conventions
Use Swift 5.9 defaults with 4-space indentation and type inference where safe. Keep files focused and prefer `struct` + SwiftUI ViewBuilder patterns already used in `App/Sources/AppMain`. Name packages with the `[Layer][Module][Api|Impl]` pattern (e.g. `FeatureHealthKitImpl`), and services as `Domain<Area>` or `Library<Capability>`. Run `swift-format` if configured locally and keep imports explicit (no wildcard). Comments should capture intent or rationale, not restate code.

## Testing Guidelines
Add `Tests/<ModuleName>Tests` targets to every new package and mirror the namespace (e.g. `FeatureHealthKitImplTests`). Use XCTest with descriptive `test_<behavior>` method names. Prefer dependency inversion to mock domain services. Ensure new demos register deterministic sample data so snapshots remain stable. Before opening a PR, execute project tests with `xcodebuild test` plus any impacted package tests.

## Commit & Pull Request Guidelines
Follow the observed `type: summary` convention (`docs: update README.md`, `refactor: simplify project structure`). Keep commits small, scoped to one change, and include migration notes in the body when touching scripts. PRs should summarize the demo or service being added, link to tracking issues, attach simulator screenshots for UI work, and note test results (`xcodebuild test` output or package runs). Tag reviewers across App, Feature, and Domain areas when changes span layers.

## Module Automation Tips
Use `scripts/createModule.py -f <Name>` to scaffold feature modules; it prepares paired API/Impl packages. After scaffolding, adjust `project.yml`, run `scripts/generate_project.sh`, and register the module in `AppComposition` before pushing.
