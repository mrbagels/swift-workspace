#if os(macOS)
  import Foundation
  import MacWorkspaceShell
  import Testing
  import WorkspaceCore

  private enum TestRoute: String, Codable, Hashable, Sendable {
    case inbox
    case settings
  }

  @Test
  func macRestorationComposesSharedWorkspaceStateAndSanitizesWidths() throws {
    let restoration = MacWorkspaceRestoration(
      workspace: WorkspaceRestoration(
        selectedRouteID: TestRoute.settings,
        collapsedSectionIDs: ["main"],
        recentCommandIDs: [.route(.settings)]
      ),
      isSidebarVisible: false,
      isInspectorPresented: true,
      columnWidths: MacWorkspaceColumnWidths(
        sidebar: 280,
        detail: -1,
        inspector: .infinity
      ),
      style: .nativeSplitView
    )

    #expect(restoration.columnWidths.sidebar == 280)
    #expect(restoration.columnWidths.detail == nil)
    #expect(restoration.columnWidths.inspector == nil)
    #expect(restoration.workspace.selectedRouteID == .settings)

    let data = try JSONEncoder().encode(restoration)
    let decoded = try JSONDecoder().decode(
      MacWorkspaceRestoration<TestRoute>.self,
      from: data
    )

    #expect(decoded == restoration)
  }

  @Test
  func macCommandReferenceUsesSharedCommandSections() {
    let commands: [WorkspaceCommand<TestRoute>] = [
      WorkspaceCommand(
        id: .route(.inbox),
        title: "Inbox",
        systemImage: "tray.full",
        sectionTitle: "Main",
        source: .navigation,
        target: .route(.inbox)
      ),
      .system(
        id: "toggle-sidebar",
        title: "Toggle Sidebar",
        systemImage: "sidebar.left"
      ),
    ]

    let sections = WorkspaceCommandSections.make(
      for: commands,
      grouping: .source
    )

    #expect(sections.map(\.title) == ["Navigation", "Workspace"])
  }

  @Test
  func macShellConfigurationHasNativeSplitViewDefaults() {
    let configuration = MacWorkspaceShellConfiguration.default

    #expect(configuration.style == .nativeSplitView)
    #expect(configuration.sidebarMinimumWidth < configuration.sidebarIdealWidth)
    #expect(configuration.sidebarIdealWidth < configuration.sidebarMaximumWidth)
    #expect(configuration.commandPaletteWidth >= 520)
  }
#endif
