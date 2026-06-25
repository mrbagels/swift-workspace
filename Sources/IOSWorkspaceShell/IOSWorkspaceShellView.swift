#if os(iOS)
  import ComposableArchitecture
  import SwiftUI
  import WorkspaceCore
  import WorkspaceTCA

  private enum IOSWorkspaceCommandSearchFocusField: Hashable {
    case search
  }

  private enum IOSWorkspaceAccessibility {
    static func identifierComponent(_ value: String) -> String {
      var identifier = ""
      var previousWasSeparator = false

      for scalar in value.lowercased().unicodeScalars {
        if CharacterSet.alphanumerics.contains(scalar) {
          identifier.unicodeScalars.append(scalar)
          previousWasSeparator = false
        } else if !previousWasSeparator {
          identifier.append("-")
          previousWasSeparator = true
        }
      }

      let trimmed = identifier.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
      return trimmed.isEmpty ? "unknown" : trimmed
    }

    static func commandIdentifier<RouteID: Hashable & Sendable>(
      _ commandID: WorkspaceCommandIdentifier<RouteID>
    ) -> String {
      switch commandID {
      case .appAction(let id):
        "ios-workspace-command-app-\(identifierComponent(id.rawValue))"
      case .primaryAction(let id):
        "ios-workspace-command-primary-\(identifierComponent(id.rawValue))"
      case .route(let id):
        routeIdentifier(id)
      case .scene(let id):
        sceneButtonIdentifier(id)
      case .system(let id):
        "ios-workspace-command-system-\(identifierComponent(id.rawValue))"
      case .toolbarAction(let id):
        "ios-workspace-command-toolbar-\(identifierComponent(id.rawValue))"
      }
    }

    static func commandSearchRowIdentifier<RouteID: Hashable & Sendable>(
      _ commandID: WorkspaceCommandIdentifier<RouteID>
    ) -> String {
      "\(commandIdentifier(commandID))-search-row"
    }

    static func detailIdentifier<RouteID>(_ routeID: RouteID) -> String {
      "ios-workspace-detail-\(identifierComponent(String(describing: routeID)))"
    }

    static func routeIdentifier<RouteID>(_ routeID: RouteID) -> String {
      "ios-workspace-route-\(identifierComponent(String(describing: routeID)))"
    }

    static func sceneButtonIdentifier<RouteID>(_ routeID: RouteID) -> String {
      "ios-workspace-open-scene-\(identifierComponent(String(describing: routeID)))"
    }

    static func sectionIdentifier(_ sectionID: WorkspaceRouteSectionID) -> String {
      "ios-workspace-route-section-\(identifierComponent(sectionID))"
    }
  }

  /// An iOS and iPadOS renderer for the platform-neutral workspace engine.
  public struct IOSWorkspaceShellView<RouteID: Hashable & Sendable, Content: View>: View {
    @Bindable public var store: StoreOf<WorkspaceFeature<RouteID>>
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var compactNavigationPath: [RouteID] = []

    private let configuration: IOSWorkspaceShellConfiguration
    private let content: (WorkspaceRouteDescriptor<RouteID>?) -> Content

    public init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: IOSWorkspaceShellConfiguration = .default,
      @ViewBuilder content: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> Content
    ) {
      self.store = store
      self.configuration = configuration
      self.content = content
    }

    public var body: some View {
      shell
        .navigationTitle(configuration.title)
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            Button {
              store.send(.commandPaletteRequested)
            } label: {
              Label("Command Search", systemImage: "command")
            }
            .keyboardShortcut("k")
            .accessibilityIdentifier("ios-workspace-command-search-button")

            Button {
              store.send(.recentCommandsCleared)
            } label: {
              Label("Clear Recent Commands", systemImage: "clock.arrow.circlepath")
            }
            .disabled(store.recentCommandIDs.isEmpty)
            .accessibilityIdentifier("ios-workspace-clear-recent-commands-button")
          }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(configuration.title)
        .accessibilityIdentifier("ios-workspace-shell")
        .sheet(
          isPresented: Binding(
            get: { store.isCommandPalettePresented },
            set: { isPresented in
              if isPresented {
                store.send(.commandPaletteRequested)
              } else {
                store.send(.commandPaletteDismissed)
              }
            }
          )
        ) {
          IOSWorkspaceCommandSearchView(
            store: store,
            configuration: configuration
          )
          .presentationDetents([.medium, .large])
        }
        .onChange(of: store.selectedRouteID) { _, selectedRouteID in
          syncCompactPath(with: selectedRouteID)
        }
    }

    @ViewBuilder
    private var shell: some View {
      if usesStackNavigation {
        compactStackShell
      } else {
        splitShell
      }
    }

    @ViewBuilder
    private var splitShell: some View {
      switch configuration.navigationStyle {
      case .automatic:
        NavigationSplitView {
          routeList
        } detail: {
          detail(for: store.selectedRoute)
        }
        .navigationSplitViewStyle(.automatic)
      case .split:
        NavigationSplitView {
          routeList
        } detail: {
          detail(for: store.selectedRoute)
        }
        .navigationSplitViewStyle(.balanced)
      case .stack:
        NavigationSplitView {
          routeList
        } detail: {
          detail(for: store.selectedRoute)
        }
        .navigationSplitViewStyle(.prominentDetail)
      }
    }

    private var compactStackShell: some View {
      NavigationStack(path: $compactNavigationPath) {
        routeList
          .navigationTitle(configuration.title)
          .navigationDestination(for: RouteID.self) { routeID in
            let route = visibleRoute(for: routeID)
            detail(for: route)
              .navigationTitle(route?.title ?? configuration.title)
          }
      }
      .onAppear {
        syncCompactPath(with: store.selectedRouteID)
      }
    }

    private var routeList: some View {
      List {
        ForEach(store.visibleSections) { section in
          Section(section.title) {
            ForEach(section.routes) { route in
              Button {
                select(route)
              } label: {
                IOSWorkspaceRouteRow(
                  route: route,
                  isSelected: store.selectedRouteID == route.id,
                  prefersBadges: configuration.prefersBadges
                )
              }
              .disabled(!route.availability.isEnabled)
              .accessibilityIdentifier(IOSWorkspaceAccessibility.routeIdentifier(route.id))
              .contextMenu {
                if route.scenePresentation.opensInSeparateScene {
                  Button("Open in New Window") {
                    store.send(.sceneRequested(route.id))
                  }
                  .accessibilityIdentifier(
                    IOSWorkspaceAccessibility.sceneButtonIdentifier(route.id)
                  )
                }
              }
            }
          }
          .accessibilityIdentifier(
            IOSWorkspaceAccessibility.sectionIdentifier(section.id)
          )
        }
      }
      .navigationTitle(configuration.title)
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Workspace routes")
      .accessibilityIdentifier("ios-workspace-route-list")
    }

    private func detail(
      for route: WorkspaceRouteDescriptor<RouteID>?
    ) -> some View {
      content(route)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(route?.title ?? "Workspace Detail")
        .accessibilityIdentifier(
          route.map(IOSWorkspaceAccessibility.detailIdentifier)
          ?? "ios-workspace-detail-empty"
        )
    }

    private var usesStackNavigation: Bool {
      configuration.usesStackNavigation(isCompactWidth: horizontalSizeClass == .compact)
    }

    private func select(_ route: WorkspaceRouteDescriptor<RouteID>) {
      store.send(.routeSelected(route.id))
      guard usesStackNavigation else { return }
      compactNavigationPath = [route.id]
    }

    private func syncCompactPath(with routeID: RouteID) {
      guard usesStackNavigation else { return }
      if compactNavigationPath.last != routeID {
        compactNavigationPath = [routeID]
      }
    }

    private func visibleRoute(for routeID: RouteID) -> WorkspaceRouteDescriptor<RouteID>? {
      store.visibleSections
        .lazy
        .flatMap(\.routes)
        .first { $0.id == routeID }
    }
  }

  private struct IOSWorkspaceRouteRow<RouteID: Hashable & Sendable>: View {
    let route: WorkspaceRouteDescriptor<RouteID>
    let isSelected: Bool
    let prefersBadges: Bool

    var body: some View {
      HStack(spacing: 10) {
        Label {
          VStack(alignment: .leading, spacing: 2) {
            Text(route.title)
              .fontWeight(isSelected ? .semibold : .regular)

            if let subtitle = route.subtitle {
              Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        } icon: {
          Image(systemName: route.systemImage)
        }

        Spacer()

        if prefersBadges, let badge = route.badge {
          Text("\(badge)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      }
      .contentShape(Rectangle())
    }
  }

  private struct IOSWorkspaceCommandSearchView<RouteID: Hashable & Sendable>: View {
    @Bindable var store: StoreOf<WorkspaceFeature<RouteID>>

    let configuration: IOSWorkspaceShellConfiguration
    @FocusState private var focusedField: IOSWorkspaceCommandSearchFocusField?
    @State private var focusTask: Task<Void, Never>?

    var body: some View {
      NavigationSplitView {
        List {
          Section {
            TextField(
              configuration.commandSearchPlaceholder,
              text: Binding(
                get: { store.commandPaletteQuery },
                set: { store.send(.commandPaletteQueryChanged($0)) }
              )
            )
            .focused($focusedField, equals: .search)
            .defaultFocus($focusedField, .search)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .accessibilityLabel("Command search")
            .accessibilityHint("Search workspace commands and routes.")
            .accessibilityIdentifier("ios-workspace-command-search-field")
            .onSubmit {
              store.send(.commandPaletteReturnKeyPressed)
            }
          }

          if store.filteredCommands.isEmpty {
            ContentUnavailableView(
              "No Commands",
              systemImage: "command",
              description: Text("Try another search.")
            )
            .accessibilityIdentifier("ios-workspace-command-search-empty-state")
          } else {
            Section {
              ForEach(store.filteredCommands) { command in
                Button {
                  store.send(.commandPaletteCommandSelected(command.id))
                } label: {
                  IOSWorkspaceCommandRow(
                    command: command,
                    isSelected: store.selectedCommand?.id == command.id
                  )
                }
                .disabled(!command.isEnabled)
                .accessibilityHint(
                  command.isEnabled
                  ? "Runs the selected workspace command."
                  : command.disabledReason ?? "This command is unavailable."
                )
                .accessibilityIdentifier(
                  IOSWorkspaceAccessibility.commandSearchRowIdentifier(command.id)
                )
              }
            }
            .accessibilityIdentifier("ios-workspace-command-search-results")
          }
        }
        .navigationTitle("Command Search")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ios-workspace-command-search-list")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Done") {
              store.send(.commandPaletteDismissed)
            }
            .accessibilityIdentifier("ios-workspace-command-search-done-button")
          }
        }
      } detail: {
        if let command = store.selectedCommand {
          IOSWorkspaceCommandDetail(command: command)
        } else {
          ContentUnavailableView("No Command", systemImage: "command")
            .accessibilityIdentifier("ios-workspace-command-search-detail-empty")
        }
      }
      .onAppear {
        store.send(.commandPaletteRequested)
        focusSearchField()
      }
      .onChange(of: store.isCommandPalettePresented) { _, isPresented in
        if isPresented {
          focusSearchField()
        }
      }
      .onDisappear {
        focusTask?.cancel()
        focusTask = nil
        focusedField = nil
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("ios-workspace-command-search")
    }

    private func focusSearchField() {
      focusTask?.cancel()
      focusedField = nil
      focusTask = Task { @MainActor in
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(80))
        guard !Task.isCancelled else { return }
        focusedField = .search
      }
    }
  }

  private struct IOSWorkspaceCommandRow<RouteID: Hashable & Sendable>: View {
    let command: WorkspaceCommand<RouteID>
    let isSelected: Bool

    var body: some View {
      HStack(spacing: 10) {
        Image(systemName: command.systemImage)
          .frame(width: 24)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 2) {
          Text(command.title)
            .fontWeight(isSelected ? .semibold : .regular)
          Text(command.categoryTitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        if let shortcut = command.shortcut {
          Text(shortcut.displayLabel)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
        }
      }
      .contentShape(Rectangle())
    }
  }

  private struct IOSWorkspaceCommandDetail<RouteID: Hashable & Sendable>: View {
    let command: WorkspaceCommand<RouteID>

    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        Label(command.title, systemImage: command.systemImage)
          .font(.title2.bold())

        Text(command.categoryTitle)
          .font(.callout)
          .foregroundStyle(.secondary)

        if let subtitle = command.subtitle {
          Text(subtitle)
            .foregroundStyle(.secondary)
        }

        if let disabledReason = command.disabledReason, !command.isEnabled {
          Text(disabledReason)
            .font(.callout)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }
      .padding(24)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(
        IOSWorkspaceAccessibility.commandIdentifier(command.id) + "-detail"
      )
    }
  }
#else
  public enum IOSWorkspaceShellUnavailable {}
#endif
