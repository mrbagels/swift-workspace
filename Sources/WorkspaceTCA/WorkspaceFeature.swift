import ComposableArchitecture
import WorkspaceCore

/// TCA reducer that owns platform-neutral workspace routing and commands.
@Reducer
public struct WorkspaceFeature<RouteID: Hashable & Sendable> {
  public init() {}

  @ObservableState
  public struct State: Equatable, Sendable {
    public var collapsedSectionIDs: Set<WorkspaceRouteSectionID>
    public var commandPaletteQuery: String
    public var commandPolicy: WorkspaceCommandExecutionPolicy<RouteID>
    public var isCommandPalettePresented: Bool
    public var navigation: WorkspaceNavigationRegistry<RouteID>
    public var pinnedRouteIDs: [RouteID]
    public var recentCommandIDs: [WorkspaceCommandIdentifier<RouteID>]
    public var recentCommandLimit: Int
    public var recentRouteIDs: [RouteID]
    public var recentRouteLimit: Int
    public var selectedCommandID: WorkspaceCommandIdentifier<RouteID>?
    public var selectedRouteID: RouteID

    public init(
      collapsedSectionIDs: Set<WorkspaceRouteSectionID> = [],
      commandPaletteQuery: String = "",
      commandPolicy: WorkspaceCommandExecutionPolicy<RouteID> = .allowAll,
      isCommandPalettePresented: Bool = false,
      navigation: WorkspaceNavigationRegistry<RouteID>,
      pinnedRouteIDs: [RouteID] = [],
      recentCommandIDs: [WorkspaceCommandIdentifier<RouteID>] = [],
      recentCommandLimit: Int = 8,
      recentRouteIDs: [RouteID] = [],
      recentRouteLimit: Int = 8,
      selectedCommandID: WorkspaceCommandIdentifier<RouteID>? = nil,
      selectedRouteID: RouteID
    ) {
      self.collapsedSectionIDs = collapsedSectionIDs
      self.commandPaletteQuery = commandPaletteQuery
      self.commandPolicy = commandPolicy
      self.isCommandPalettePresented = isCommandPalettePresented
      self.navigation = navigation
      self.pinnedRouteIDs = []
      self.recentCommandIDs = Array(recentCommandIDs.prefix(max(0, recentCommandLimit)))
      self.recentCommandLimit = max(0, recentCommandLimit)
      self.recentRouteIDs = []
      self.recentRouteLimit = max(0, recentRouteLimit)
      self.selectedCommandID = selectedCommandID
      self.selectedRouteID = selectedRouteID
      restorePinnedRoutes(pinnedRouteIDs)
      restoreRecentRoutes(recentRouteIDs)
    }

    public init(
      collapsedSectionIDs: Set<WorkspaceRouteSectionID> = [],
      commandPaletteQuery: String = "",
      commandPolicy: WorkspaceCommandExecutionPolicy<RouteID> = .allowAll,
      isCommandPalettePresented: Bool = false,
      navigation: WorkspaceNavigationRegistry<RouteID>,
      recentCommandIDs: [WorkspaceCommandIdentifier<RouteID>] = [],
      recentCommandLimit: Int = 8,
      selectedCommandID: WorkspaceCommandIdentifier<RouteID>? = nil,
      selectedRouteID: RouteID
    ) {
      self.init(
        collapsedSectionIDs: collapsedSectionIDs,
        commandPaletteQuery: commandPaletteQuery,
        commandPolicy: commandPolicy,
        isCommandPalettePresented: isCommandPalettePresented,
        navigation: navigation,
        pinnedRouteIDs: [],
        recentCommandIDs: recentCommandIDs,
        recentCommandLimit: recentCommandLimit,
        recentRouteIDs: [],
        recentRouteLimit: 8,
        selectedCommandID: selectedCommandID,
        selectedRouteID: selectedRouteID
      )
    }

