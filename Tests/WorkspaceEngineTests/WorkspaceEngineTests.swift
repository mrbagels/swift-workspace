import Foundation
import Testing
import WorkspaceEngine

private enum EngineRoute: String, Codable, Hashable, Sendable {
  case home
}

@MainActor
@Test
func workspaceEngineReexportsCoreTCAPersistenceAndComposableArchitecture() async throws {
  let registry = WorkspaceNavigationRegistry(
    sections: [
      WorkspaceRouteSection(
        id: "main",
        title: "Main",
        routes: [
          WorkspaceRouteDescriptor(
            id: EngineRoute.home,
            title: "Home",
            systemImage: "house"
          ),
        ]
      ),
    ]
  )
  let store = Store(
    initialState: WorkspaceFeature<EngineRoute>.State(
      navigation: registry,
      selectedRouteID: .home
    )
  ) {
    WorkspaceFeature<EngineRoute>()
  }
  let codec = WorkspaceJSONCodec<EngineRoute>()
  let restoration = WorkspaceRestoration<EngineRoute>(selectedRouteID: .home)
  let data = try codec.encode(restoration)
  let decoded = try codec.decode(data)

  store.send(.routeSelected(.home))
  #expect(decoded == restoration)
}
