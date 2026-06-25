# Phased Implementation Plan

Last updated: 2026-06-25

## Purpose

This plan turns `swift-workspace` from a clean scaffold into a professional reusable
workspace product. The old Mac Shell remains a high-quality prototype and
reference implementation. `swift-workspace` is the new source of truth.

## Phase 0: Fresh Root And Guardrails

Status: complete for the initial scaffold.

Outcome:

- Create the `swift-workspace` root.
- Add SwiftPM and XcodeGen manifests.
- Add docs lifecycle folders.
- Add initial doctor and verification scripts.
- Add the first package products.
- Add Mac and iOS demo app targets.

Acceptance:

- `swift test` runs from `swift-workspace`.
- `xcodegen generate --spec project.yml` generates `SwiftWorkspace.xcodeproj`.
- `scripts/doctor.sh` reports the expected source files and docs.
- The prototype package outside `swift-workspace` remains untouched.

## Phase 1: Stabilize WorkspaceCore

Status: complete for the first stable engine vocabulary. Continue API review
before public tags.

Goal:

Lock down the platform-neutral engine vocabulary before investing in renderers.

Work:

- Audit every `WorkspaceCore` type for naming, access control, Sendable
  conformance, Codable needs, and source stability.
- Decide whether route descriptors should contain display metadata directly or
  be split into route identity plus renderer metadata.
- Add metadata merge primitives for live route badges and availability.
- Add command grouping and command reference helpers.
- Add explicit command roles, including app action, navigation, scene, toolbar,
  primary action, and system command.
- Add route-open parsing helpers for deep links.
- Add more tests for hidden routes, disabled routes, command policy, recents,
  scene replacement, and Codable compatibility.

Acceptance:

- Core has no UI or persistence dependencies.
- Core tests cover route commands, scene commands, policy denial, restoration,
  and metadata application.
- Public type names read as product-level concepts, not prototype names.

Progress:

- Added explicit command roles and reusable command reference grouping.
- Added route metadata patches for live availability, badges, labels, search
  metadata, presentation, scene presentation, and shortcuts.
- Added `WorkspaceRouteOpenURLParser` for app-owned URL-to-route mapping.
- Added conditional Codable conformance to storage-safe route, command,
  navigation, scene request, and route-open request values.
- Expanded core tests for command grouping, unavailable command filtering,
  metadata application, scene identity, and deep-link parsing.

## Phase 2: Make WorkspaceTCA Boring

Status: complete for the current shared reducer surface. Continue adding tests
when new delegate paths or effects appear.

Goal:

Make the reducer durable enough that platform shells can be thin renderers.

Work:

- Add reducer coverage for all delegate paths.
- Add command palette lifecycle coverage.
- Add route-open rejection coverage.
- Add scene request coverage.
- Add restoration coverage.
- Add app-owned command, toolbar, primary, and system command delegate handling.
- Add dependency hooks only when real effects are needed.
- Keep all persistence writes in parent features.

Acceptance:

- Reducer tests can describe every shared workspace behavior without launching
  an app.
- Platform renderers do not duplicate route-selection or command-execution
  logic.

Progress:

- Added `navigationRegistryChanged` and `routeMetadataPatchesApplied` actions.
- Added reducer reconciliation for selected routes, collapsed sections, recent
  commands, and command-palette selection after registry changes.
- Added route fallback when a selected route becomes hidden, disabled, or
  missing.
- Expanded reducer tests for command palette lifecycle, recents, command
  policy, route-open requests and rejections, preferred scene requests,
  restoration, and metadata-driven fallback.

## Phase 3: Port Proven Mac Shell Behavior

Status: complete for the first professional Mac renderer baseline. Manual demo
review remains required before public release.

Goal:

Bring over the prototype's best Mac behavior without copying the old package
shape.

Work:

- Add a Mac shell configuration type.
- Add custom shell and native split-view styles.
- Add command palette UI.
- Add command menu integration.
- Add titlebar configuration.
- Add inspector support.
- Add sidebar visibility.
- Add column width state in Mac-specific restoration.
- Add Mac keyboard shortcuts.
- Add route-window handoff for SwiftUI `WindowGroup`.
- Add accessibility labels and keyboard focus behavior.
- Add visual regression fixtures once the shell stabilizes.

