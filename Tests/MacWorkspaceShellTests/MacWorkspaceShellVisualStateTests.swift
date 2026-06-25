#if os(macOS)
  import Foundation
  import MacWorkspaceShell
  import Testing
  import WorkspaceCore

  private enum VisualRoute: String, Codable, Hashable, Sendable {
    case inbox
    case review
    case settings
  }

  @Test
  func nativeMacShellVisualStateMatchesFixture() throws {
    let actual = MacShellVisualStateDescriptor(
      configuration: .visualState(style: .nativeSplitView),
      restoration: MacWorkspaceRestoration(
        workspace: WorkspaceRestoration(
          selectedRouteID: VisualRoute.inbox,
          collapsedSectionIDs: [],
          recentCommandIDs: [.appAction("refresh-workspace")]
        ),
        isSidebarVisible: true,
        isInspectorPresented: false,
        density: .compact,
        style: .nativeSplitView
      ),
      registry: .visualState
    )
    .render()

    try expectSnapshot(actual, named: "native-split-visual-state.txt")
  }

  @Test
  func customMacShellVisualStateMatchesFixture() throws {
    let actual = MacShellVisualStateDescriptor(
      configuration: .visualState(style: .custom),
      restoration: MacWorkspaceRestoration(
        workspace: WorkspaceRestoration(
          selectedRouteID: VisualRoute.settings,
          collapsedSectionIDs: ["workspace"],
          recentCommandIDs: [.scene(.settings), .route(.inbox)]
        ),
        isSidebarVisible: false,
        isInspectorPresented: true,
        columnWidths: MacWorkspaceColumnWidths(
          sidebar: 300,
          list: 360,
          detail: 640,
          inspector: 340
        ),
        density: .comfortable,
        style: .custom
      ),
      registry: .visualState
    )
    .render()

    try expectSnapshot(actual, named: "custom-inspector-visual-state.txt")
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

  private struct MacShellVisualStateDescriptor<RouteID: Hashable & Sendable> {
    var configuration: MacWorkspaceShellConfiguration
    var restoration: MacWorkspaceRestoration<RouteID>
    var registry: WorkspaceNavigationRegistry<RouteID>

    func render() -> String {
      var lines: [String] = []
      let selectedRoute = route(for: restoration.workspace.selectedRouteID)
      let selectedPresentation = selectedRoute?.presentation.rawValue ?? "missing"
      let selectedScene = selectedRoute?.scenePresentation.kind.rawValue ?? "missing"

      lines.append("MacWorkspaceShellVisualState")
      lines.append("style: \(resolvedStyle.rawValue)")
      lines.append("density: \(restoration.density.rawValue)")
      lines.append("brand: \(configuration.brand.title) (\(configuration.brand.tint.rawValue))")
      lines.append("sidebar: \(restoration.isSidebarVisible ? "visible" : "hidden")")
      lines.append("inspector: \(restoration.isInspectorPresented ? "visible" : "hidden")")
      lines.append("selected: \(routeName(restoration.workspace.selectedRouteID))")
      lines.append("selected-presentation: \(selectedPresentation)")
      lines.append("selected-scene: \(selectedScene)")
      lines.append(widthsLine)
      lines.append(paletteLine)
      lines.append("panes:")
      for pane in panes(for: selectedRoute) {
        lines.append("- \(pane)")
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

    private var paletteLine: String {
      let behavior = configuration.behavior
      return [
        "palette: width=\(integer(behavior.commandPaletteWidth))",
        "top=\(integer(behavior.commandPaletteTopPadding))",
        "results=\(integer(behavior.commandPaletteResultsMaximumHeight))",
        "placeholder=\"\(configuration.searchPlaceholder)\"",
      ]
      .joined(separator: " ")
    }

    private var resolvedStyle: MacWorkspaceShellStyle {
      switch configuration.style {
      case .automatic:
        .custom
      case .custom, .nativeSplitView:
        configuration.style
      }
    }

    private var widthsLine: String {
      let layout = configuration.layout
      return [
        "widths:",
        "sidebar=\(integer(layout.resolvedWidth(for: .sidebar, columnWidths: restoration.columnWidths)))",
        "list=\(integer(layout.resolvedWidth(for: .list, columnWidths: restoration.columnWidths)))",
        "detail=\(integer(layout.resolvedWidth(for: .detail, columnWidths: restoration.columnWidths)))",
        "inspector=\(integer(layout.resolvedWidth(for: .inspector, columnWidths: restoration.columnWidths)))",
      ]
      .joined(separator: " ")
    }

    private func accessibilityAnchors(
      selectedRoute: WorkspaceRouteDescriptor<RouteID>?
    ) -> [String] {
      var anchors = [
        "mac-workspace-shell",
        "mac-workspace-shell-\(resolvedStyle == .custom ? "custom" : "native")",
        "mac-workspace-sidebar",
        "mac-workspace-sidebar-routes",
        "mac-workspace-command-search-button",
        "mac-workspace-content-header",
        "mac-workspace-content-title",
        "mac-workspace-sidebar-toggle-button",
      ]

      if let selectedRoute {
        anchors.append("mac-workspace-route-\(identifierComponent(routeName(selectedRoute.id)))")
      }

      if restoration.isInspectorPresented {
        anchors.append("mac-workspace-inspector-pane")
        anchors.append("mac-workspace-inspector-toggle-button")
      }

      anchors.append("mac-workspace-command-palette")
      anchors.append("mac-workspace-command-palette-search-field")
      anchors.append("mac-workspace-command-palette-results")
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

    private func panes(
      for route: WorkspaceRouteDescriptor<RouteID>?
    ) -> [String] {
      var panes: [String] = []
      if restoration.isSidebarVisible {
        panes.append("sidebar")
      }
      panes.append("header")

      switch route?.presentation {
      case .listDetail:
        panes.append("list")
        panes.append("detail")
      case .fullWidth:
        panes.append("full-width")
      case nil:
        panes.append("empty")
      }

      if restoration.isInspectorPresented {
        panes.append("inspector")
      }

      return panes
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

    private func route(for id: RouteID) -> WorkspaceRouteDescriptor<RouteID>? {
      registry.sections
        .lazy
        .flatMap(\.routes)
        .first { $0.id == id }
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

    private func integer(_ value: CGFloat) -> Int {
      Int(value.rounded())
    }

    private func routeName(_ routeID: RouteID) -> String {
      String(describing: routeID)
    }
  }

  private extension MacWorkspaceShellConfiguration {
    static func visualState(style: MacWorkspaceShellStyle) -> Self {
      Self(
        title: "Workspace Demo",
        style: style,
        searchPlaceholder: "Search demo commands",
        brandSystemImage: "square.grid.2x2",
        brandTint: .indigo
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
#endif
