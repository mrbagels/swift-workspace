import IOSWorkspaceShell
import SwiftUI
import WorkspaceEngine

enum MinimalIOSRoute: String, Codable, Hashable, Sendable {
  case home
  case settings
}

enum MinimalIOSWorkspace {
  static let registry = WorkspaceNavigationRegistry(
    sections: [
      WorkspaceRouteSection(
        id: "main",
        title: "Main",
        routes: [
          WorkspaceRouteDescriptor(
            id: MinimalIOSRoute.home,
            title: "Home",
            systemImage: "house",
            shortcut: .command("1")
          ),
          WorkspaceRouteDescriptor(
            id: MinimalIOSRoute.settings,
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

  static let configuration = IOSWorkspaceShellConfiguration(
    title: "Minimal Workspace",
    commandSearchPlaceholder: "Search workspace"
  )
}

@main
struct MinimalIOSWorkspaceApp: App {
  @State private var store = Store(
    initialState: WorkspaceFeature<MinimalIOSRoute>.State(
      navigation: MinimalIOSWorkspace.registry,
      selectedRouteID: .home
    )
  ) {
    WorkspaceFeature<MinimalIOSRoute>()
  }

  var body: some Scene {
    WindowGroup {
      IOSWorkspaceShellView(
        store: store,
        configuration: MinimalIOSWorkspace.configuration
      ) { route in
        MinimalIOSRouteView(route: route)
      }
    }
  }
}

struct MinimalIOSRouteView: View {
  let route: WorkspaceRouteDescriptor<MinimalIOSRoute>?

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
    .padding(24)
  }
}
