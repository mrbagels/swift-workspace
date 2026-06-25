import Foundation
import IOSWorkspaceShell
import Testing
import WorkspaceCore

private enum VisualRoute: String, Codable, Hashable, Sendable {
  case inbox
  case review
  case settings
}

@Test
func compactIOSShellVisualStateMatchesFixture() throws {
  let actual = IOSShellVisualStateDescriptor(
    configuration: .visualState(navigationStyle: .automatic),
    restoration: IOSWorkspaceRestoration(
      workspace: WorkspaceRestoration(
        selectedRouteID: VisualRoute.inbox,
        collapsedSectionIDs: [],
        recentCommandIDs: [.appAction("refresh-workspace")]
      ),
      columnPreference: .content,
      compactNavigationPath: [.inbox]
    ),
    registry: .visualState,
    isCompactWidth: true
  )
  .render()

  try expectSnapshot(actual, named: "compact-visual-state.txt")
}

@Test
func splitIOSShellVisualStateMatchesFixture() throws {
  let actual = IOSShellVisualStateDescriptor(
    configuration: .visualState(navigationStyle: .split),
    restoration: IOSWorkspaceRestoration(
      workspace: WorkspaceRestoration(
        selectedRouteID: VisualRoute.settings,
        collapsedSectionIDs: ["workspace"],
        recentCommandIDs: [.scene(.settings), .route(.inbox)]
      ),
      columnPreference: .sidebar,
      compactNavigationPath: []
    ),
    registry: .visualState,
    isCompactWidth: false
  )
  .render()

  try expectSnapshot(actual, named: "split-visual-state.txt")
}

private func expectSnapshot(
  _ actual: String,
  named name: String,
  sourceLocation: SourceLocation = #_sourceLocation
) throws {
  let snapshotURL = try #require(
    Bundle.module.url(
      forResource: name,
      withExtension: nil
    )
  )
  let expected = try String(contentsOf: snapshotURL, encoding: .utf8)

  #expect(actual == expected, sourceLocation: sourceLocation)
}

private struct IOSShellVisualStateDescriptor<RouteID: Hashable & Sendable> {
  var configuration: IOSWorkspaceShellConfiguration
  var restoration: IOSWorkspaceRestoration<RouteID>
  var registry: WorkspaceNavigationRegistry<RouteID>
  var isCompactWidth: Bool

  func render() -> String {
    var lines: [String] = []
    let selectedRoute = route(for: restoration.workspace.selectedRouteID)
    let selectedPresentation = selectedRoute?.presentation.rawValue ?? "missing"
    let selectedScene = selectedRoute?.scenePresentation.kind.rawValue ?? "missing"

    lines.append("IOSWorkspaceShellVisualState")
    lines.append("navigation-style: \(configuration.navigationStyle.rawValue)")
    lines.append("resolved-navigation: \(usesStackNavigation ? "stack" : "split")")
    lines.append("title: \(configuration.title)")
    lines.append("badges: \(configuration.prefersBadges ? "visible" : "hidden")")
    lines.append("selected: \(routeName(restoration.workspace.selectedRouteID))")
    lines.append("selected-presentation: \(selectedPresentation)")
    lines.append("selected-scene: \(selectedScene)")
    lines.append("column-preference: \(restoration.columnPreference.rawValue)")
    lines.append("compact-path: \(compactPathLine)")
    lines.append("palette: placeholder=\"\(configuration.commandSearchPlaceholder)\"")
    lines.append("surfaces:")
    for surface in surfaces(for: selectedRoute) {
      lines.append("- \(surface)")
    }
    lines.append("sections:")
    for section in registry.sections {
      let isExpanded = !section.isCollapsible
        || !restoration.workspace.collapsedSectionIDs.contains(section.id)
      lines.append("- \(section.title) [\(isExpanded ? "expanded" : "collapsed")]")
      guard isExpanded else { continue }
      for route in section.routes where route.availability.isVisible {
        lines.append("  - \(routeLine(route))")
      }
    }
    lines.append("command-sections:")
    for section in WorkspaceCommandSections.make(
      for: commands,
      grouping: .category,
      includesDisabledCommands: true
    ) {
      lines.append("- \(section.title)")
      for command in section.commands {
        lines.append("  - \(commandLine(command))")
      }
    }
    lines.append("accessibility:")
    for anchor in accessibilityAnchors(selectedRoute: selectedRoute) {
      lines.append("- \(anchor)")
    }
    return lines.joined(separator: "\n") + "\n"
  }

  private var commands: [WorkspaceCommand<RouteID>] {
    registry.routeCommands + registry.sceneCommands + registry.commands
  }

  private var compactPathLine: String {
    if restoration.compactNavigationPath.isEmpty {
      return "empty"
    }

    return restoration.compactNavigationPath
      .map(routeName)
      .joined(separator: " > ")
  }

  private var usesStackNavigation: Bool {
    configuration.usesStackNavigation(isCompactWidth: isCompactWidth)
  }

  private func accessibilityAnchors(
    selectedRoute: WorkspaceRouteDescriptor<RouteID>?
  ) -> [String] {
    var anchors = [
      "ios-workspace-shell",
      "ios-workspace-route-list",
      "ios-workspace-command-search-button",
      "ios-workspace-clear-recent-commands-button",
    ]

    if let selectedRoute {
      anchors.append("ios-workspace-route-\(identifierComponent(routeName(selectedRoute.id)))")
      anchors.append("ios-workspace-detail-\(identifierComponent(routeName(selectedRoute.id)))")
      if selectedRoute.scenePresentation.opensInSeparateScene {
        anchors.append("ios-workspace-open-scene-\(identifierComponent(routeName(selectedRoute.id)))")
      }
    }

    anchors.append("ios-workspace-command-search")
    anchors.append("ios-workspace-command-search-field")
    anchors.append("ios-workspace-command-search-results")
    return anchors
  }

