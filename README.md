# swift-workspace

Reusable Swift workspace engine, platform shells, and optional persistence
adapters for apps that need professional navigation, commands, scenes, and
restoration without hardwiring that behavior to one app.

`swift-workspace` gives you the engine in pieces or as a whole:

- use `WorkspaceCore` for typed routes, commands, scenes, search, policy, and
  restoration,
- add `WorkspaceTCA` when you want the shared reducer to own workspace behavior,
- add `MacWorkspaceShell` or `IOSWorkspaceShell` when you want a ready-made
  platform shell,
- add persistence, SQLiteData, or CloudKit contracts only when the app needs
  them,
- build your own renderer when the product needs custom UI.

The package is intentionally app-agnostic. Your app owns documents, workflow
state, persistence writes, analytics, network calls, and server-backed effects.
The engine owns the boring shared workspace mechanics.

## Status

Initial public beta: `0.1.0`

The package is ready for early adoption after manual demo QA. Public APIs are
reviewed for the `0.1.0` surface, but source-breaking changes may still happen
before `1.0.0`.

## Install

Add the package in Xcode or SwiftPM:

```swift
.package(
  url: "https://github.com/mrbagels/swift-workspace",
  from: "0.1.0"
)
```

Then choose only the products your app needs:

```swift
.product(name: "WorkspaceCore", package: "swift-workspace")
.product(name: "WorkspaceTCA", package: "swift-workspace")
.product(name: "MacWorkspaceShell", package: "swift-workspace")
.product(name: "IOSWorkspaceShell", package: "swift-workspace")
```

## Products

| Product | Use it when |
| --- | --- |
| `WorkspaceCore` | You need route, command, scene, search, policy, and restoration models. |
| `WorkspaceTCA` | You want a shared TCA reducer for workspace behavior. |
| `WorkspaceEngine` | You want a convenience import for the core engine stack. |
| `WorkspacePersistence` | You want JSON, UserDefaults, or file-backed restoration helpers. |
| `WorkspaceSQLiteData` | You want SQLiteData records, migrations, and codecs. |
| `WorkspaceCloudKit` | You want CloudKit/iCloud contracts while keeping sync app-owned. |
| `MacWorkspaceShell` | You want the custom macOS shell renderer. |
| `IOSWorkspaceShell` | You want the adaptive iOS and iPadOS shell renderer. |

## How It Works

The app defines typed routes and a navigation registry:

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
          shortcut: .command("1")
        ),
        WorkspaceRouteDescriptor(
          id: AppRoute.settings,
          title: "Settings",
          systemImage: "gearshape",
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

The shared reducer owns workspace mechanics:

```swift
import ComposableArchitecture
import WorkspaceTCA

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var workspace = WorkspaceFeature<AppRoute>.State(
      navigation: registry,
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
      case .workspace(.delegate(.appCommandRequested(let commandID))):
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

Platform shells render that same reducer state.

## macOS Shell

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

`MacWorkspaceShell` is custom-only. It supports two sidebar presentations:

- `.floating`: rounded inset navigation that feels close to native split-view
  spacing.
- `.edgeToEdge`: full-height website-style navigation.

Install macOS menus from the same command registry:

```swift
.commands {
  MacWorkspaceCommands(
    store: store.scope(state: \.workspace, action: \.workspace)
  )
}
```

## iOS And iPadOS Shell

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

The iOS shell uses stack navigation in compact layouts and split navigation on
regular layouts. It includes command search, badge rendering, hardware shortcut
display, and iPad scene handoff.

## Custom Renderer

You do not have to use the bundled shells. Custom clients can read directly from
`WorkspaceFeature.State`:

- `visibleSections` for navigation,
- `selectedRoute` and `selectedRouteID` for content,
- `filteredCommands` and `selectedCommand` for command search,
- `recentCommandIDs` for recents,
- delegate actions for app-owned effects.

See `Examples/CustomRendererClient` for a compiled engine-only consumer.

## Persistence And iCloud

Workspace restoration is intentionally small. Persist it with:

- `WorkspacePersistence` for JSON, UserDefaults, or files,
- `WorkspaceSQLiteData` for local database integration,
- `WorkspaceCloudKit` for iCloud record contracts and conflict policy values,
- app-owned storage when documents or workflow state are involved.

iCloud remains primary for user-owned data. The package provides contracts and
payload shapes; the consuming app owns the CloudKit container, sync lifecycle,
conflict presentation, and retry behavior.

## Project Layout

```text
Sources/                         Package products
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

## Develop

Generate the Xcode project:

```sh
xcodegen generate --spec project.yml
```

Run the package tests:

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

`project.yml` is set to `MARKETING_VERSION: 0.1.0`. Before creating a public
tag, run the release checklist and manually inspect the Mac and iOS demos:

- [API review checklist](docs/operations/api-review-checklist.md)
- [0.1.0 API stability review](docs/operations/api-stability-review-0.1.0.md)
- [Release checklist](docs/operations/release-checklist.md)

## License

MIT. See [LICENSE](LICENSE).
