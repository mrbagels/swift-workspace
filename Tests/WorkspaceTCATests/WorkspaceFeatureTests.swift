import ComposableArchitecture
import Testing
import WorkspaceCore
@testable import WorkspaceTCA

private enum TestRoute: String, Codable, Hashable, Sendable {
  case archive
  case inbox
  case review
  case settings
}

@MainActor
@Test
func routeSelectionUpdatesSelectedRouteAndEmitsDelegates() async {
  let store = TestStore(initialState: WorkspaceFeature<TestRoute>.State.testValue) {
    WorkspaceFeature<TestRoute>()
  }
  store.exhaustivity = .off

  await store.send(.routeSelected(.review)) {
    $0.selectedRouteID = .review
  }
}

@MainActor
@Test
func commandPaletteReturnExecutesAppCommand() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.commandPaletteQuery = "sync"

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }
  store.exhaustivity = .off

  await store.send(.commandPaletteReturnKeyPressed) {
    $0.commandPaletteQuery = ""
    $0.recentCommandIDs = [.appAction("refresh")]
  }
}

@MainActor
@Test
func commandPaletteDismissalClearsQueryAndSelection() async {
  let store = TestStore(initialState: WorkspaceFeature<TestRoute>.State.testValue) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(.commandPaletteRequested) {
    $0.isCommandPalettePresented = true
    $0.selectedCommandID = .route(.inbox)
  }
  await store.send(.commandPaletteQueryChanged("settings")) {
    $0.commandPaletteQuery = "settings"
    $0.selectedCommandID = .route(.settings)
  }
  await store.send(.commandPaletteDismissed) {
    $0.commandPaletteQuery = ""
    $0.isCommandPalettePresented = false
    $0.selectedCommandID = nil
  }
}

@MainActor
@Test
func commandPaletteMoveSelectionWrapsThroughFilteredCommands() async {
  let store = TestStore(initialState: WorkspaceFeature<TestRoute>.State.testValue) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(.commandPaletteRequested) {
    $0.isCommandPalettePresented = true
    $0.selectedCommandID = .route(.inbox)
  }
  await store.send(.commandPaletteMoveSelection(.down)) {
    $0.selectedCommandID = .route(.review)
  }
  await store.send(.commandPaletteMoveSelection(.up)) {
    $0.selectedCommandID = .route(.inbox)
  }
  await store.send(.commandPaletteMoveSelection(.up)) {
    $0.selectedCommandID = .system("toggle-sidebar")
  }
}

@MainActor
@Test
func commandExecutionRecordsRecentCommandsAndEmitsRestorationDelegate() async {
  let store = TestStore(initialState: WorkspaceFeature<TestRoute>.State.testValue) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(.commandMenuCommandSelected(.appAction("refresh"))) {
    $0.recentCommandIDs = [.appAction("refresh")]
  }
  await store.receive(\.delegate)
  await store.receive(\.delegate)

  await store.send(.commandMenuCommandSelected(.toolbarAction("export"))) {
    $0.recentCommandIDs = [.toolbarAction("export"), .appAction("refresh")]
  }
  await store.receive(\.delegate)
  await store.receive(\.delegate)
}

@MainActor
@Test
func commandPolicyDeniesPaletteCommandAndEmitsDelegate() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.commandPolicy = WorkspaceCommandExecutionPolicy(
    deniedCommandIDs: [.appAction("refresh")]
  )
  state.commandPaletteQuery = "sync"
  state.isCommandPalettePresented = true
  state.selectedCommandID = .appAction("refresh")

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(.commandPaletteReturnKeyPressed) {
    $0.commandPaletteQuery = ""
    $0.isCommandPalettePresented = false
    $0.selectedCommandID = nil
  }
  await store.receive(\.delegate)
}

@MainActor
@Test
func commandPolicyAllowListsAutomationCommands() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.commandPolicy = WorkspaceCommandExecutionPolicy(
    automationAllowedCommandIDs: [.toolbarAction("export")]
  )

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(.commandAutomationRequested(.appAction("refresh")))
  await store.receive(\.delegate)

  await store.send(.commandAutomationRequested(.toolbarAction("export"))) {
    $0.recentCommandIDs = [.toolbarAction("export")]
  }
  await store.receive(\.delegate)
  await store.receive(\.delegate)
}

@Test
func commandPolicyCanDenyCommandSources() {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.commandPolicy = WorkspaceCommandExecutionPolicy(
    deniedSources: [.toolbar]
  )

  let command = state.availableCommands.first { $0.id == .toolbarAction("export") }

  #expect(
    command.flatMap {
      state.commandPolicy.denial(for: $0, invocation: .commandMenu)
    }
    == WorkspaceCommandExecutionDenial(
      commandID: .toolbarAction("export"),
      invocation: .commandMenu,
      reason: .sourceDenied,
      source: .toolbar
    )
  )
}

@MainActor
@Test
func routeOpenRequestSelectsRouteAndSavesState() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.collapsedSectionIDs = ["main"]
  state.commandPaletteQuery = "review"
  state.isCommandPalettePresented = true

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(
    .routeOpenRequested(
      .deepLink(.review, url: "swift-workspace://review")
    )
  ) {
    $0.collapsedSectionIDs = []
    $0.commandPaletteQuery = ""
    $0.isCommandPalettePresented = false
    $0.selectedRouteID = .review
  }
  await store.receive(\.delegate)
  await store.receive(\.delegate)
}