    public var availableCommands: [WorkspaceCommand<RouteID>] {
      var commands = navigation.routeCommands
      commands.append(contentsOf: navigation.sceneCommands)
      commands.append(contentsOf: navigation.commands)
      return commands.filter { !$0.isHidden }
    }

    public var filteredCommands: [WorkspaceCommand<RouteID>] {
      WorkspaceCommandSearch.filteredCommands(
        availableCommands,
        query: commandPaletteQuery,
        recentCommandIDs: recentCommandIDs
      )
    }

    public var recentCommands: [WorkspaceCommand<RouteID>] {
      var commandsByID: [WorkspaceCommandIdentifier<RouteID>: WorkspaceCommand<RouteID>] = [:]
      for command in availableCommands where commandsByID[command.id] == nil {
        commandsByID[command.id] = command
      }
      return recentCommandIDs.compactMap { commandsByID[$0] }
    }

    public var pinnedRoutes: [WorkspaceRouteDescriptor<RouteID>] {
      pinnedRouteIDs.compactMap(visibleRoute(for:))
    }

    public var recentRoutes: [WorkspaceRouteDescriptor<RouteID>] {
      recentRouteIDs.compactMap(visibleRoute(for:))
    }

    public var restorationState: WorkspaceRestoration<RouteID> {
      WorkspaceRestoration(
        selectedRouteID: selectedRouteID,
        collapsedSectionIDs: collapsedSectionIDs,
        pinnedRouteIDs: pinnedRouteIDs,
        recentCommandIDs: recentCommandIDs,
        recentRouteIDs: recentRouteIDs
      )
    }

    public var sections: [WorkspaceRouteSection<RouteID>] {
      get { navigation.sections }
      set { navigation.sections = newValue }
    }

    public var selectedCommand: WorkspaceCommand<RouteID>? {
      guard let selectedCommandID
      else { return filteredCommands.first }
      return filteredCommands.first { $0.id == selectedCommandID }
    }

    public var selectedRoute: WorkspaceRouteDescriptor<RouteID>? {
      visibleRoute(for: selectedRouteID)
    }

    public var visibleSections: [WorkspaceRouteSection<RouteID>] {
      sections.map { section in
        let visibleRoutes = section.routes.filter(\.availability.isVisible)
        guard isSectionExpanded(section.id)
        else { return section.withRoutes([]) }
        return section.withRoutes(visibleRoutes)
      }
    }

    public func route(for routeID: RouteID) -> WorkspaceRouteDescriptor<RouteID>? {
      sections.lazy.flatMap(\.routes).first { $0.id == routeID }
    }

    public func visibleRoute(for routeID: RouteID) -> WorkspaceRouteDescriptor<RouteID>? {
      guard let route = route(for: routeID), route.availability.isVisible
      else { return nil }
      return route
    }

    public func isSectionExpanded(_ sectionID: WorkspaceRouteSectionID) -> Bool {
      guard let section = sections.first(where: { $0.id == sectionID })
      else { return false }
      return !section.isCollapsible || !collapsedSectionIDs.contains(sectionID)
    }

    public func isRoutePinned(_ routeID: RouteID) -> Bool {
      pinnedRouteIDs.contains(routeID)
    }

    public var firstSelectableRouteID: RouteID? {
      sections
        .lazy
        .flatMap(\.routes)
        .first { route in
          route.availability.isVisible && route.availability.isEnabled
        }?
        .id
    }

    public func routeOpenRejectionReason(
      for routeID: RouteID
    ) -> WorkspaceRouteOpenRejectionReason? {
      guard let route = route(for: routeID)
      else { return .routeNotFound }

      if !route.availability.isVisible {
        return .routeHidden
      }

      if !route.availability.isEnabled {
        return .routeDisabled
      }

      return nil
    }

