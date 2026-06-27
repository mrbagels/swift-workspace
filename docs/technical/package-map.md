# Package Map

Last updated: 2026-06-27

## Products

| Product | Depends On | Purpose |
| --- | --- | --- |
| `WorkspaceCore` | Foundation | Shared route, command, scene, search, policy, and restoration models. |
| `WorkspaceTCA` | WorkspaceCore, TCA | Platform-neutral reducer. |
| `WorkspaceEngine` | WorkspaceCore, WorkspaceTCA, WorkspacePersistence, TCA | Convenience import for wholesale engine adoption. |
| `WorkspacePersistence` | WorkspaceCore | JSON, UserDefaults, and file persistence helpers. |
| `WorkspaceSQLiteData` | WorkspaceCore, SQLiteData | Optional SQLiteData records, migrations, and codecs. |
| `WorkspaceCloudKit` | WorkspaceCore, CloudKit | Optional CloudKit adapter contracts. |
| `WorkspaceShellDesignSystem` | WorkspaceCore, SwiftUI | Shared SwiftUI primitives for bundled shells and custom renderers. |
| `WorkspaceAutomationBridge` | WorkspaceCore | Serializable automation catalog and App Intent handoff descriptors. |
| `WorkspaceServerClient` | WorkspaceCore, Comet, CometTCA, TCA | Optional companion server client for typed non-storage workflows. |
| `MacWorkspaceShell` | WorkspaceCore, WorkspaceTCA, SwiftUI | macOS renderer. |
| `IOSWorkspaceShell` | WorkspaceCore, WorkspaceTCA, SwiftUI | iOS and iPadOS renderer. |

## Demo Targets

| Target | Platform | Purpose |
| --- | --- | --- |
| `MacWorkspaceDemo` | macOS | First consumer of `MacWorkspaceShell`. |
| `IOSWorkspaceDemo` | iOS | First consumer of `IOSWorkspaceShell`. |
| `MacWorkspaceDemoUITests` | macOS | Opt-in UI smoke coverage for Mac shell launch, routes, and command search. |
| `IOSWorkspaceDemoUITests` | iOS | Opt-in UI smoke coverage for iOS shell launch, routes, and command search. |
| `MinimalMacWorkspaceApp` | macOS | Smallest starter target for Mac shell adoption. |
| `MinimalIOSWorkspaceApp` | iOS | Smallest starter target for iOS shell adoption. |

The iOS app targets keep explicit Info.plist files checked in so launch screen,
scene manifest, orientation, indirect input, and universal iPhone/iPad device
family metadata are reviewed as source instead of inferred from generated build
settings.

## Example Packages

| Package | Purpose |
| --- | --- |
| `Examples/CustomRendererClient` | Standalone consumer that uses `WorkspaceCore`, `WorkspaceTCA`, and `WorkspacePersistence` without importing bundled platform shells. |

## Dependency Constraints

- Optional adapters must not leak into core products.
- Platform renderers must consume the reducer, not duplicate it.
- Demo apps may import umbrella products for ergonomics.
- Tests should prefer package-level behavior over app-level UI until renderers
  stabilize.

## Current Core Surface

`WorkspaceCore` includes:

- route descriptors, sections, availability, and registry values,
- route content states and route status metadata,
- command IDs, roles, sources, targets, policy, and search,
- registry validation diagnostics for CI and debug surfaces,
- command reference grouping with `WorkspaceCommandSections`,
- route metadata patches with `WorkspaceRouteMetadataPatch`,
- route-open requests, rejections, and URL parsing,
- scene presentation, requests, values, and collections,
- keyboard shortcut metadata,
- shared restoration payloads.

`WorkspaceTCA` currently owns:

- command palette lifecycle,
- command execution and command policy enforcement,
- route selection and route-open handling,
- preferred scene request delegates,
- pinned route and recent route tracking,
- recent command tracking,
- collapsed section tracking,
- restoration loading,
- navigation registry replacement,
- route metadata patch reconciliation.

Large-registry tests cover route command search, command reference grouping, and
metadata patch application across thousands of routes. Metadata patches are
indexed by route before application so patch handling scales with changed routes
and route count instead of repeatedly scanning every patch for every route.

`MacWorkspaceShell` currently provides:

