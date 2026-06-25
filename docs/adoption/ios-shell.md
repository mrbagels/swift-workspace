# iOS Shell Quickstart

`IOSWorkspaceShell` renders the shared workspace engine with native iOS and
iPadOS navigation. It uses the same `WorkspaceFeature` reducer as the Mac shell,
but it owns its own presentation choices: stack navigation on compact widths,
split navigation on regular widths, a command-search sheet, route badges, and
iPad scene handoff.

## 1. Define Routes

Routes stay app-owned and typed. Use a stable `Codable` representation when the
app wants restoration, CloudKit envelopes, or scene values.

```swift
enum AppRoute: String, Codable, Hashable, Sendable {
  case inbox
  case review
  case settings
}
```

## 2. Build The Registry

The iOS shell consumes the same route registry as any other renderer. Route
metadata should describe shared intent, not platform layout.

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
          badge: 8,
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

## 3. Own App Effects

The shell can request route selection, command execution, and scene opening, but
the app decides what those requests do. Keep persistence, networking, analytics,
server work, document loading, and CloudKit writes in the parent app feature.

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

Use `.automatic` for normal apps. It resolves to stack navigation on compact
widths and split navigation on regular widths. Force `.stack` or `.split` only
when the app has a strong product reason.

```swift
IOSWorkspaceShellView(
  store: store.scope(state: \.workspace, action: \.workspace),
  configuration: IOSWorkspaceShellConfiguration(
    title: "Workspace",
    navigationStyle: .automatic,
    commandSearchPlaceholder: "Search workspace",
    prefersBadges: true
  )
) { route in
  AppRouteView(route: route)
}
```

## 5. Restore iOS Chrome

Shared restoration belongs in `WorkspaceRestoration`. iOS presentation state
belongs in `IOSWorkspaceRestoration`.

```swift
let restoration = IOSWorkspaceRestoration(
  workspace: WorkspaceRestoration(
    selectedRouteID: AppRoute.inbox,
    collapsedSectionIDs: [],
    recentCommandIDs: []
  ),
  columnPreference: .automatic,
  compactNavigationPath: [.inbox]
)
```

Persist this payload with `WorkspacePersistence`, CloudKit, SQLiteData, or
app-owned storage. The shell should not write storage directly.

## 6. Open iPad Scenes

Routes that declare `scenePresentation` expose an "Open in New Window" context
action. The app receives a scene delegate and decides whether to call
`openWindow(value:)`.

```swift
WindowGroup("Workspace Route", for: WorkspaceSceneValue<AppRoute>.self) { value in
  if let value = value.wrappedValue {
    AppRouteWindow(value: value)
  } else {
    ContentUnavailableView("No route selected", systemImage: "rectangle.split.2x1")
  }
}
```

## Accessibility And Automation

The shell exposes stable accessibility identifiers for the root shell, route
list, route rows, command-search trigger, recent-command clearing, command-search
sheet, search field, results, and detail pane. UI tests should target these
identifiers instead of localized text.

## Verification

Use package tests for configuration and restoration coverage, then build the iOS
demo to compile the iOS-only SwiftUI renderer:

```sh
swift test --filter IOSWorkspaceShell
VERIFY_BUILD_IOS=1 scripts/verify.sh
```