    public func sceneRequest(
      for routeID: RouteID,
      source: WorkspaceSceneRequestSource
    ) -> WorkspaceSceneRequest<RouteID>? {
      guard let route = route(for: routeID),
            route.availability.isEnabled,
            route.scenePresentation.opensInSeparateScene
      else { return nil }

      return WorkspaceSceneRequest(
        routeID: routeID,
        presentation: route.scenePresentation,
        source: source
      )
    }

    mutating func dismissCommandPalette() {
      commandPaletteQuery = ""
      isCommandPalettePresented = false
      selectedCommandID = nil
    }

    mutating func expandSection(containing routeID: RouteID) {
      guard let section = sections.first(where: { section in
        section.routes.contains(where: { $0.id == routeID })
      })
      else { return }
      collapsedSectionIDs.remove(section.id)
    }

    mutating func reconcileNavigation() {
      let collapsibleSectionIDs = Set(
        sections
          .filter(\.isCollapsible)
          .map(\.id)
      )
      collapsedSectionIDs.formIntersection(collapsibleSectionIDs)
      restorePinnedRoutes(pinnedRouteIDs)
      restoreRecentCommands(recentCommandIDs)
      restoreRecentRoutes(recentRouteIDs)

      if routeOpenRejectionReason(for: selectedRouteID) != nil,
         let firstSelectableRouteID {
        selectedRouteID = firstSelectableRouteID
      }

      expandSection(containing: selectedRouteID)
      syncSelectedCommandWithFilteredCommands()
    }

    @discardableResult
    mutating func recordRecentCommand(
      _ commandID: WorkspaceCommandIdentifier<RouteID>
    ) -> Bool {
      guard recentCommandLimit > 0
      else {
        let changed = !recentCommandIDs.isEmpty
        recentCommandIDs = []
        return changed
      }

      let previousCommandIDs = recentCommandIDs
      recentCommandIDs.removeAll { $0 == commandID }
      recentCommandIDs.insert(commandID, at: 0)
      trimRecentCommands()
      return previousCommandIDs != recentCommandIDs
    }

    @discardableResult
    mutating func clearRecentCommands() -> Bool {
      guard !recentCommandIDs.isEmpty
      else { return false }
      recentCommandIDs = []
      return true
    }

    @discardableResult
    mutating func clearRecentRoutes() -> Bool {
      guard !recentRouteIDs.isEmpty
      else { return false }
      recentRouteIDs = []
      return true
    }

    @discardableResult
    mutating func recordRecentRoute(_ routeID: RouteID) -> Bool {
      guard recentRouteLimit > 0
      else {
        let changed = !recentRouteIDs.isEmpty
        recentRouteIDs = []
        return changed
      }

      guard visibleRoute(for: routeID) != nil
      else { return false }

      let previousRouteIDs = recentRouteIDs
      recentRouteIDs.removeAll { $0 == routeID }
      recentRouteIDs.insert(routeID, at: 0)
      trimRecentRoutes()
      return previousRouteIDs != recentRouteIDs
    }

    mutating func restore(_ restorationState: WorkspaceRestoration<RouteID>) {
      let collapsibleSectionIDs = Set(
        sections
          .filter(\.isCollapsible)
          .map(\.id)
      )

      if routeOpenRejectionReason(for: restorationState.selectedRouteID) == nil {
        selectedRouteID = restorationState.selectedRouteID
      }

      collapsedSectionIDs = restorationState.collapsedSectionIDs
        .intersection(collapsibleSectionIDs)
      expandSection(containing: selectedRouteID)
      restorePinnedRoutes(restorationState.pinnedRouteIDs)
      restoreRecentCommands(restorationState.recentCommandIDs)
      restoreRecentRoutes(restorationState.recentRouteIDs)
      dismissCommandPalette()
    }

    @discardableResult
    mutating func setSection(
      _ sectionID: WorkspaceRouteSectionID,
      isExpanded: Bool
    ) -> Bool {
      guard sections.contains(where: { $0.id == sectionID && $0.isCollapsible }),
            isSectionExpanded(sectionID) != isExpanded
      else { return false }

      if isExpanded {
        collapsedSectionIDs.remove(sectionID)
      } else {
        collapsedSectionIDs.insert(sectionID)
      }
      return true
    }

