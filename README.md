# swift-workspace

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2026%20%7C%20iOS%2026-blue.svg)](Package.swift)
[![Version](https://img.shields.io/badge/version-0.1.0-6E56CF.svg)](docs/operations/release-checklist.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![TCA](https://img.shields.io/badge/TCA-ready-111827.svg)](https://github.com/pointfreeco/swift-composable-architecture)
[![iCloud](https://img.shields.io/badge/storage-iCloud%20primary-0A84FF.svg)](docs/adoption/cloudkit.md)
[![Comet](https://img.shields.io/badge/server%20client-Comet%20optional-7C3AED.svg)](docs/features/server-side-companion.md)

Reusable Swift workspace engine, platform shells, persistence contracts, and
optional companion integrations for apps that need polished navigation,
commands, restoration, scenes, and automation without tying those mechanics to a
single product.

`swift-workspace` is designed to be adopted in pieces. Use the pure engine,
bring the TCA reducer, ship the bundled Mac or iOS shells, build your own
renderer, or add optional storage, automation, and server products only when
your app needs them.

## Why It Exists

Modern productivity apps usually rebuild the same infrastructure:

- typed route registries,
- sidebar and split navigation,
- command palettes and native menus,
- keyboard shortcuts,
- route restoration,
- scene/window handoff,
- iCloud-aware persistence contracts,
- accessibility fixtures,
- optional server workflows,
- system automation entry points.

This package makes that infrastructure shared, testable, and app-agnostic. Your
app still owns domain state, documents, iCloud containers, server decisions,
analytics, and product-specific UI.

## What You Get

| Area | Included |
| --- | --- |
| Engine | Typed routes, commands, scenes, search, policy, diagnostics, restoration, pins, recents, route states. |
| Reducer | `WorkspaceFeature`, shared TCA behavior, delegate effects, command execution, route opening, registry reconciliation. |
| Shells | Custom macOS shell, adaptive iOS and iPadOS shell, command search, visual fixtures, accessibility anchors. |
| Design System | Reusable SwiftUI primitives for badges, keycaps, section labels, and route status states. |
| Persistence | JSON, UserDefaults, file persistence, SQLiteData codecs, CloudKit contracts. |
| Automation | Serializable command catalog, App Intent handoff payloads, shortcut descriptors. |
| Server | Optional Comet-backed typed client for entitlements, templates, jobs, diagnostics, and health. |

## Install

Add the package in Xcode or SwiftPM:

```swift
.package(
  url: "https://github.com/mrbagels/swift-workspace",
  from: "0.1.0"
)
```

Then import only the products you need:

```swift
.product(name: "WorkspaceCore", package: "swift-workspace")
.product(name: "WorkspaceTCA", package: "swift-workspace")
.product(name: "MacWorkspaceShell", package: "swift-workspace")
.product(name: "IOSWorkspaceShell", package: "swift-workspace")
```

## Choose A Path

| If you want | Start with |
| --- | --- |
| Pure route, command, scene, and restoration models | `WorkspaceCore` |
| Shared reducer behavior with app-owned effects | `WorkspaceTCA` |
| A batteries-included engine import | `WorkspaceEngine` |
| A polished custom macOS shell | `MacWorkspaceShell` |
| A native-feeling iPhone and iPad shell | `IOSWorkspaceShell` |
| A fully custom renderer | `WorkspaceCore` plus `WorkspaceTCA` |
| Small restoration storage | `WorkspacePersistence` |
| SQLiteData records and codecs | `WorkspaceSQLiteData` |
| iCloud contracts and conflict policies | `WorkspaceCloudKit` |
| Shared shell UI primitives | `WorkspaceShellDesignSystem` |
| Shortcuts, App Intents, widgets, or controls | `WorkspaceAutomationBridge` |
| Thin companion server calls | `WorkspaceServerClient` |

## Product Map

| Product | Purpose |
| --- | --- |
| `WorkspaceCore` | Pure Swift route, command, scene, search, diagnostics, policy, state, and restoration vocabulary. |
| `WorkspaceTCA` | Platform-neutral TCA reducer for route selection, commands, command palette, scenes, pins, recents, and restoration. |
| `WorkspaceEngine` | Convenience umbrella that re-exports core engine products and TCA. |
| `WorkspacePersistence` | JSON, UserDefaults, and file-backed restoration helpers. |
| `WorkspaceSQLiteData` | Optional SQLiteData records, migrations, codecs, and metadata mapping. |
| `WorkspaceCloudKit` | Optional CloudKit record names, envelopes, conflict policies, and app-owned adapter contracts. |
| `WorkspaceShellDesignSystem` | SwiftUI badges, keycaps, section labels, and route status views shared by renderers. |
| `WorkspaceAutomationBridge` | Automation descriptors, shortcut metadata, and App Intent handoff payloads. |
| `WorkspaceServerClient` | Optional Comet client for companion service contracts. |
| `MacWorkspaceShell` | Custom macOS shell renderer with sidebar styles, command palette, menus, toolbar, inspector, and scenes. |
| `IOSWorkspaceShell` | Adaptive iOS and iPadOS renderer with split/stack navigation, command search, pins, recents, and scene actions. |

## Core Example

Define typed routes and a navigation registry:

```swift
import WorkspaceCore

enum AppRoute: String, Codable, Hashable, Sendable {
  case inbox
  case settings
}

let registry = WorkspaceNavigationRegistry(
  sections: [
    WorkspaceRouteSection(
      id: "workspace",
      title: "Workspace",
      routes: [
        WorkspaceRouteDescriptor(
          id: AppRoute.inbox,
          title: "Inbox",
          systemImage: "tray.full",
          badge: 12,
          shortcut: .command("1")
        ),
        WorkspaceRouteDescriptor(
          id: AppRoute.settings,
          title: "Settings",
          systemImage: "gearshape",
          contentState: .empty(
            title: "No Settings Changes",
            message: "Everything is already current.",
            systemImage: "gearshape"
          ),
          shortcut: .command(","),
          presentation: .fullWidth,
          scenePresentation: .singleton(id: "settings", title: "Settings")
        ),
      ]
    ),
  ],
  commands: [
    .appAction(
      id: "refresh-workspace",
      title: "Refresh Workspace",
      systemImage: "arrow.clockwise",
      shortcut: .command("r")
    ),
  ]
)
```

Wire the shared reducer into your app feature:

```swift
import ComposableArchitecture
import WorkspaceTCA

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var workspace = WorkspaceFeature<AppRoute>.State(
      navigation: registry,
      pinnedRouteIDs: [.inbox],
      selectedRouteID: .inbox
    )
  }

  enum Action: Sendable {
    case workspace(WorkspaceFeature<AppRoute>.Action)
  }

  var body: some Reducer<State, Action> {
    Scope(state: \.workspace, action: \.workspace) {
      WorkspaceFeature<AppRoute>()
    }

    Reduce { state, action in
      switch action {
      case .workspace(.delegate(.commandRequested(let commandID))):
        return runAppCommand(commandID)

      case .workspace(.delegate(.sceneRequested(let request))):
        return openScene(request)

      case .workspace:
        return .none
      }
    }
  }
}
```

## Bundled Shells

### macOS

```swift
import MacWorkspaceShell

MacWorkspaceShellView(
  store: store.scope(state: \.workspace, action: \.workspace),
  configuration: MacWorkspaceShellConfiguration(
    title: "Workspace",
    sidebarPresentation: .floating
  )
) { route in
  AppRouteView(route: route)
}
```

Install native menus from the same command registry:

```swift
.commands {
  MacWorkspaceCommands(
    store: store.scope(state: \.workspace, action: \.workspace)
  )
}
```

The Mac shell is custom-only. It supports:

- `.floating`: rounded inset navigation with split-view-like spacing.
- `.edgeToEdge`: full-height website-style navigation.

### iOS And iPadOS

```swift
import IOSWorkspaceShell

IOSWorkspaceShellView(
  store: store.scope(state: \.workspace, action: \.workspace),
  configuration: IOSWorkspaceShellConfiguration(
    title: "Workspace",
    navigationStyle: .automatic
  )
) { route in
  AppRouteView(route: route)
}
```

The iOS shell resolves to stack navigation on compact widths and split
navigation on regular widths. It includes command search, pins, recent routes,
badges, shortcut labels, route status states, and iPad scene context actions.

## Custom Renderers

You do not need to use the bundled shells. Custom clients can read directly from
`WorkspaceFeature.State`:

- `visibleSections`
- `pinnedRoutes`
- `recentRoutes`
- `selectedRoute`
- `filteredCommands`
- `recentCommands`
- `restorationState`

Dispatch shared actions back into the reducer:

- `.routeSelected(routeID)`
- `.routePinToggled(routeID)`
- `.recentRoutesCleared`
- `.commandPaletteCommandSelected(commandID)`
- `.routeOpenRequested(request)`
- `.routeMetadataPatchesApplied(patches)`

See [`Examples/CustomRendererClient`](Examples/CustomRendererClient) for a
compiled engine-only consumer.

## Optional Integrations

### iCloud-Primary Persistence

Workspace restoration is intentionally small. Persist it with:

- `WorkspacePersistence` for JSON, UserDefaults, and files.
- `WorkspaceSQLiteData` for database records and codecs.
- `WorkspaceCloudKit` for record contracts and conflict policy values.

iCloud remains primary for user-owned data. The package provides payload shapes
and adapter contracts. Your app owns the CloudKit container, subscriptions,
conflict UI, retries, and document data.

### App Intents And Shortcuts

`WorkspaceAutomationBridge` converts the shared command registry into:

- `WorkspaceAutomationCommandDescriptor`
- `WorkspaceAutomationHandoff`
- `WorkspaceAppShortcutDescriptor`

Host app targets bind those descriptors to concrete `AppIntent` and
`AppShortcutsProvider` types. This keeps App Intents thin and app-specific while
the command catalog remains shared.

### Server Companion

`WorkspaceServerClient` is optional and uses
[`Comet`](https://github.com/mrbagels/comet). It provides typed calls for:

- health,
- entitlements,
- templates,
- job submission and status,
- diagnostics upload.

The server is a companion surface, not canonical storage. Keep documents,
workspace restoration, and user-owned data local or iCloud-primary.

## Repository Layout

```text
Sources/                         Swift package products
Tests/                           Package tests and visual-state fixtures
Apps/MacWorkspaceDemo            macOS demo app
Apps/IOSWorkspaceDemo            iOS and iPadOS demo app
Examples/MinimalMacWorkspaceApp  Smallest macOS starter target
Examples/MinimalIOSWorkspaceApp  Smallest iOS starter target
Examples/CustomRendererClient    Engine-only custom renderer package
docs/adoption                    Consumer quickstarts
docs/architecture                Durable architecture docs
docs/features                    Feature briefs
docs/operations                  Verification, API review, release checklists
docs/product                     Roadmap and phased implementation plan
docs/technical                   Package map and implementation notes
```

## Quickstarts

- [Mac shell quickstart](docs/adoption/mac-shell.md)
- [iOS shell quickstart](docs/adoption/ios-shell.md)
- [Engine-only quickstart](docs/adoption/engine-only.md)
- [Custom renderer quickstart](docs/adoption/custom-renderer.md)
- [Persistence adapter guide](docs/adoption/persistence.md)
- [CloudKit adoption guide](docs/adoption/cloudkit.md)
- [Prototype migration guide](docs/adoption/prototype-migration.md)
- [Server companion notes](docs/features/server-side-companion.md)

## Develop

Generate the Xcode project:

```sh
xcodegen generate --spec project.yml
```

Run package tests:

```sh
swift test
```

Run the local verification pass:

```sh
scripts/doctor.sh
scripts/check-docs.sh
scripts/verify.sh
```

Build iOS targets too:

```sh
VERIFY_BUILD_IOS=1 scripts/verify.sh
```

Run UI smoke tests:

```sh
VERIFY_RUN_UI_TESTS=1 scripts/verify.sh
VERIFY_BUILD_IOS=1 VERIFY_RUN_UI_TESTS=1 scripts/verify.sh
```

## Release

Initial public beta: `0.1.0`

Before tagging, run the release checklist and manually inspect the Mac and iOS
demos:

- [API review checklist](docs/operations/api-review-checklist.md)
- [0.1.0 API stability review](docs/operations/api-stability-review-0.1.0.md)
- [Release checklist](docs/operations/release-checklist.md)

## License

MIT. See [LICENSE](LICENSE).
