# Engine-Only Quickstart

Use the engine-only path when an app wants workspace routing, commands, scenes,
search, policy, and restoration without a bundled Mac or iOS shell.

## Products

Start with the smallest imports that match the app's needs:

```swift
import WorkspaceCore
import WorkspaceTCA
```

Add `WorkspaceEngine` when the app wants the convenience umbrella:

```swift
import WorkspaceEngine
```

Add optional adapters only when needed:

- `WorkspacePersistence` for JSON, UserDefaults, and file-backed restoration.
- `WorkspaceSQLiteData` for SQLiteData record and codec helpers.
- `WorkspaceCloudKit` for CloudKit/iCloud adapter contracts.

## 1. Define A Route Type

```swift
enum AppRoute: String, Codable, Hashable, Sendable {
  case dashboard
  case projects
  case settings
}
```

## 2. Build Shared Navigation

```swift
let registry = WorkspaceNavigationRegistry(
  sections: [
    WorkspaceRouteSection(
      id: "workspace",
      title: "Workspace",
      routes: [
        WorkspaceRouteDescriptor(
          id: AppRoute.dashboard,
          title: "Dashboard",
          systemImage: "square.grid.2x2"
        ),
        WorkspaceRouteDescriptor(
          id: AppRoute.projects,
          title: "Projects",
          systemImage: "folder"
        ),
      ]
    ),
    WorkspaceRouteSection(
      id: "system",
      title: "System",
      routes: [
        WorkspaceRouteDescriptor(
          id: AppRoute.settings,
          title: "Settings",
          systemImage: "gearshape",
          presentation: .fullWidth,
          scenePresentation: .singleton(id: "settings", title: "Settings")
        ),
      ]
    ),
  ],
  commands: [
    .primaryAction(
      id: "new-project",
      title: "New Project",
      systemImage: "plus"
    ),
  ]
)
```

## 3. Own The Reducer

`WorkspaceFeature` gives the app shared workspace behavior. Parent features own
effects, storage, network calls, and domain state.

```swift
@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var workspace = WorkspaceFeature<AppRoute>.State(
      navigation: registry,
      selectedRouteID: .dashboard
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

## 4. Render Your Own UI

Custom clients should read from `WorkspaceFeature.State` and send actions back
to the reducer:

- `visibleSections` for navigation.
- `selectedRoute` and `selectedRouteID` for content.
- `filteredCommands`, `selectedCommand`, and `commandPaletteQuery` for command
  search.
- `recentCommandIDs` for recents.
- delegate actions for app-owned effects.

The checked-in `Examples/CustomRendererClient` package proves this usage without
importing bundled platform shells.

## 5. Persist Restoration

```swift
let persistence = WorkspaceFilePersistence<AppRoute>(
  fileURL: applicationSupportURL.appendingPathComponent("workspace.json")
)

try persistence.save(store.workspace.restorationState)
let restored = try persistence.load()
```

Keep platform chrome outside shared restoration. Mac apps should wrap shared
state in `MacWorkspaceRestoration`; iOS apps should wrap it in
`IOSWorkspaceRestoration`.

## Verification

```sh
swift test
swift test --package-path Examples/CustomRendererClient
```