Acceptance:

- Mac users can choose custom or native shell style.
- The Mac shell consumes `WorkspaceTCA`, not a forked reducer.
- Mac-specific restoration composes with shared workspace restoration.
- The demo proves route selection, command execution, scene opening, and
  persistence handoff.

Progress:

- Added `MacWorkspaceShellConfiguration` for renderer style, title, split widths,
  and command palette sizing.
- Added `MacWorkspaceRestoration` and `MacWorkspaceColumnWidths` to compose
  Mac chrome restoration around shared `WorkspaceRestoration`.
- Added a native command palette overlay backed by `WorkspaceFeature`
  command-palette state.
- Added `MacWorkspaceCommandReferenceView` over shared
  `WorkspaceCommandSections`.
- Added toolbar and command menu entry points for command palette and refresh
  commands in the Mac demo.
- Added `MacWorkspaceShellTests` for restoration, configuration, and command
  reference grouping.
- Added stable Mac accessibility identifiers and command-palette focus hardening.
- Added deterministic visual-state fixtures for native split-view and custom Mac
  renderer states.

## Phase 4: Build The iOS And iPadOS Renderer

Status: complete for the first adaptive iOS and iPadOS renderer baseline. Manual
device or simulator review remains required before public release.

Goal:

Show that the engine is not secretly Mac-only.

Work:

- Build an adaptive iOS shell with compact, regular, and iPad layouts.
- Use `NavigationSplitView` where appropriate.
- Add searchable route and command surfaces.
- Add scene-aware iPad behavior.
- Add keyboard shortcut display for hardware keyboards.
- Add route restoration in an iOS-specific wrapper.
- Add snapshot or UI coverage for compact and regular widths.

Acceptance:

- The iOS demo uses the same route registry and command definitions as the Mac
  demo.
- The iOS shell feels native rather than copied from Mac.
- Custom iOS clients can bypass the shell and still use the engine.

Progress:

- Added `IOSWorkspaceShellConfiguration` for title, navigation style, command
  search placeholder, and badge display preferences.
- Added `IOSWorkspaceRestoration` to compose iOS column and compact navigation
  state around shared `WorkspaceRestoration`.
- Added a configurable iOS shell renderer backed by `WorkspaceFeature`.
- Added a compact command-search sheet that uses shared command filtering,
  selection, recents, and command execution.
- Added scene-aware route context actions for iPadOS window handoff.
- Updated the iOS demo to use the same singleton settings scene metadata as the
  Mac demo.
- Added `IOSWorkspaceShellTests` for restoration and configuration defaults.
- Added stable iOS accessibility identifiers and command-search focus hardening.
- Added deterministic visual-state fixtures for compact and split renderer
  states.
- Added `VERIFY_BUILD_IOS=1 scripts/verify.sh` coverage for compiling the iOS
  demo and iOS-only SwiftUI renderer.

## Phase 5: Persistence And iCloud Primary Storage

Status: complete for persistence helpers and CloudKit contracts. Live CloudKit
sync remains app-owned and decision-gated by consuming app requirements.

Goal:

Make local and iCloud-backed durability explicit without making storage a hidden
engine dependency.

Work:

- Complete `WorkspacePersistence` with file and UserDefaults stores.
- Complete `WorkspaceSQLiteData` migrations, codecs, stores, and metadata
  observers.
- Build `WorkspaceCloudKit` adapter contracts.
- Add CloudKit private database restoration examples.
- Add CloudKit shared database metadata examples.
- Define conflict policies for route metadata and restoration payloads.
- Document what belongs in iCloud, SQLite, UserDefaults, and app-owned storage.

Acceptance:

- Apps can persist shared engine restoration with UserDefaults, SQLiteData, or
  CloudKit.
- App-owned document and workflow state remains app-owned.
- iCloud is documented as primary storage for user-owned data.

Progress:

- Added `WorkspaceFilePersistence` for atomic JSON restoration files.
- Added file persistence tests for missing files, parent directory creation,
  roundtrip loading, and missing-file removal.
