# Mac Shell Quickstart

`MacWorkspaceShell` renders a `WorkspaceFeature` store with macOS-native chrome,
menus, keyboard shortcuts, command palette support, and route scene handoff.

## 1. Define Routes

Routes stay app-owned and typed:

```swift
enum AppRoute: String, Codable, Hashable, Sendable {
  case inbox
  case settings
}
```

## 2. Build The Registry

Use `WorkspaceNavigationRegistry` for sidebar routes and app commands. Routes
that should open outside the main window declare `scenePresentation`.

```swift
let registry = WorkspaceNavigationRegistry(
  sections: [
    WorkspaceRouteSection(
      id: "main",
      title: "Main",
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

## 3. Own App-Specific Effects

The shell reducer emits delegates for work it should not perform itself. A parent
feature should handle those delegates and keep persistence, networking, and
scene opening app-owned.

```swift
@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var pendingSceneValue: WorkspaceSceneValue<AppRoute>?
    var scenes = WorkspaceSceneCollection<AppRoute>()
    var workspace = WorkspaceFeature<AppRoute>.State(
      navigation: registry,
      selectedRouteID: .inbox
    )
  }

  enum Action: Sendable {
    case sceneOpenHandled(WorkspaceSceneValue<AppRoute>.ID)
    case workspace(WorkspaceFeature<AppRoute>.Action)
  }

  var body: some Reducer<State, Action> {
    Scope(state: \.workspace, action: \.workspace) {
      WorkspaceFeature<AppRoute>()
    }

    Reduce { state, action in
      switch action {
      case .sceneOpenHandled(let id):
        if state.pendingSceneValue?.id == id {
          state.pendingSceneValue = nil
        }
        return .none

      case .workspace(.delegate(.sceneRequested(let request))):
        state.pendingSceneValue = state.scenes.open(
          request,
          encodeRouteID: \.rawValue
        )
        return .none

      case .workspace:
        return .none
      }
    }
  }
}
```

## 4. Render The Shell

The shell consumes the scoped workspace store. It does not own app documents,
server work, or storage writes.

```swift
MacWorkspaceShellView(
  store: store.scope(state: \.workspace, action: \.workspace),
  configuration: MacWorkspaceShellConfiguration(
    title: "Workspace"
  )
) { route in
  AppRouteView(route: route)
}
```

The default Mac renderer is the custom shell. Use
`MacWorkspaceShellConfiguration.nativeSplitView` or pass
`style: .nativeSplitView` only when an app explicitly wants the alternate native
split-view treatment.

## 5. Install Menus

Use `MacWorkspaceCommands` from the scene `commands` builder. It renders command
palette access, primary commands, route commands, scene commands, and app
commands from the shared command registry.

```swift
.commands {
  MacWorkspaceCommands(
    store: store.scope(state: \.workspace, action: \.workspace)
  )
}
```

Customize grouping when needed:

```swift
MacWorkspaceCommands(
  store: workspaceStore,
  configuration: MacWorkspaceCommandMenuConfiguration(
    includesDisabledCommands: true,
    includesPaletteCommand: true,
    grouping: .source
  )
)
```

## 6. Open Route Scenes

Declare a typed `WindowGroup` for `WorkspaceSceneValue`. The parent feature sets
`pendingSceneValue` after receiving a scene delegate, and the root view calls
`openWindow(value:)`.

```swift
WindowGroup("Workspace Route", for: WorkspaceSceneValue<AppRoute>.self) { value in
  if let value = value.wrappedValue {
    AppRouteWindow(value: value)
  } else {
    ContentUnavailableView("No route selected", systemImage: "macwindow")
  }
}
```

```swift
.onChange(of: store.pendingSceneValue) { _, value in
  guard let value else { return }
  openWindow(value: value)
  store.send(.sceneOpenHandled(value.id))
}
```

## Verification

Use the package tests for API coverage and the app build for scene and menu
wiring:

```sh
swift test
scripts/verify.sh
```
