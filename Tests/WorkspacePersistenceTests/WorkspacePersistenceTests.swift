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

@Test
func filePersistenceRoundTripsRestorationAndCreatesParentDirectory() throws {
  let rootURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("WorkspacePersistenceTests-\(UUID().uuidString)")
  let fileURL = rootURL
    .appendingPathComponent("nested")
    .appendingPathComponent("restoration.json")
  defer { try? FileManager.default.removeItem(at: rootURL) }

  let persistence = WorkspaceFilePersistence<TestRoute>(fileURL: fileURL)
  let restoration = WorkspaceRestoration(
    selectedRouteID: TestRoute.inbox,
    collapsedSectionIDs: ["main"],
    recentCommandIDs: [.route(.inbox), .route(.settings)]
  )

  #expect(try persistence.load() == nil)

  try persistence.save(restoration)

  #expect(FileManager.default.fileExists(atPath: fileURL.path))
  #expect(try persistence.load() == restoration)
}

@Test
func filePersistenceRemoveIgnoresMissingFiles() throws {
  let rootURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("WorkspacePersistenceTests-\(UUID().uuidString)")
  let fileURL = rootURL.appendingPathComponent("restoration.json")
  defer { try? FileManager.default.removeItem(at: rootURL) }

  let persistence = WorkspaceFilePersistence<TestRoute>(fileURL: fileURL)

  try persistence.remove()
  #expect(try persistence.load() == nil)
}
