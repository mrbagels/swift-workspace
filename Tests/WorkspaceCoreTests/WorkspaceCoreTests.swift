import Foundation
import Testing
@testable import WorkspaceCore

private enum TestRoute: String, Codable, Hashable, Sendable {
  case archive
  case inbox
  case review
  case settings
}

@Test
func commandSearchFindsRoutesAndAppCommands() {
  let registry = WorkspaceNavigationRegistry(
    sections: [
      WorkspaceRouteSection(
        id: "main",
        title: "Main",
        routes: [
          WorkspaceRouteDescriptor(
            id: TestRoute.inbox,
            title: "Inbox",
            systemImage: "tray.full",
            keywords: ["queue"]
          ),
          WorkspaceRouteDescriptor(
            id: TestRoute.settings,
            title: "Settings",
            systemImage: "gearshape",
            keywords: ["preferences"]
          ),
        ]
      ),
    ],
    commands: [
      .appAction(
        id: "refresh",
        title: "Refresh Workspace",
        systemImage: "arrow.clockwise",
        keywords: ["sync"]
      ),
    ]
  )

  #expect(
    WorkspaceCommandSearch
      .filteredCommands(registry.routeCommands + registry.commands, query: "preferences")
      .map(\.id)
    == [.route(.settings)]
  )

  #expect(
    WorkspaceCommandSearch
      .filteredCommands(registry.routeCommands + registry.commands, query: "sync")
      .map(\.id)
    == [.appAction("refresh")]
  )
}

@Test
func commandSearchFiltersUnavailableCommandsAndBoostsRecentMatches() {
  let commands: [WorkspaceCommand<TestRoute>] = [
    .appAction(
      id: "open",
      title: "Open",
      systemImage: "folder"
    ),
    .appAction(
      id: "organize",
      title: "Organize",
      systemImage: "tray.full"
    ),
    .appAction(
      id: "disabled",
      title: "Disabled",
      systemImage: "lock",
      isEnabled: false
    ),
    .appAction(
      id: "hidden",
      title: "Hidden",
      systemImage: "eye.slash",
      isHidden: true
    ),
  ]

  let filteredCommands = WorkspaceCommandSearch.filteredCommands(
    commands,
    query: "o",
    recentCommandIDs: [.appAction("organize")]
  )

  #expect(filteredCommands.map(\.id) == [.appAction("organize"), .appAction("open")])
}

@Test
func commandSectionsGroupCommandsAndFilterDisabledCommands() {
  let commands: [WorkspaceCommand<TestRoute>] = [
    WorkspaceCommand(
      id: .route(.inbox),
      title: "Inbox",
      systemImage: "tray.full",
      sectionTitle: "Main",
      source: .navigation,
      target: .route(.inbox)
    ),
    WorkspaceCommand(
      id: .route(.settings),
      title: "Settings",
      systemImage: "gearshape",
      sectionTitle: "Main",
      source: .navigation,
      target: .route(.settings),
      isEnabled: false,
      disabledReason: "Requires admin"
    ),
    .toolbarAction(
      id: "export",
      title: "Export",
      systemImage: "square.and.arrow.up"
    ),
    .primaryAction(
      id: "new",
      title: "New",
      systemImage: "plus"
    ),
  ]

  let categorySections = WorkspaceCommandSections.make(
    for: commands,
    grouping: .category,
    includesDisabledCommands: false
  )

  #expect(categorySections.map(\.title) == ["Main", "Toolbar", "Primary"])
  #expect(categorySections.flatMap(\.commands).map(\.id) == [
    .route(.inbox),
    .toolbarAction("export"),
    .primaryAction("new"),
  ])

  let roleSections = WorkspaceCommandSections.make(
    for: commands,
    grouping: .role
  )

  #expect(roleSections.map(\.title) == [
    "Navigation",
    "Toolbar Action",
    "Primary Action",
  ])
}

@Test
func routeMetadataPatchesApplyAcrossNavigationRegistry() {
  var registry = WorkspaceNavigationRegistry(
    sections: [
      WorkspaceRouteSection(
        id: "main",
        title: "Main",
        routes: [
          WorkspaceRouteDescriptor(
            id: TestRoute.inbox,
            title: "Inbox",
            systemImage: "tray.full"
          ),
          WorkspaceRouteDescriptor(
            id: TestRoute.settings,
            title: "Settings",
            systemImage: "gearshape"
          ),
        ]
      ),
    ]
  )

  let changed = registry.apply([
    WorkspaceRouteMetadataPatch(
      routeID: .inbox,
      badge: .set(12),
      subtitle: .set("Needs review")
    ),
    WorkspaceRouteMetadataPatch(
      routeID: .settings,
      availability: .set(.disabled(reason: "Requires admin")),
      keywords: .set(["preferences", "account"])
    ),
  ])

  #expect(changed)
  #expect(registry.sections[0].routes[0].badge == 12)
  #expect(registry.sections[0].routes[0].subtitle == "Needs review")
  #expect(registry.sections[0].routes[1].availability == .disabled(reason: "Requires admin"))
  #expect(registry.routeCommands.first { $0.id == .route(.settings) }?.isEnabled == false)
}

@Test
func routeOpenURLParserBuildsTypedRequestsFromHostAndPathCandidates() throws {
  let parser = WorkspaceRouteOpenURLParser(
    routesByPath: [
      "settings": TestRoute.settings,
      "workspace/review": TestRoute.review,
    ],
    defaultMode: .preferredScene
  )

  let customSchemeURL = try #require(URL(string: "swift-workspace://settings"))
  let universalLinkURL = try #require(URL(string: "https://example.com/workspace/review"))

  #expect(
    parser.request(for: customSchemeURL)
    == WorkspaceRouteOpenRequest.deepLink(
      .settings,
      url: "swift-workspace://settings",
      mode: .preferredScene
    )
  )
  #expect(
    parser.request(for: universalLinkURL, mode: .currentScene)
    == WorkspaceRouteOpenRequest.deepLink(
      .review,
      url: "https://example.com/workspace/review",
      mode: .currentScene
    )
  )
}

@Test
func sceneCollectionKeepsSingletonStableAndDocumentsSequenced() {
  let settings = WorkspaceSceneRequest(
    routeID: TestRoute.settings,
    presentation: .singleton(id: "settings-window", title: "Settings"),
    source: .routeAction
  )
  let reviewDocument = WorkspaceSceneRequest(
    routeID: TestRoute.review,
    presentation: .document(title: "Review"),
    source: .command
  )

  var collection = WorkspaceSceneCollection<TestRoute>()
  let firstSettings = collection.open(settings, encodeRouteID: \.rawValue)
  let secondSettings = collection.open(settings, encodeRouteID: \.rawValue)
  let firstReview = collection.open(reviewDocument, encodeRouteID: \.rawValue)
  let secondReview = collection.open(reviewDocument, encodeRouteID: \.rawValue)

  #expect(firstSettings.id == "settings-window")
  #expect(secondSettings.id == "settings-window")
  #expect(firstReview.id == "review-document-1")
  #expect(secondReview.id == "review-document-2")
  #expect(collection.values.count == 3)
}
