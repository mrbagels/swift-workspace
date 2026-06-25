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
}

@main
struct MacWorkspaceDemoApp: App {
  @State private var store = Store(
    initialState: WorkspaceFeature<DemoRoute>.State(
      navigation: DemoNavigation.registry,
      selectedRouteID: .inbox
    )
  ) {
    WorkspaceFeature<DemoRoute>()
  }

  var body: some Scene {
    WindowGroup("Workspace Demo") {
      MacWorkspaceShellView(store: store) {
        HStack {
          Image(systemName: "checkmark.icloud")
          Text("iCloud primary")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      } content: { route in
        DemoRouteView(route: route)
      }
      .frame(minWidth: 900, minHeight: 620)
    }
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unified)
    .defaultSize(width: 1100, height: 720)
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
