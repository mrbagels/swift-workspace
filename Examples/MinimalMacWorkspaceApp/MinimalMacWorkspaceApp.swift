import MacWorkspaceShell
import SwiftUI
import WorkspaceEngine

enum MinimalMacRoute: String, Codable, Hashable, Sendable {
  case home
  case settings
}

enum MinimalMacWorkspace {
  static let registry = WorkspaceNavigationRegistry(
    sections: [
      WorkspaceRouteSection(
        id: "main",
        title: "Main",
        routes: [
          WorkspaceRouteDescriptor(
            id: MinimalMacRoute.home,
            title: "Home",
            systemImage: "house",
            shortcut: .command("1")
          ),
          WorkspaceRouteDescriptor(
            id: MinimalMacRoute.settings,
            title: "Settings",
            systemImage: "gearshape",
            keywords: ["preferences"],
            shortcut: .command(","),
            presentation: .fullWidth
          ),
        ]
      ),
    ],
    commands: [
      .appAction(
        id: "refresh",
        title: "Refresh",
        systemImage: "arrow.clockwise",
        shortcut: .command("r")
      ),
    ]
  )

  static let configuration = MacWorkspaceShellConfiguration(
    title: "Minimal Workspace",
    searchPlaceholder: "Search workspace"
  )
}

@main
struct MinimalMacWorkspaceApp: App {
  @State private var store = Store(
    initialState: WorkspaceFeature<MinimalMacRoute>.State(
      navigation: MinimalMacWorkspace.registry,
      selectedRouteID: .home
    )
  ) {
    WorkspaceFeature<MinimalMacRoute>()
  }

  var body: some Scene {
    WindowGroup("Minimal Workspace") {
      MacWorkspaceShellView(
        store: store,
        configuration: MinimalMacWorkspace.configuration
      ) { route in
        MinimalMacRouteView(route: route)
      }
      .frame(minWidth: 820, minHeight: 560)
    }
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unified)
    .defaultSize(width: 960, height: 640)
    .commands {
      MacWorkspaceCommands(store: store)
    }
  }
}

struct MinimalMacRouteView: View {
  let route: WorkspaceRouteDescriptor<MinimalMacRoute>?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label(
        route?.title ?? "Workspace",
        systemImage: route?.systemImage ?? "square.grid.2x2"
      )
      .font(.largeTitle.bold())

      Text("Replace this view with app-owned content for the selected route.")
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
