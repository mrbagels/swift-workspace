import CustomRendererClient
import Foundation
import Testing
import WorkspaceCore

@Test
func customRendererBuildsRouteAndCommandSnapshots() {
  let state = CustomRendererClient.initialState()
  let snapshot = CustomRendererClient.snapshot(from: state)

  #expect(snapshot.selectedRouteID == .dashboard)
  #expect(snapshot.selectedRouteTitle == "Dashboard")
  #expect(snapshot.sections.map(\.title) == ["Main", "System"])
  #expect(snapshot.sections.flatMap(\.routes).map(\.routeID) == [
    .dashboard,
    .reports,
    .settings,
  ])
  #expect(snapshot.commandSections.map(\.title) == ["Main", "System", "App"])
}

@Test
func customRendererCanUseSharedFilePersistence() throws {
  let rootURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("CustomRendererClientTests-\(UUID().uuidString)")
  let fileURL = rootURL.appendingPathComponent("restoration.json")
  defer { try? FileManager.default.removeItem(at: rootURL) }

  let persistence = CustomRendererClient.persistence(fileURL: fileURL)
  let state = CustomRendererClient.initialState(selectedRouteID: .settings)

  try persistence.save(state.restorationState)

  #expect(try persistence.load()?.selectedRouteID == .settings)
}

@Test
func customRendererCanApplyRouteMetadataWithoutAShell() {
  var state = CustomRendererClient.initialState()
  let changed = state.navigation.apply([
    WorkspaceRouteMetadataPatch(
      routeID: CustomRendererRoute.dashboard,
      badge: .set(9)
    ),
    WorkspaceRouteMetadataPatch(
      routeID: CustomRendererRoute.reports,
      availability: .set(.disabled(reason: "No report access"))
    ),
  ])

  let snapshot = CustomRendererClient.snapshot(from: state)

  #expect(changed)
  #expect(snapshot.sections[0].routes[0].badge == 9)
  #expect(snapshot.sections[0].routes[1].isEnabled == false)
}