    @discardableResult
    mutating func togglePinnedRoute(_ routeID: RouteID) -> Bool {
      guard visibleRoute(for: routeID) != nil
      else { return false }

      if let index = pinnedRouteIDs.firstIndex(of: routeID) {
        pinnedRouteIDs.remove(at: index)
      } else {
        pinnedRouteIDs.insert(routeID, at: 0)
      }
      return true
    }

    mutating func syncSelectedCommandWithFilteredCommands() {
      let commands = filteredCommands
      if let selectedCommandID, commands.contains(where: { $0.id == selectedCommandID }) {
        return
      }
      selectedCommandID = commands.first?.id
    }

    private mutating func restoreRecentCommands(
      _ commandIDs: [WorkspaceCommandIdentifier<RouteID>]
    ) {
      let availableCommandIDs = Set(availableCommands.map(\.id))
      var restoredCommandIDs: [WorkspaceCommandIdentifier<RouteID>] = []
      for commandID in commandIDs
      where availableCommandIDs.contains(commandID) && !restoredCommandIDs.contains(commandID) {
        restoredCommandIDs.append(commandID)
      }
      recentCommandIDs = restoredCommandIDs
      trimRecentCommands()
    }

    private mutating func restorePinnedRoutes(_ routeIDs: [RouteID]) {
      pinnedRouteIDs = uniqueVisibleRouteIDs(routeIDs)
    }

    private mutating func restoreRecentRoutes(_ routeIDs: [RouteID]) {
      recentRouteIDs = uniqueVisibleRouteIDs(routeIDs)
      trimRecentRoutes()
    }

    private mutating func trimRecentCommands() {
      let limit = max(0, recentCommandLimit)
      if recentCommandIDs.count > limit {
        recentCommandIDs.removeLast(recentCommandIDs.count - limit)
      }
    }

    private mutating func trimRecentRoutes() {
      let limit = max(0, recentRouteLimit)
      if recentRouteIDs.count > limit {
        recentRouteIDs.removeLast(recentRouteIDs.count - limit)
      }
    }

    private func uniqueVisibleRouteIDs(_ routeIDs: [RouteID]) -> [RouteID] {
      var restoredRouteIDs: [RouteID] = []
      var seenRouteIDs: Set<RouteID> = []
      for routeID in routeIDs
      where visibleRoute(for: routeID) != nil && seenRouteIDs.insert(routeID).inserted {
        restoredRouteIDs.append(routeID)
      }
      return restoredRouteIDs
    }
  }

  public enum Action: Sendable {
    case commandAutomationRequested(WorkspaceCommandIdentifier<RouteID>)
    case commandMenuCommandSelected(WorkspaceCommandIdentifier<RouteID>)
    case commandPaletteCommandSelected(WorkspaceCommandIdentifier<RouteID>)
    case commandPaletteDismissed
    case commandPaletteMoveSelection(WorkspaceCommandSelectionDirection)
    case commandPaletteQueryChanged(String)
    case commandPaletteRequested
    case commandPaletteReturnKeyPressed
    case commandPaletteSelectionChanged(WorkspaceCommandIdentifier<RouteID>?)
    case delegate(Delegate)
    case navigationRegistryChanged(WorkspaceNavigationRegistry<RouteID>)
    case recentCommandsCleared
    case recentRoutesCleared
    case restorationStateLoaded(WorkspaceRestoration<RouteID>)
    case routeOpenRequested(WorkspaceRouteOpenRequest<RouteID>)
    case routeMetadataPatchesApplied([WorkspaceRouteMetadataPatch<RouteID>])
    case routePinToggled(RouteID)
    case routeSelected(RouteID)
    case sceneRequested(RouteID)
    case sectionDisclosureButtonTapped(WorkspaceRouteSectionID)
    case sectionExpansionChanged(WorkspaceRouteSectionID, Bool)
    case primaryActionRequested(WorkspaceCommandID)
    case systemCommandRequested(WorkspaceCommandID)
    case toolbarActionRequested(WorkspaceCommandID)

