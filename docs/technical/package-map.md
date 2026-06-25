# Package Map

Last updated: 2026-06-25

## Products

| Product | Depends On | Purpose |
| --- | --- | --- |
| `WorkspaceCore` | Foundation | Shared route, command, scene, search, policy, and restoration models. |
| `WorkspaceTCA` | WorkspaceCore, TCA | Platform-neutral reducer. |
| `WorkspaceEngine` | WorkspaceCore, WorkspaceTCA, WorkspacePersistence, TCA | Convenience import for wholesale engine adoption. |
| `WorkspacePersistence` | WorkspaceCore | JSON, UserDefaults, and file persistence helpers. |
| `WorkspaceSQLiteData` | WorkspaceCore, SQLiteData | Optional SQLiteData records, migrations, and codecs. |
| `WorkspaceCloudKit` | WorkspaceCore, CloudKit | Optional CloudKit adapter contracts. |
| `MacWorkspaceShell` | WorkspaceCore, WorkspaceTCA, SwiftUI | macOS renderer. |
| `IOSWorkspaceShell` | WorkspaceCore, WorkspaceTCA, SwiftUI | iOS and iPadOS renderer. |

## Demo Targets

| Target | Platform | Purpose |
| --- | --- | --- |
| `MacWorkspaceDemo` | macOS | First consumer of `MacWorkspaceShell`. |
| `IOSWorkspaceDemo` | iOS | First consumer of `IOSWorkspaceShell`. |
| `MinimalMacWorkspaceApp` | macOS | Smallest starter target for Mac shell adoption. |
| `MinimalIOSWorkspaceApp` | iOS | Smallest starter target for iOS shell adoption. |

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
- command IDs, roles, sources, targets, policy, and search,
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

- configurable native split-view rendering,
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

## Adoption And Distribution Docs

Consumer-facing adoption docs now cover:

- Mac shell adoption,
- iOS shell adoption,
- engine-only adoption,
- custom renderer adoption,
- persistence adapters,
- CloudKit contracts,
- prototype migration.

Operations docs now cover API review and release checklists. Live server-client
distribution remains decision-gated until an app workflow proves a server API.
CI runs from `.github/workflows/swift-workspace.yml` and uses
`scripts/verify.sh` as its source of truth.

DocC landing pages are scaffolded in each public product target:

- `Sources/WorkspaceCore/WorkspaceCore.docc`
- `Sources/WorkspaceTCA/WorkspaceTCA.docc`
- `Sources/WorkspaceEngine/WorkspaceEngine.docc`
- `Sources/WorkspacePersistence/WorkspacePersistence.docc`
- `Sources/WorkspaceSQLiteData/WorkspaceSQLiteData.docc`
- `Sources/WorkspaceCloudKit/WorkspaceCloudKit.docc`
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
