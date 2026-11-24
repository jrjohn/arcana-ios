# AGENTS.md — arcana-ios

Instructions for any AI coding agent (Claude Code, Codex, Cursor, Copilot, Gemini…) working
in this repository **or in any product created from it**. `CLAUDE.md`, `GEMINI.md` and
`.github/copilot-instructions.md` all point here; this file is the single source.

> **You MUST NOT report a task as done until `tools/arch-check.sh` exits 0 and the build and
> test commands in §5 pass.** Breaking the layering costs a red build: the pre-commit hook
> (`tools/githooks/pre-commit`) rejects new Swift files outside the layer folders and concrete
> `*Impl` types named outside `ArcanaCore/DI/`; Jenkins stage "Architecture Qube" fails the
> merge below score 90 or on any critical violation. A screen that talks to SwiftData directly
> compiles fine and fails both gates after the work is written.

## 0. First command in a fresh clone

Run `tools/install-hooks.sh` once. Git does not install hooks on clone; until you run it the
pre-commit check does not exist and only CI catches a flat layout — after the work is
written. `tools/new-app.sh` runs it for you.

## 1. Starting something new

| Situation | Do this | Never do this |
|---|---|---|
| New iOS product | `[BUNDLE_ID=com.acme.x] tools/new-app.sh <name> <dest-dir>` — copies the whole repo, renames the Xcode project / target / scheme / module, bundle id, display name, Sonar key, Jenkins and fastlane names, resets the version to 0.1.0, installs the hook | Create a new Xcode project and copy a few `Sources/` folders into it |
| New business feature | `tools/new-feature.sh <Name>` (PascalCase) — one vertical slice: model, service protocol + impl, repository protocol + offline-first impl, SwiftData entity + local DAO, remote DAO, Input/Output/Effect ViewModel + View, DI key + wiring + schema entry, `AppRoute` case + `NavGraph` route, Swift Testing tests with mocks | Call `ModelContext`, `URLSession` or `ApiService` from a View or ViewModel, or add `Sources/Foo.swift` |
| Form / detail screen for a feature | Copy `Screens/User/UserFormView.swift` + `UserFormViewModel.swift` into `Screens/<Name>/`, renamed; add an `AppRoute` case and a `NavGraphView` case | Keep form state and service calls in the View |
| New field on a feature | Change model, `<Name>Entity` (+ `toDomain`/`from`/`update`), remote mapping and tests together | Change only the entity |

New files need no project edit: the app and test targets are Xcode synchronized folders
(`PBXFileSystemSynchronizedRootGroup`), so anything under `arcana-ios/` or `arcana-iosTests/`
is compiled. Copying parts instead of `new-app.sh` loses this file, the hook and the CI gate.

## 2. Layers — where a file goes

One Swift module (`arcana_ios`, target `arcana-ios`); layers are folders under
`arcana-ios/Sources/`. The `@main` App (`arcana-ios/arcana_iosApp.swift`) only builds the
`ModelContainer`, calls `AppDependencies.setup` and hosts `MainView` in a `NavigationStack`.

| Layer | Path | Contains | May depend on |
|---|---|---|---|
| Core | `ArcanaCore/{Analytics,Common,Configuration,Localization,Network,Remote}/` | `AnalyticsTracker`, `AppError`/`ErrorCode`, `AppConfiguration`/`AppConstants`, `NetworkMonitor`, `ApiService` (Alamofire) | Foundation, Alamofire, SwiftData (analytics store) |
| DI (composition root) | `ArcanaCore/DI/AppDependencies.swift` | `DependencyValues` keys, `DependencyStorage`, `setup()` building DAO → repository → service, `createModelContainer()` schema, test/preview overrides | everything; the **only** file that constructs `*Impl` |
| Presentation | `ArcanaPresentation/Screens/<Feature>/` (View + ViewModel), `Components/`, `Theme/`; routing in `Screens/User/AppRoute.swift` + `NavGraph.swift` | SwiftUI views rendering `viewModel.output`; `@Observable` ViewModels with Input/Output/Effect | Domain (service protocols, models), Core (`@Dependency`, `AppError`, analytics) — never ArcanaData |
| Domain | `ArcanaDomain/Model/`, `Service/` (protocols), `Service/impl/`, `Validation/` | value models, `XService` protocols, `XServiceImpl`, validators | Core; `Service/impl` also uses the `XRepository` protocol from ArcanaData/Repository |
| Data | `ArcanaData/Repository/` (+`impl/`), `Local/` (+`impl/`, `Entities/`), `Remote/` (+`impl/`) | `XRepository` protocols + `OfflineFirstXRepositoryImpl`, SwiftData `@Model` entities, `XLocalDao`/`XRemoteDao` protocols + impls | Domain models, Core |
| Tests | `arcana-iosTests/{Core,Domain,Presentation,Mocks}/`, root for repository tests; `arcana-iosUITests/` | Swift Testing (`@Test`, `#expect`), hand-written mocks of each protocol | `@testable import arcana_ios` |

Direction: View → ViewModel → `@Dependency(\.xService)` (Domain protocol) → `XServiceImpl`
→ `XRepository` → local DAO (SwiftData) / remote DAO. A lower layer never references a higher
one. Known legacy, do not copy: `UserListViewModel.syncOfflineChanges` casts to
`OfflineFirstUserRepositoryImpl`, and `NavGraph.swift` holds placeholder detail/settings views.

## 3. Rules

