import Foundation
import WorkspaceCore
import WorkspacePersistence
import WorkspaceTCA

public enum CustomRendererRoute: String, CaseIterable, Codable, Hashable, Sendable {
  case dashboard
  case reports
  case settings
}

public struct CustomRendererRouteSnapshot: Equatable, Sendable {
  public var badge: Int?
  public var isEnabled: Bool
  public var routeID: CustomRendererRoute
  public var systemImage: String
  public var title: String

  public init(
    routeID: CustomRendererRoute,
    title: String,
    systemImage: String,
    badge: Int?,
    isEnabled: Bool
  ) {
    self.badge = badge
    self.isEnabled = isEnabled
    self.routeID = routeID
    self.systemImage = systemImage
    self.title = title
  }
}

public struct CustomRendererSectionSnapshot: Equatable, Sendable {
  public var id: WorkspaceRouteSectionID
  public var routes: [CustomRendererRouteSnapshot]
  public var title: String

  public init(
    id: WorkspaceRouteSectionID,
    title: String,
    routes: [CustomRendererRouteSnapshot]
  ) {
    self.id = id
    self.routes = routes
    self.title = title
  }
}

public struct CustomRendererSnapshot: Equatable, Sendable {
  public var commandSections: [WorkspaceCommandSection<CustomRendererRoute>]
  public var sections: [CustomRendererSectionSnapshot]
  public var selectedRouteID: CustomRendererRoute
  public var selectedRouteTitle: String?

  public init(
    selectedRouteID: CustomRendererRoute,
    selectedRouteTitle: String?,
    sections: [CustomRendererSectionSnapshot],
    commandSections: [WorkspaceCommandSection<CustomRendererRoute>]
  ) {
    self.commandSections = commandSections
    self.sections = sections
    self.selectedRouteID = selectedRouteID
    self.selectedRouteTitle = selectedRouteTitle
  }
}

public enum CustomRendererClient {
  public static let navigation = WorkspaceNavigationRegistry(
    sections: [
      WorkspaceRouteSection(
        id: "main",
        title: "Main",
        routes: [
          WorkspaceRouteDescriptor(
            id: CustomRendererRoute.dashboard,
            title: "Dashboard",
            systemImage: "gauge.with.dots.needle",
            badge: 3,
            keywords: ["home", "overview"],
            shortcut: .command("1")
          ),
          WorkspaceRouteDescriptor(
            id: CustomRendererRoute.reports,
            title: "Reports",
            systemImage: "chart.bar.xaxis",
            keywords: ["analytics", "exports"],
            shortcut: .command("2")
          ),
        ]
      ),
      WorkspaceRouteSection(
        id: "system",
        title: "System",
        routes: [
          WorkspaceRouteDescriptor(
            id: CustomRendererRoute.settings,
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
        id: "refresh",
        title: "Refresh",
        systemImage: "arrow.clockwise",
        keywords: ["reload", "sync"],
        shortcut: .command("r")
      ),
    ]
  )

  public static func initialState(
    selectedRouteID: CustomRendererRoute = .dashboard
  ) -> WorkspaceFeature<CustomRendererRoute>.State {
    WorkspaceFeature.State(
      navigation: navigation,
      selectedRouteID: selectedRouteID
    )
  }

  public static func snapshot(
    from state: WorkspaceFeature<CustomRendererRoute>.State,
    commandGrouping: WorkspaceCommandGrouping = .category
  ) -> CustomRendererSnapshot {
    CustomRendererSnapshot(
      selectedRouteID: state.selectedRouteID,
      selectedRouteTitle: state.selectedRoute?.title,
      sections: state.visibleSections.map(sectionSnapshot),
      commandSections: WorkspaceCommandSections.make(
        for: state.availableCommands,
        grouping: commandGrouping,
        includesDisabledCommands: false
      )
    )
  }

  public static func persistence(
    fileURL: URL
  ) -> WorkspaceFilePersistence<CustomRendererRoute> {
    WorkspaceFilePersistence(fileURL: fileURL)
  }

  private static func sectionSnapshot(
    _ section: WorkspaceRouteSection<CustomRendererRoute>
  ) -> CustomRendererSectionSnapshot {
    CustomRendererSectionSnapshot(
      id: section.id,
      title: section.title,
      routes: section.routes.map { route in
        CustomRendererRouteSnapshot(
          routeID: route.id,
          title: route.title,
          systemImage: route.systemImage,
          badge: route.badge,
          isEnabled: route.availability.isEnabled
        )
      }
    )
  }
}
