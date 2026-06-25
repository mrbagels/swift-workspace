import Foundation
import Testing
@testable import WorkspaceCore

private struct LargeRouteID: Codable, Hashable, Sendable {
  var section: Int
  var route: Int
}

@Test
func largeRegistrySearchGroupingAndMetadataPatchesRemainResponsive() {
  let sectionCount = 40
  let routeCount = 60
  let target = LargeRouteID(section: 37, route: 48)
  var registry = makeLargeRegistry(
    sectionCount: sectionCount,
    routeCount: routeCount,
    target: target
  )

  let commands: [WorkspaceCommand<LargeRouteID>] =
    registry.routeCommands + registry.sceneCommands + registry.commands

  let clock = ContinuousClock()
  let start = clock.now
  let searchResults = WorkspaceCommandSearch.filteredCommands(
    commands,
    query: "needle critical",
    recentCommandIDs: [.route(target)]
  )
  let sections: [WorkspaceCommandSection<LargeRouteID>] = WorkspaceCommandSections.make(
    for: commands,
    grouping: .role
  )
  let didChange = registry.apply([
    WorkspaceRouteMetadataPatch(
      routeID: target,
      badge: .set(99),
      subtitle: .set("Escalated")
    ),
    WorkspaceRouteMetadataPatch(
      routeID: target,
      title: .set("Critical Review Queue Updated")
    ),
    WorkspaceRouteMetadataPatch(
      routeID: LargeRouteID(section: 2, route: 3),
      availability: .set(.hidden)
    ),
  ])
  let elapsed = start.duration(to: clock.now)

  #expect(searchResults.first?.id == .route(target))
  #expect(sections.map { $0.title } == ["Navigation", "Scene", "App Action"])
  #expect(didChange)
  #expect(
    registry.sections[37].routes[48].title
    == "Critical Review Queue Updated"
  )
  #expect(registry.sections[37].routes[48].badge == 99)
  #expect(registry.sections[37].routes[48].subtitle == "Escalated")
  #expect(registry.sections[2].routes[3].availability == WorkspaceAvailability.hidden)
  #expect(elapsed < .seconds(5))
}

@Test
func metadataPatchIndexingPreservesPerRoutePatchOrder() {
  var registry = WorkspaceNavigationRegistry(
    sections: [
      WorkspaceRouteSection(
        id: "main",
        title: "Main",
        routes: [
          WorkspaceRouteDescriptor(
            id: LargeRouteID(section: 0, route: 0),
            title: "Original",
            systemImage: "tray"
          ),
        ]
      ),
    ]
  )

  registry.apply([
    WorkspaceRouteMetadataPatch(
      routeID: LargeRouteID(section: 0, route: 0),
      title: .set("First")
    ),
    WorkspaceRouteMetadataPatch(
      routeID: LargeRouteID(section: 0, route: 0),
      subtitle: .set("Preserved"),
      title: .set("Second")
    ),
  ])

  #expect(registry.sections[0].routes[0].title == "Second")
  #expect(registry.sections[0].routes[0].subtitle == "Preserved")
}

private func makeLargeRegistry(
  sectionCount: Int,
  routeCount: Int,
  target: LargeRouteID
) -> WorkspaceNavigationRegistry<LargeRouteID> {
  WorkspaceNavigationRegistry(
    sections: (0..<sectionCount).map { section in
      makeLargeSection(section, routeCount: routeCount, target: target)
    },
    commands: makeLargeCommands(count: 200)
  )
}

private func makeLargeSection(
  _ section: Int,
  routeCount: Int,
  target: LargeRouteID
) -> WorkspaceRouteSection<LargeRouteID> {
  WorkspaceRouteSection(
    id: "section-\(section)",
    title: "Section \(section)",
    routes: (0..<routeCount).map { route in
      makeLargeRoute(section: section, route: route, target: target)
    }
  )
}

private func makeLargeRoute(
  section: Int,
  route: Int,
  target: LargeRouteID
) -> WorkspaceRouteDescriptor<LargeRouteID> {
  let routeID = LargeRouteID(section: section, route: route)
  return WorkspaceRouteDescriptor(
    id: routeID,
    title: routeID == target ? "Critical Review Queue" : "Route \(section)-\(route)",
    systemImage: "square.grid.2x2",
    badge: route,
    keywords: [
      "section-\(section)",
      "route-\(route)",
      routeID == target ? "needle" : "standard",
    ],
    shortcut: route < 9 ? .command("\(route + 1)") : nil,
    scenePresentation: route == 0
      ? .singleton(id: WorkspaceSceneID("section-\(section)"))
      : .primary
  )
}

private func makeLargeCommands(
  count: Int
) -> [WorkspaceCommand<LargeRouteID>] {
  (0..<count).map { index in
    .appAction(
      id: WorkspaceCommandID("app-command-\(index)"),
      title: "App Command \(index)",
      systemImage: "bolt",
      keywords: ["automation", "command-\(index)"]
    )
  }
}