    public enum Delegate: Equatable, Sendable {
      case commandExecutionDenied(WorkspaceCommandExecutionDenial<RouteID>)
      case commandRequested(WorkspaceCommandID)
      case navigationChanged
      case primaryActionRequested(WorkspaceCommandID)
      case restorationStateChanged(WorkspaceRestoration<RouteID>)
      case routeOpenRejected(WorkspaceRouteOpenRejection<RouteID>)
      case routeSelected(RouteID)
      case sceneRequested(WorkspaceSceneRequest<RouteID>)
      case sectionExpansionChanged(WorkspaceRouteSectionID, Bool)
      case systemCommandRequested(WorkspaceCommandID)
      case toolbarActionRequested(WorkspaceCommandID)
    }
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .commandAutomationRequested(let id):
        guard let command = state.availableCommands.first(where: { $0.id == id })
        else { return .none }
        return execute(
          command,
          state: &state,
          invocation: .automation,
          dismissesPalette: false
        )

      case .commandMenuCommandSelected(let id):
        guard let command = state.availableCommands.first(where: { $0.id == id })
        else { return .none }
        return execute(
          command,
          state: &state,
          invocation: .commandMenu,
          dismissesPalette: false
        )

      case .commandPaletteCommandSelected(let id):
        guard let command = state.availableCommands.first(where: { $0.id == id })
        else { return .none }
        return execute(
          command,
          state: &state,
          invocation: .commandPalette,
          dismissesPalette: true
        )

      case .commandPaletteDismissed:
        state.dismissCommandPalette()
        return .none

      case .commandPaletteMoveSelection(let direction):
        let commands = state.filteredCommands
        guard !commands.isEmpty
        else {
          state.selectedCommandID = nil
          return .none
        }

        let currentIndex = state.selectedCommandID
          .flatMap { id in commands.firstIndex { $0.id == id } }
        let nextIndex: Int
        switch (direction, currentIndex) {
        case (.down, .none):
          nextIndex = 0
        case (.down, let index?):
          nextIndex = commands.index(after: index) == commands.endIndex
            ? commands.startIndex
            : commands.index(after: index)
        case (.up, .none):
          nextIndex = commands.index(before: commands.endIndex)
        case (.up, let index?):
          nextIndex = index == commands.startIndex
            ? commands.index(before: commands.endIndex)
            : commands.index(before: index)
        }
        state.selectedCommandID = commands[nextIndex].id
        return .none

      case .commandPaletteQueryChanged(let query):
        state.commandPaletteQuery = query
        state.syncSelectedCommandWithFilteredCommands()
        return .none

      case .commandPaletteRequested:
        state.isCommandPalettePresented = true
        state.syncSelectedCommandWithFilteredCommands()
        return .none

      case .commandPaletteReturnKeyPressed:
        guard let command = state.selectedCommand
        else { return .none }
        return execute(
          command,
          state: &state,
          invocation: .commandPalette,
          dismissesPalette: true
        )

      case .commandPaletteSelectionChanged(let id):
        state.selectedCommandID = id
        return .none

      case .delegate:
        return .none

      case .navigationRegistryChanged(let navigation):
        let previousRestorationState = state.restorationState
        let previousSelectedRouteID = state.selectedRouteID
        state.navigation = navigation
        state.reconcileNavigation()
        return navigationChanged(
          state,
          previousRestorationState: previousRestorationState,
          previousSelectedRouteID: previousSelectedRouteID
        )

      case .primaryActionRequested(let id):
        return delegate(.primaryActionRequested(id))

