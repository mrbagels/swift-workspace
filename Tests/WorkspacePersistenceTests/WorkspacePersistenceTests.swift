import Foundation
import Testing
import WorkspaceCore
@testable import WorkspacePersistence

private enum TestRoute: String, Codable, Hashable, Sendable {
  case inbox
  case settings
}

@Test
func userDefaultsPersistenceRoundTripsRestoration() throws {
  let defaults = try #require(UserDefaults(suiteName: "WorkspacePersistenceTests"))
  defaults.removePersistentDomain(forName: "WorkspacePersistenceTests")

  let persistence = WorkspaceUserDefaultsPersistence<TestRoute>(
    key: "main",
    defaults: defaults
  )
  let restoration = WorkspaceRestoration(
    selectedRouteID: TestRoute.settings,
    collapsedSectionIDs: ["admin"],
    recentCommandIDs: [.route(.settings)]
  )

  try persistence.save(restoration)

  #expect(try persistence.load() == restoration)
}