- custom-only shell rendering,
- floating and edge-to-edge custom sidebar presentations,
- toolbar and command-menu entry points,
- `MacWorkspaceCommands` for native menu generation from
  `WorkspaceCommandSections`,
- command palette UI backed by `WorkspaceFeature`,
- command reference UI backed by `WorkspaceCommandSections`,
- Mac-specific restoration for chrome and split widths,
- demo-proven typed route scene handoff through `WorkspaceSceneValue`.

`IOSWorkspaceShell` currently provides:

- configurable iOS and iPadOS split rendering,
- command-search sheet backed by `WorkspaceFeature`,
- hardware keyboard shortcut display in command results,
- scene-aware context actions for routes that prefer separate scenes,
- iOS-specific restoration for column preference and compact navigation path,
- stable accessibility identifiers for shell automation,
- deterministic visual-state fixtures for compact and split renderer states.

`WorkspacePersistence` currently provides:

- JSON encoding and decoding for `WorkspaceRestoration`,
- UserDefaults-backed restoration persistence,
- file-backed restoration persistence with parent directory creation and atomic
  writes.

`WorkspaceCloudKit` currently provides:

- CloudKit database, sync scope, zone, and conflict policy values,
- stable record-name helpers for restoration, route metadata, and scenes,
- Codable restoration and route-metadata envelopes,
- async adapter protocol for app-owned live CloudKit implementations.

`WorkspaceShellDesignSystem` currently provides:

- `WorkspaceShellBadge`,
- `WorkspaceShellKeycap`,
- `WorkspaceShellSectionLabel`,
- `WorkspaceShellRouteStatusView`,
- reusable palette and metrics values for custom renderers.

`WorkspaceAutomationBridge` currently provides:

- an automation catalog built from `WorkspaceNavigationRegistry`,
- command descriptors for routes, scenes, app actions, toolbar actions, primary
  actions, and system actions,
- handoff payloads that app-owned App Intents can pass to the main scene,
- shortcut descriptor templates for app-owned `AppShortcutsProvider` types.

`WorkspaceServerClient` currently provides:

- an optional Comet-backed HTTP client,
- typed health, entitlement, template, job, and diagnostics requests,
- a TCA `Effect.workspaceServerRequest` helper,
- tests backed by `CometTesting`.

## Adoption And Distribution Docs

Consumer-facing adoption docs now cover:

- Mac shell adoption,
- iOS shell adoption,
- engine-only adoption,
- custom renderer adoption,
- persistence adapters,
- CloudKit contracts,
- automation bridge adoption,
- server client adoption,
- prototype migration.

Operations docs now cover API review and release checklists. The server client
is optional and intentionally thin, and it must remain outside core engine and
renderer products. CI runs from `.github/workflows/swift-workspace.yml` and uses
`scripts/verify.sh` as its source of truth.

The initial public beta is versioned as `0.1.0`, published from
`https://github.com/mrbagels/swift-workspace`, and licensed under MIT.

DocC landing pages are scaffolded in each public product target:

- `Sources/WorkspaceCore/WorkspaceCore.docc`
- `Sources/WorkspaceTCA/WorkspaceTCA.docc`
- `Sources/WorkspaceEngine/WorkspaceEngine.docc`
- `Sources/WorkspacePersistence/WorkspacePersistence.docc`
- `Sources/WorkspaceSQLiteData/WorkspaceSQLiteData.docc`
- `Sources/WorkspaceCloudKit/WorkspaceCloudKit.docc`
- `Sources/WorkspaceShellDesignSystem/WorkspaceShellDesignSystem.docc`
- `Sources/WorkspaceAutomationBridge/WorkspaceAutomationBridge.docc`
- `Sources/WorkspaceServerClient/WorkspaceServerClient.docc`
- `Sources/MacWorkspaceShell/MacWorkspaceShell.docc`
- `Sources/IOSWorkspaceShell/IOSWorkspaceShell.docc`

## Starter Apps

The minimal starter app targets live under `Examples/` but are built by the
generated Xcode project rather than SwiftPM:

- `Examples/MinimalMacWorkspaceApp`
- `Examples/MinimalIOSWorkspaceApp`

They intentionally contain only route definitions, a small registry, a
`WorkspaceFeature` store, and the platform shell view. They are templates for
consumer wiring, not full demos.