      case .recentCommandsCleared:
        guard state.clearRecentCommands()
        else { return .none }
        return restorationStateChanged(state)

      case .recentRoutesCleared:
        guard state.clearRecentRoutes()
        else { return .none }
        return restorationStateChanged(state)

      case .restorationStateLoaded(let restorationState):
        state.restore(restorationState)
        return .none

      case .routeOpenRequested(let request):
        return open(request, state: &state)

      case .routeMetadataPatchesApplied(let patches):
        let previousRestorationState = state.restorationState
        let previousSelectedRouteID = state.selectedRouteID
        guard state.navigation.apply(patches)
        else { return .none }
        state.reconcileNavigation()
        return navigationChanged(
          state,
          previousRestorationState: previousRestorationState,
          previousSelectedRouteID: previousSelectedRouteID
        )

      case .routePinToggled(let id):
        guard state.togglePinnedRoute(id)
        else { return .none }
        return restorationStateChanged(state)

      case .routeSelected(let id):
        guard state.routeOpenRejectionReason(for: id) == nil
        else { return .none }
        let selectedRouteChanged = state.selectedRouteID != id
        let didRecordRecentRoute = state.recordRecentRoute(id)
        state.selectedRouteID = id
        state.dismissCommandPalette()
        state.expandSection(containing: id)
        if selectedRouteChanged {
          return delegate(.routeSelected(id), saving: state)
        }
        return didRecordRecentRoute ? restorationStateChanged(state) : .none

      case .sceneRequested(let id):
        guard let request = state.sceneRequest(for: id, source: .routeAction)
        else { return .none }
        return delegate(.sceneRequested(request))

      case .sectionDisclosureButtonTapped(let sectionID):
        guard state.sections.contains(where: { $0.id == sectionID && $0.isCollapsible })
        else { return .none }
        let nextExpansion = !state.isSectionExpanded(sectionID)
        guard state.setSection(sectionID, isExpanded: nextExpansion)
        else { return .none }
        return delegate(.sectionExpansionChanged(sectionID, nextExpansion), saving: state)

      case .sectionExpansionChanged(let sectionID, let isExpanded):
        guard state.setSection(sectionID, isExpanded: isExpanded)
        else { return .none }
        return delegate(.sectionExpansionChanged(sectionID, isExpanded), saving: state)

      case .systemCommandRequested(let id):
        return delegate(.systemCommandRequested(id))