| # | Rule | Enforced by |
|---|---|---|
| R1 | Every service, repository and DAO is a protocol next to an `impl/` folder holding `XServiceImpl` / `OfflineFirstXRepositoryImpl` / `XLocalDaoImpl` / `XRemoteDaoImpl`. | arch-qube "Interface/Impl Colocation", "Implementation Naming Convention" |
| R2 | Only `ArcanaCore/DI/` names a concrete `*Impl`; everyone else depends on the protocol through `@Dependency(\.x)` or an init parameter typed as the protocol. Tests may construct impls. | pre-commit hook (arch-qube "Only DI Container Imports Impl" looks at imports, and one Swift module has none — it did not flag the legacy cast below) |
| R3 | Views never call a service, repository, DAO, `ModelContext` or `ApiService`; they send `await viewModel.input(.x)` and render `viewModel.output`. | arch-qube "View Cannot Call Service", "Layer Direction Enforcement" |
| R4 | A ViewModel is `@MainActor @Observable final class` with `enum Input`, `struct Output` held in `private(set) var output`, `enum Effect`, and `func input(_:) async -> Effect?`; dependencies are `@ObservationIgnored @Dependency` properties; navigation goes through the injected `NavGraph`. | arch-qube "Unidirectional Data Flow"; review (arch-qube "MVVM I/O/E Structure" is AI-only, §4) |
| R5 | A screen is reachable only through an `AppRoute` case (with `id`, `title`, `analyticsName`), a `NavGraphView.view(for:)` case and a `NavGraph.navigateTo…` method. | arch-qube "Type-Safe NavGraph"; the compiler (exhaustive `switch`) |
| R6 | A new service gets a `DependencyValues` property, a `DependencyKey`, a `DependencyStorage` slot and wiring in `AppDependencies.setup()`; a new `@Model` is added to the `Schema` in `createModelContainer()`. | `new-feature.sh` does it; a missing key is a `fatalError` at first use, a missing schema entry fails at runtime — not at compile time |
| R7 | Reads come from SwiftData first and refresh from remote; writes land in SwiftData before the network and survive a remote failure. | review (arch-qube "Offline-First Design", "4-Layer Progressive Cache" are AI-only) |
| R8 | No new `.swift` file outside the folders of §2. | pre-commit hook |
| R9 | Every new service impl, repository impl and ViewModel gets Swift Testing tests that mock the layer below (as `new-feature.sh` generates). | arch-qube "Test Coverage Threshold"; SonarQube quality gate (Jenkins "SonarQube Analysis") |
| R10 | Boundary code (Views, `NavGraph`) only delegates: no method over 20 lines of logic. | arch-qube "No Business Logic in Boundary" (major; `NavGraphView.view` is a known finding) |

## 4. Architecture check (arch-qube)

arch-qube (https://github.com/jrjohn/arcana-arch-qube) scans the source for MVVM,
layer-direction, DI and naming violations and scores it; usage guide:
https://github.com/jrjohn/arcana-skills/tree/main/arch-qube-skill. The version is pinned in
`tools/arch-qube.version`, read by both `tools/arch-check.sh` and the Jenkinsfile.

- Run: `tools/arch-check.sh` — image `ghcr.io/jrjohn/arch-qube:<version>` (public,
  multi-arch), else `arcana.boo/arcana/arch-qube:<version>`; never `:latest`. Same
  `--framework ios`, `--threshold 90` and exclusions as Jenkins stage "Architecture Qube".
  Exit 0 = pass, 1 = fail, 2 = could not run (no Docker / no image) — 2 is **not** a pass.
- Without Docker, on a tree without `DerivedData/`, `build/`, `.build/`:
  `pipx run --spec git+https://github.com/jrjohn/arcana-arch-qube.git@v0.5.6 arch-qube scan . --framework ios --no-ai --format json,markdown -o arch-qube-reports --threshold 90`.
- Report: `arch-qube-reports/arch-qube.md` (summary) and `arch-qube.json` (per rule:
  `files_checked`, violations). PASS needs score ≥ threshold **and** zero violations in
  every critical rule — a 99.6 can FAIL. A rule under "Not evaluated" (here: MVVM I/O/E,
  4-Layer Cache, Offline-First, Security — AI-only) is not a pass; R4/R7 are on you. A rule
  with `files_checked: 0` checked nothing. `--ci` prints nothing on failure: rerun without
  `--ci` to see why.
- False positive: open an issue on arcana-arch-qube with the report attached. Never lower
  `--threshold`, add exclusions, or move code to dodge a rule.

## 5. Before you say "done"

Run these, in this order, and paste the last line of each into your summary. `<SIM>` is an
iPhone simulator id with iOS ≥ 26.1 (the deployment target) from
`xcrun simctl list devices available`; CI uses `name=iPhone 17`.

```bash
tools/arch-check.sh     # must print "arch-check: PASS"
# Jenkins "Build":
xcodebuild -project arcana-ios.xcodeproj -scheme arcana-ios -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
# Jenkins "Test + Coverage" (also fails on any "recorded an issue" line in the log):
xcodebuild -project arcana-ios.xcodeproj -scheme arcana-ios -destination "platform=iOS Simulator,id=<SIM>" \
  -enableCodeCoverage YES -skipPackagePluginValidation -parallel-testing-enabled NO test
```

Add `-only-testing:arcana-iosTests` for the unit tests alone while iterating; the full run
also launches the UI tests. `make test` runs the same `xcodebuild test` (with `pipefail`, so
its exit code is xcodebuild's). CI also runs SonarQube, which you cannot run locally.

## 6. Reference

- Optional detail: `arcana-ios-developer-skill`
  (https://github.com/jrjohn/arcana-skills/tree/main/arcana-ios-developer-skill).
  This file is the source of truth: if the skill and this file disagree, this file wins.