@MainActor
@Test
func routeOpenRequestPreferredSceneEmitsSceneDelegateWhenAvailable() async {
  let store = TestStore(initialState: WorkspaceFeature<TestRoute>.State.testValue) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(
    .routeOpenRequested(
      WorkspaceRouteOpenRequest(
        routeID: .settings,
        mode: .preferredScene,
        source: .programmatic
      )
    )
  )
  await store.receive(\.delegate)
}

@MainActor
@Test
func routeOpenRequestRejectsUnknownRoutes() async {
  let store = TestStore(initialState: WorkspaceFeature<TestRoute>.State.testValue) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(
    .routeOpenRequested(
      WorkspaceRouteOpenRequest(
        routeID: .archive,
        source: .externalEvent("NSUserActivity")
      )
    )
  )
  await store.receive(\.delegate)
}

@MainActor
@Test
func disabledRouteRemainsVisibleButCannotBeSelected() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.sections[0].routes[1].availability = .disabled(reason: "Requires admin access")

  #expect(state.visibleSections[0].routes.map(\.id) == [.inbox, .review, .settings])
  #expect(state.availableCommands.first { $0.id == .route(.review) }?.isEnabled == false)
  #expect(state.filteredCommands.contains { $0.id == .route(.review) } == false)
  #expect(state.routeOpenRejectionReason(for: .review) == .routeDisabled)

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(.routeSelected(.review))
}

@MainActor
@Test
func hiddenRouteIsRemovedFromNavigationAndRejectedByOpenRequests() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.sections[0].routes[1].availability = .hidden

  #expect(state.visibleSections[0].routes.map(\.id) == [.inbox, .settings])
  #expect(!state.availableCommands.map(\.id).contains(.route(.review)))
  #expect(state.routeOpenRejectionReason(for: .review) == .routeHidden)

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(
    .routeOpenRequested(
      WorkspaceRouteOpenRequest(routeID: .review)
    )
  )
  await store.receive(\.delegate)
}

@MainActor
@Test
func sceneCommandEmitsSceneDelegateAndRecordsRecentCommand() async {
  let store = TestStore(initialState: WorkspaceFeature<TestRoute>.State.testValue) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(.commandMenuCommandSelected(.scene(.settings))) {
    $0.recentCommandIDs = [.scene(.settings)]
  }
  await store.receive(\.delegate)
  await store.receive(\.delegate)
}

@MainActor
@Test
func recentCommandsClearedRemovesHistoryAndEmitsRestorationDelegate() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.recentCommandIDs = [.appAction("refresh")]

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(.recentCommandsCleared) {
    $0.recentCommandIDs = []
  }
  await store.receive(\.delegate)
}

@MainActor
@Test
func restorationStateLoadedRestoresSharedStateAndClearsTransientPaletteState() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.commandPaletteQuery = "review"
  state.isCommandPalettePresented = true
  state.selectedCommandID = .route(.review)

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }

  await store.send(
    .restorationStateLoaded(
      WorkspaceRestoration(
        selectedRouteID: .settings,
        collapsedSectionIDs: ["main", "unknown"],
        recentCommandIDs: [
          .toolbarAction("export"),
          .appAction("missing"),
          .toolbarAction("export"),
          .route(.inbox),
        ]
      )
    )
  ) {
    $0.collapsedSectionIDs = []
    $0.commandPaletteQuery = ""
    $0.isCommandPalettePresented = false
    $0.recentCommandIDs = [.toolbarAction("export"), .route(.inbox)]
    $0.selectedCommandID = nil
    $0.selectedRouteID = .settings
  }
}

@MainActor
@Test
func routeMetadataPatchHidingSelectedRouteFallsBackToFirstSelectableRoute() async {
  var state = WorkspaceFeature<TestRoute>.State.testValue
  state.selectedRouteID = .settings

  let store = TestStore(initialState: state) {
    WorkspaceFeature<TestRoute>()
  }
  store.exhaustivity = .off

  await store.send(
    .routeMetadataPatchesApplied([
      WorkspaceRouteMetadataPatch(
        routeID: .settings,
        availability: .set(.hidden)
      ),
    ])
  ) {
    $0.navigation.sections[0].routes[2].availability = .hidden
    $0.selectedRouteID = .inbox
  }
}

private extension WorkspaceFeature<TestRoute>.State {
  static let testValue = Self(
    navigation: WorkspaceNavigationRegistry(
      sections: [
        WorkspaceRouteSection(
          id: "main",
          title: "Main",
          isCollapsible: true,
          routes: [
            WorkspaceRouteDescriptor(
              id: TestRoute.inbox,
              title: "Inbox",
              systemImage: "tray.full"
            ),
            WorkspaceRouteDescriptor(
              id: TestRoute.review,
              title: "Review",
              systemImage: "checklist"
            ),
            WorkspaceRouteDescriptor(
              id: TestRoute.settings,
              title: "Settings",
              systemImage: "gearshape",
              scenePresentation: .singleton(id: "settings-window")
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
        .toolbarAction(
          id: "export",
          title: "Export",
          systemImage: "square.and.arrow.up",
          keywords: ["share"],
          shortcut: .command("e")
        ),
        .primaryAction(
          id: "new",
          title: "New",
          systemImage: "plus",
          keywords: ["create"]
        ),
        .system(
          id: "toggle-sidebar",
          title: "Toggle Sidebar",
          systemImage: "sidebar.left",
          keywords: ["sidebar"]
        ),
      ]
    ),
    selectedRouteID: .inbox
  )
}