      case .toolbarActionRequested(let id):
        return delegate(.toolbarActionRequested(id))
      }
    }
  }

  private func execute(
    _ command: WorkspaceCommand<RouteID>,
    state: inout State,
    invocation: WorkspaceCommandInvocation,
    dismissesPalette: Bool
  ) -> Effect<Action> {
    guard command.isEnabled
    else { return .none }

    if let denial = state.commandPolicy.denial(for: command, invocation: invocation) {
      if dismissesPalette {
        state.dismissCommandPalette()
      }
      return delegate(.commandExecutionDenied(denial))
    }

    let didRecordRecentCommand = state.recordRecentCommand(command.id)

    switch command.target {
    case .appAction(let id):
      if dismissesPalette {
        state.dismissCommandPalette()
      }
      return delegate(
        .commandRequested(id),
        saving: state,
        recordingRestorationState: didRecordRecentCommand
      )

    case .primaryAction(let id):
      if dismissesPalette {
        state.dismissCommandPalette()
      }
      return delegate(
        .primaryActionRequested(id),
        saving: state,
        recordingRestorationState: didRecordRecentCommand
      )

    case .route(let id):
      return selectRoute(
        id,
        state: &state,
        request: WorkspaceRouteOpenRequest(routeID: id),
        dismissesPalette: dismissesPalette,
        recordsRecentCommand: didRecordRecentCommand
      )

    case .scene(let id):
      if dismissesPalette {
        state.dismissCommandPalette()
      }
      guard let request = state.sceneRequest(for: id, source: .command)
      else {
        return didRecordRecentCommand ? restorationStateChanged(state) : .none
      }
      return delegate(
        .sceneRequested(request),
        saving: state,
        recordingRestorationState: didRecordRecentCommand
      )

    case .system(let id):
      if dismissesPalette {
        state.dismissCommandPalette()
      }
      return delegate(
        .systemCommandRequested(id),
        saving: state,
        recordingRestorationState: didRecordRecentCommand
      )

    case .toolbarAction(let id):
      if dismissesPalette {
        state.dismissCommandPalette()
      }
      return delegate(
        .toolbarActionRequested(id),
        saving: state,
        recordingRestorationState: didRecordRecentCommand
      )
    }
  }

  private func open(
    _ request: WorkspaceRouteOpenRequest<RouteID>,
    state: inout State
  ) -> Effect<Action> {
    if let rejectionReason = state.routeOpenRejectionReason(for: request.routeID) {
      return delegate(
        .routeOpenRejected(
          WorkspaceRouteOpenRejection(
            request: request,
            reason: rejectionReason
          )
        )
      )
    }

    if request.mode == .preferredScene,
       let sceneRequest = state.sceneRequest(
        for: request.routeID,
        source: .openRouteRequest
       ) {
      return delegate(.sceneRequested(sceneRequest))
    }

    return selectRoute(
      request.routeID,
      state: &state,
      request: request,
      dismissesPalette: true,
      recordsRecentCommand: false
    )
  }

  private func selectRoute(
    _ id: RouteID,
    state: inout State,
    request: WorkspaceRouteOpenRequest<RouteID>,
    dismissesPalette: Bool,
    recordsRecentCommand: Bool
  ) -> Effect<Action> {
    if let rejectionReason = state.routeOpenRejectionReason(for: id) {
      if dismissesPalette {
        state.dismissCommandPalette()
      }
      return delegate(
        .routeOpenRejected(
          WorkspaceRouteOpenRejection(
            request: request,
            reason: rejectionReason
          )
        )
      )
    }

    let selectedRouteChanged = state.selectedRouteID != id
    let didRecordRecentRoute = state.recordRecentRoute(id)
    state.selectedRouteID = id
    state.expandSection(containing: id)
    if dismissesPalette {
      state.dismissCommandPalette()
    }

    guard selectedRouteChanged
    else {
      return recordsRecentCommand || didRecordRecentRoute
        ? restorationStateChanged(state)
        : .none
    }

    return delegate(.routeSelected(id), saving: state)
  }

  private func delegate(
    _ delegate: Action.Delegate
  ) -> Effect<Action> {
    .send(.delegate(delegate))
  }

  private func delegate(
    _ delegate: Action.Delegate,
    saving state: State
  ) -> Effect<Action> {
    .merge(
      .send(.delegate(delegate)),
      restorationStateChanged(state)
    )
  }

  private func delegate(
    _ delegate: Action.Delegate,
    saving state: State,
    recordingRestorationState shouldSave: Bool
  ) -> Effect<Action> {
    guard shouldSave
    else { return self.delegate(delegate) }
    return self.delegate(delegate, saving: state)
  }

  private func restorationStateChanged(_ state: State) -> Effect<Action> {
    .send(.delegate(.restorationStateChanged(state.restorationState)))
  }

  private func navigationChanged(
    _ state: State,
    previousRestorationState: WorkspaceRestoration<RouteID>,
    previousSelectedRouteID: RouteID
  ) -> Effect<Action> {
    var effects: [Effect<Action>] = [
      .send(.delegate(.navigationChanged)),
    ]

    if state.selectedRouteID != previousSelectedRouteID {
      effects.append(.send(.delegate(.routeSelected(state.selectedRouteID))))
    }

    if state.restorationState != previousRestorationState {
      effects.append(restorationStateChanged(state))
    }

    return .merge(effects)
  }
}
