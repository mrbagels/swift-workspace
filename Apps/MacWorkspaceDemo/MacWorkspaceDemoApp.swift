import MacWorkspaceShell
import SwiftUI
import WorkspaceEngine

enum DemoRoute: String, CaseIterable, Codable, Hashable, Sendable {
  case inbox
  case review
  case automations
  case settings
}

enum DemoNavigation {
  static let macConfiguration = MacWorkspaceShellConfiguration(
    title: "Workspace Demo",
    style: .nativeSplitView,
    searchPlaceholder: "Search demo commands"
  )

  static let registry = WorkspaceNavigationRegistry(
    sections: [
      WorkspaceRouteSection(
        id: "workspace",
        title: "Workspace",
        routes: [
          WorkspaceRouteDescriptor(
            id: DemoRoute.inbox,
            title: "Inbox",
            systemImage: "tray.full",
            badge: 12,
            keywords: ["queue", "triage"],
            shortcut: .command("1")
          ),
          WorkspaceRouteDescriptor(
            id: DemoRoute.review,
            title: "Review",
            systemImage: "checklist",
            badge: 4,
            keywords: ["approval", "work"],
            shortcut: .command("2")
          ),
          WorkspaceRouteDescriptor(
            id: DemoRoute.automations,
            title: "Automations",
            systemImage: "wand.and.sparkles",
            availability: .disabled(reason: "Coming in a later phase"),
            keywords: ["rules", "actions"],
            shortcut: .command("3")
          ),
        ]
      ),
      WorkspaceRouteSection(
        id: "system",
        title: "System",
        routes: [
          WorkspaceRouteDescriptor(
            id: DemoRoute.settings,
            title: "Settings",
            systemImage: "gearshape",
            keywords: ["preferences"],
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
        keywords: ["reload", "sync"],
        shortcut: .command("r")
      ),
    ]
  )

  static func route(for id: DemoRoute) -> WorkspaceRouteDescriptor<DemoRoute>? {
    registry.sections
      .lazy
      .flatMap(\.routes)
      .first { $0.id == id }
  }
}

@Reducer
struct MacWorkspaceDemoFeature {
  @ObservableState
  struct State: Equatable {
    var pendingSceneValue: WorkspaceSceneValue<DemoRoute>?
    var scenes: WorkspaceSceneCollection<DemoRoute>
    var workspace: WorkspaceFeature<DemoRoute>.State

    init(
      pendingSceneValue: WorkspaceSceneValue<DemoRoute>? = nil,
      scenes: WorkspaceSceneCollection<DemoRoute> = .init(),
      workspace: WorkspaceFeature<DemoRoute>.State = .init(
        navigation: DemoNavigation.registry,
        selectedRouteID: .inbox
      )
    ) {
      self.pendingSceneValue = pendingSceneValue
      self.scenes = scenes
      self.workspace = workspace
    }
  }

  enum Action: Sendable {
    case sceneOpenHandled(WorkspaceSceneValue<DemoRoute>.ID)
    case workspace(WorkspaceFeature<DemoRoute>.Action)
  }

  var body: some Reducer<State, Action> {
    Scope(state: \.workspace, action: \.workspace) {
      WorkspaceFeature<DemoRoute>()
    }

    Reduce { state, action in
      switch action {
      case .sceneOpenHandled(let id):
        guard state.pendingSceneValue?.id == id
        else { return .none }
        state.pendingSceneValue = nil
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

@main
struct MacWorkspaceDemoApp: App {
  @State private var store = Store(
    initialState: MacWorkspaceDemoFeature.State()
  ) {
    MacWorkspaceDemoFeature()
  }

  var body: some Scene {
    WindowGroup("Workspace Demo") {
      MacWorkspaceDemoRootView(store: store)
        .frame(minWidth: 900, minHeight: 620)
    }
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unified)
    .defaultSize(width: 1100, height: 720)
    .commands {
      MacWorkspaceCommands(
        store: store.scope(state: \.workspace, action: \.workspace)
      )
    }

    WindowGroup("Workspace Route", for: WorkspaceSceneValue<DemoRoute>.self) { sceneValue in
      if let sceneValue = sceneValue.wrappedValue {
        MacWorkspaceDemoRouteWindowView(sceneValue: sceneValue)
      } else {
        ContentUnavailableView("No route selected", systemImage: "macwindow")
      }
    }
    .defaultSize(width: 900, height: 660)
  }
}

struct MacWorkspaceDemoRootView: View {
  @Environment(\.openWindow) private var openWindow
  let store: StoreOf<MacWorkspaceDemoFeature>

  var body: some View {
    let workspaceStore = store.scope(state: \.workspace, action: \.workspace)

    MacWorkspaceShellView(
      store: workspaceStore,
      configuration: DemoNavigation.macConfiguration
    ) {
      HStack {
        Image(systemName: "checkmark.icloud")
        Text("iCloud primary")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    } content: { route in
      DemoRouteView(route: route)
    }
    .onChange(of: store.pendingSceneValue) { _, pendingSceneValue in
      guard let pendingSceneValue
      else { return }
      openWindow(value: pendingSceneValue)
      store.send(.sceneOpenHandled(pendingSceneValue.id))
    }
  }
}

struct MacWorkspaceDemoRouteWindowView: View {
  let sceneValue: WorkspaceSceneValue<DemoRoute>

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 10) {
        Image(systemName: route?.systemImage ?? fallbackSystemImage)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.tint)

        VStack(alignment: .leading, spacing: 2) {
          Text(sceneValue.title ?? route?.title ?? "Workspace Route")
            .font(.system(size: 14, weight: .semibold))
          Text(sceneValue.restorationKey)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 18)
      .frame(height: 54)

      Divider()

      DemoRouteView(route: route)
    }
    .frame(minWidth: 760, minHeight: 560)
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("workspace-route-window-\(sceneValue.id)")
  }

  private var route: WorkspaceRouteDescriptor<DemoRoute>? {
    DemoNavigation.route(for: sceneValue.route)
  }

  private var fallbackSystemImage: String {
    switch sceneValue.kind {
    case .document:
      "doc"
    case .primary:
      "macwindow"
    case .singleton:
      "macwindow.on.rectangle"
    case .utility:
      "sidebar.right"
    }
  }
}

struct DemoRouteView: View {
  let route: WorkspaceRouteDescriptor<DemoRoute>?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Label(route?.title ?? "Workspace", systemImage: route?.systemImage ?? "square.grid.2x2")
        .font(.largeTitle.bold())

      Text("This demo is backed by the new platform-neutral workspace engine.")
        .foregroundStyle(.secondary)

      if let route {
        Text("Route ID: \(route.id.rawValue)")
          .font(.callout.monospaced())
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(32)
  }
}
