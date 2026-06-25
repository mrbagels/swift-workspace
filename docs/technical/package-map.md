# Package Map

Last updated: 2026-06-25

## Products

| Product | Depends On | Purpose |
| --- | --- | --- |
| `WorkspaceCore` | Foundation | Shared route, command, scene, search, policy, and restoration models. |
| `WorkspaceTCA` | WorkspaceCore, TCA | Platform-neutral reducer. |
| `WorkspaceEngine` | WorkspaceCore, WorkspaceTCA, WorkspacePersistence, TCA | Convenience import for wholesale engine adoption. |
| `WorkspacePersistence` | WorkspaceCore | JSON and UserDefaults persistence helpers. |
| `WorkspaceSQLiteData` | WorkspaceCore, SQLiteData | Optional SQLiteData records, migrations, and codecs. |
| `WorkspaceCloudKit` | WorkspaceCore, CloudKit | Optional CloudKit adapter contracts. |
| `MacWorkspaceShell` | WorkspaceCore, WorkspaceTCA, SwiftUI | macOS renderer. |
| `IOSWorkspaceShell` | WorkspaceCore, WorkspaceTCA, SwiftUI | iOS and iPadOS renderer. |

## Demo Targets

| Target | Platform | Purpose |
| --- | --- | --- |
| `MacWorkspaceDemo` | macOS | First consumer of `MacWorkspaceShell`. |
| `IOSWorkspaceDemo` | iOS | First consumer of `IOSWorkspaceShell`. |

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

`MacWorkspaceShell` currently provides:

- configurable native split-view rendering,
- toolbar and command-menu entry points,
- command palette UI backed by `WorkspaceFeature`,
- command reference UI backed by `WorkspaceCommandSections`,
- Mac-specific restoration for chrome and split widths.

`IOSWorkspaceShell` currently provides:

- configurable iOS and iPadOS split rendering,
- command-search sheet backed by `WorkspaceFeature`,
- hardware keyboard shortcut display in command results,
- scene-aware context actions for routes that prefer separate scenes,
- iOS-specific restoration for column preference and compact navigation path.
