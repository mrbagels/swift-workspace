import Testing
import WorkspaceAutomationBridge
import WorkspaceCore

private enum AutomationRoute: String, Codable, Hashable, Sendable {
  case inbox
  case settings
}

@Test
func automationCatalogBuildsRouteSceneAndActionDescriptors() {
  let catalog = WorkspaceAutomationCatalog.make(
    from: registry,
    routeIdentifier: \.rawValue,
    appNamePlaceholder: "Workspace Demo"
  )

  #expect(catalog.commands.map(\.id) == [
    "route.inbox",
    "route.settings",
    "scene.settings",
    "app.refresh",
    "toolbar.export",
  ])

  let route = catalog.command(id: "route.inbox")
  #expect(route?.kind == .openRoute)
  #expect(route?.launchPolicy == .openApp)
  #expect(route?.routeID == "inbox")
  #expect(route?.phraseTemplates.first == "Open Inbox in Workspace Demo")

  let toolbar = catalog.command(id: "toolbar.export")
  #expect(toolbar?.kind == .toolbarAction)
  #expect(toolbar?.launchPolicy == .inline)

  #expect(catalog.shortcuts.map(\.commandID).contains("route.inbox"))
}

@Test
func automationCatalogBuildsStableHandoffPayloads() throws {
  let catalog = WorkspaceAutomationCatalog.make(
    from: registry,
    routeIdentifier: \.rawValue
  )

  let handoff = try #require(catalog.handoff(for: "scene.settings", source: "shortcut"))
  #expect(handoff.commandID == "scene.settings")
  #expect(handoff.kind == .openScene)
  #expect(handoff.routeID == "settings")
  #expect(handoff.source == "shortcut")
}

private let registry = WorkspaceNavigationRegistry(
  sections: [
    WorkspaceRouteSection(
      id: "workspace",
      title: "Workspace",
      routes: [
        WorkspaceRouteDescriptor(
          id: AutomationRoute.inbox,
          title: "Inbox",
          systemImage: "tray.full",
          shortcut: .command("1")
        ),
        WorkspaceRouteDescriptor(
          id: AutomationRoute.settings,
          title: "Settings",
          systemImage: "gearshape",
          scenePresentation: .singleton(id: "settings")
        ),
      ]
    ),
  ],
  commands: [
    .appAction(
      id: "refresh",
      title: "Refresh",
      systemImage: "arrow.clockwise"
    ),
    .toolbarAction(
      id: "export",
      title: "Export",
      systemImage: "square.and.arrow.up"
    ),
  ]
)
