import Foundation
import IOSWorkspaceShell
import Testing
import WorkspaceCore

private enum TestRoute: String, Codable, Hashable, Sendable {
  case inbox
  case settings
}

@Test
func iosRestorationComposesSharedWorkspaceState() throws {
  let restoration = IOSWorkspaceRestoration(
    workspace: WorkspaceRestoration(
      selectedRouteID: TestRoute.settings,
      collapsedSectionIDs: ["main"],
      recentCommandIDs: [.route(.settings)]
    ),
    columnPreference: .content,
    compactNavigationPath: [.inbox, .settings]
  )

  let data = try JSONEncoder().encode(restoration)
  let decoded = try JSONDecoder().decode(
    IOSWorkspaceRestoration<TestRoute>.self,
    from: data
  )

  #expect(decoded == restoration)
  #expect(decoded.workspace.selectedRouteID == .settings)
  #expect(decoded.columnPreference == .content)
  #expect(decoded.compactNavigationPath == [.inbox, .settings])
}

@Test
func iosShellConfigurationHasNativeDefaults() {
  let configuration = IOSWorkspaceShellConfiguration.default

  #expect(configuration.title == "Workspace")
  #expect(configuration.navigationStyle == .automatic)
  #expect(configuration.commandSearchPlaceholder == "Search commands and routes")
  #expect(configuration.prefersBadges)
}