- Expanded `WorkspaceCloudKit` with database scope, sync scope, zone,
  conflict-policy, record-name, restoration-envelope, and route-metadata
  envelope contracts.
- Added an async `WorkspaceCloudKitSyncAdapter` protocol for app-owned live
  CloudKit implementations.
- Added CloudKit contract tests for Codable envelopes and conflict policy.
- Added CloudKit adoption docs that keep iCloud primary and app-owned.

## Phase 6: Companion Server

Status: decision-gated. Do not add `WorkspaceServerClient` until a consuming app
proves the first server-backed workflow.

Goal:

Add server capabilities without turning the server into primary storage.

Work:

- Define server scope and anti-scope.
- Add an OpenAPI contract or typed client contract.
- Add entitlement and feature flag endpoints.
- Add template catalog endpoints.
- Add background job endpoints for AI, import, export, and diagnostics.
- Add webhook relay shape.
- Add `WorkspaceServerClient` only after app flows require it.
- Keep all server calls app-owned effects.

Acceptance:

- Server features are optional.
- User documents and workspace state are not server-primary.
- Apps can run without the companion server unless they use server-specific
  capabilities.

Progress:

- Defined server scope, anti-scope, initial API areas, and the implementation
  gate in `docs/features/server-side-companion.md`.
- Kept server behavior outside `WorkspaceCore`, `WorkspaceTCA`, and platform
  shells.

Blocked Until:

- First concrete server-backed workflow.
- Authentication and entitlement model.
- Request and response payloads.
- Offline, retry, cancellation, privacy, and retention requirements.

## Phase 7: Distribution And Adoption

Status: in progress. Adoption docs and local release checklists are in place;
DocC catalogs are scaffolded; public release work still needs versioning and
repository decisions.

Goal:

Make client adoption boring.

Work:

- Publish from the root Swift package.
- Tag semantic versions.
- Add DocC catalogs for every public product.
- Add consumer quickstarts for Mac, iOS, custom renderer, and engine-only usage.
- Add migration docs from the prototype.
- Add release checklist and API review checklist.
- Add minimal starter apps.
- Add CI verification for package tests, docs, Mac demo build, and optional iOS
  simulator build.

Acceptance:

- A client can add one package URL and choose products by need.
- Public docs explain which product to import.
- Release quality does not depend on remembering prototype context.

Progress:

- Added a compiled `Examples/CustomRendererClient` Swift package that depends on
  `swift-workspace` by path.
- Demonstrated route snapshots, command sections, route metadata patches, and
  file restoration without importing either platform shell.
- Added adoption docs for Mac shell, iOS shell, engine-only, custom renderer,
  persistence, CloudKit, and prototype migration paths.
- Added API review and release checklists.
- Added DocC landing-page catalogs for every public package product.
- Added custom-renderer example tests to `scripts/verify.sh`.

Remaining:

- Add minimal starter apps when the preferred starter shape is chosen.
- Add CI after the target runner image and Xcode version are chosen.
- Tag a semantic version after manual demo review.

## Phase 8: Professional Polish

Status: in progress. Automation anchors and visual-state fixtures are in place;
manual design and interaction review remains.

Goal:

Make `swift-workspace` feel like a product worth showing.

Work:

- Design review for Mac and iOS shells.
- Accessibility audit.
- Command discoverability audit.
- Snapshot and UI automation coverage.
- Performance pass for large route registries.
- API stability pass.
- Example app polish.
- Server companion demo only if it clarifies the product.

Acceptance:

- The package has a convincing demo story.
- API boundaries are defensible.
- Docs, tests, and examples agree with behavior.

## Current Remaining Work

Autonomous:

- Add a CI workflow once the expected Xcode runner is known.
- Add more reducer and renderer fixtures when new public behavior is introduced.
- Keep docs and package map synchronized with source changes.

Manual Or Decision-Gated:

- Choose the first real companion-server workflow before adding a server client.
- Choose package version, public repository URL, and release timing before
  tagging.
- Choose minimal starter app shape before adding starter app templates.
- Run hands-on Mac and iOS demo review before public release.