  private func commandLine(_ command: WorkspaceCommand<RouteID>) -> String {
    [
      commandID(command.id),
      "\"\(command.title)\"",
      command.isEnabled ? "enabled" : "disabled",
      "role=\(command.role.rawValue)",
      "source=\(command.source.rawValue)",
      "shortcut=\(command.shortcut?.displayLabel ?? "none")",
    ]
    .joined(separator: " ")
  }

  private func routeLine(_ route: WorkspaceRouteDescriptor<RouteID>) -> String {
    [
      routeName(route.id),
      "\"\(route.title)\"",
      route.id == restoration.workspace.selectedRouteID ? "selected" : "unselected",
      route.availability.isEnabled ? "enabled" : "disabled",
      "badge=\(route.badge.map(String.init) ?? "none")",
      "shortcut=\(route.shortcut?.displayLabel ?? "none")",
      "presentation=\(route.presentation.rawValue)",
      "scene=\(route.scenePresentation.kind.rawValue)",
    ]
    .joined(separator: " ")
  }

  private func route(
    for id: RouteID
  ) -> WorkspaceRouteDescriptor<RouteID>? {
    registry.sections
      .lazy
      .flatMap(\.routes)
      .first { $0.id == id }
  }

  private func surfaces(
    for route: WorkspaceRouteDescriptor<RouteID>?
  ) -> [String] {
    var surfaces = [
      usesStackNavigation ? "navigation-stack" : "navigation-split-view",
      "route-list",
    ]

    switch route?.presentation {
    case .listDetail:
      surfaces.append("detail")
    case .fullWidth:
      surfaces.append("full-width-detail")
    case nil:
      surfaces.append("empty-detail")
    }

    if usesStackNavigation, !restoration.compactNavigationPath.isEmpty {
      surfaces.append("compact-navigation-path")
    }

    return surfaces
  }

  private func commandID(_ id: WorkspaceCommandIdentifier<RouteID>) -> String {
    switch id {
    case .appAction(let id):
      "app:\(id.rawValue)"
    case .primaryAction(let id):
      "primary:\(id.rawValue)"
    case .route(let id):
      "route:\(routeName(id))"
    case .scene(let id):
      "scene:\(routeName(id))"
    case .system(let id):
      "system:\(id.rawValue)"
    case .toolbarAction(let id):
      "toolbar:\(id.rawValue)"
    }
  }

  private func identifierComponent(_ value: String) -> String {
    var identifier = ""
    var previousWasSeparator = false

    for scalar in value.lowercased().unicodeScalars {
      if CharacterSet.alphanumerics.contains(scalar) {
        identifier.unicodeScalars.append(scalar)
        previousWasSeparator = false
      } else if !previousWasSeparator {
        identifier.append("-")
        previousWasSeparator = true
      }
    }

    let trimmed = identifier.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return trimmed.isEmpty ? "unknown" : trimmed
  }

  private func routeName(_ routeID: RouteID) -> String {
    String(describing: routeID)
  }
}

private extension IOSWorkspaceShellConfiguration {
  static func visualState(navigationStyle: IOSWorkspaceNavigationStyle) -> Self {
    Self(
      title: "Workspace Demo",
      navigationStyle: navigationStyle,
      commandSearchPlaceholder: "Search demo commands and routes",
      prefersBadges: true
    )
  }
}

private extension WorkspaceNavigationRegistry where RouteID == VisualRoute {
  static let visualState = Self(
    sections: [
      WorkspaceRouteSection(
        id: "workspace",
        title: "Workspace",
        isCollapsible: true,
        routes: [
          WorkspaceRouteDescriptor(
            id: .inbox,
            title: "Inbox",
            systemImage: "tray.full",
            badge: 12,
            keywords: ["queue", "triage"],
            shortcut: WorkspaceKeyboardShortcut(
              key: "1",
              displayTitle: "Cmd+1"
            )
          ),
          WorkspaceRouteDescriptor(
            id: .review,
            title: "Review",
            systemImage: "checklist",
            availability: .disabled(reason: "Requires approval"),
            badge: 4,
            keywords: ["approval"],
            shortcut: WorkspaceKeyboardShortcut(
              key: "2",
              displayTitle: "Cmd+2"
            )
          ),
        ]
      ),
      WorkspaceRouteSection(
        id: "system",
        title: "System",
        routes: [
          WorkspaceRouteDescriptor(
            id: .settings,
            title: "Settings",
            systemImage: "gearshape",
            keywords: ["preferences"],
            shortcut: WorkspaceKeyboardShortcut(
              key: ",",
              displayTitle: "Cmd+,"
            ),
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
        shortcut: WorkspaceKeyboardShortcut(
          key: "r",
          displayTitle: "Cmd+R"
        )
      ),
      .toolbarAction(
        id: "export-workspace",
        title: "Export",
        systemImage: "square.and.arrow.up",
        keywords: ["share"],
        shortcut: WorkspaceKeyboardShortcut(
          key: "e",
          displayTitle: "Cmd+E"
        )
      ),
      .primaryAction(
        id: "new-item",
        title: "New Item",
        systemImage: "plus",
        keywords: ["create"],
        shortcut: WorkspaceKeyboardShortcut(
          key: "n",
          displayTitle: "Cmd+N"
        )
      ),
    ]
  )
}
