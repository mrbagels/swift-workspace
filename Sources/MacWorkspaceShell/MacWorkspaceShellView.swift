#if os(macOS)
  import ComposableArchitecture
  import SwiftUI
  import WorkspaceCore
  import WorkspaceTCA

  /// A first-pass macOS renderer for the platform-neutral workspace engine.
  public struct MacWorkspaceShellView<
    RouteID: Hashable & Sendable,
    Content: View,
    SidebarFooter: View
  >: View {
    @Bindable public var store: StoreOf<WorkspaceFeature<RouteID>>

    private let configuration: MacWorkspaceShellConfiguration
    private let content: (WorkspaceRouteDescriptor<RouteID>?) -> Content
    private let sidebarFooter: () -> SidebarFooter

    public init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: MacWorkspaceShellConfiguration = .default,
      @ViewBuilder sidebarFooter: @escaping () -> SidebarFooter,
      @ViewBuilder content: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> Content
    ) {
      self.store = store
      self.configuration = configuration
      self.sidebarFooter = sidebarFooter
      self.content = content
    }

    public var body: some View {
      NavigationSplitView {
        sidebar
          .navigationSplitViewColumnWidth(
            min: configuration.sidebarMinimumWidth,
            ideal: configuration.sidebarIdealWidth,
            max: configuration.sidebarMaximumWidth
          )
      } detail: {
        content(store.selectedRoute)
          .frame(minWidth: configuration.detailMinimumWidth)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .navigationTitle(configuration.title)
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Button {
            store.send(.commandPaletteRequested)
          } label: {
            Label("Command Palette", systemImage: "command")
          }
          .help("Command Palette")
          .keyboardShortcut("k")

          Button {
            store.send(.recentCommandsCleared)
          } label: {
            Label("Clear Recent Commands", systemImage: "clock.arrow.circlepath")
          }
          .help("Clear Recent Commands")
          .disabled(store.recentCommandIDs.isEmpty)
        }
      }
      .overlay {
        if store.isCommandPalettePresented {
          MacWorkspaceCommandPalette(
            store: store,
            configuration: configuration
          )
        }
      }
    }

    private var sidebar: some View {
      List {
        ForEach(store.visibleSections) { section in
          Section(section.title) {
            ForEach(section.routes) { route in
              Button {
                store.send(.routeSelected(route.id))
              } label: {
                HStack {
                  Label(route.title, systemImage: route.systemImage)
                    .fontWeight(store.selectedRouteID == route.id ? .semibold : .regular)
                  Spacer()
                  if let badge = route.badge {
                    Text("\(badge)")
                      .font(.caption.monospacedDigit())
                      .foregroundStyle(.secondary)
                  }
                }
              }
              .buttonStyle(.plain)
              .accessibilityLabel(route.title)
              .disabled(!route.availability.isEnabled)
              .contextMenu {
                if route.scenePresentation.opensInSeparateScene {
                  Button("Open in New Window") {
                    store.send(.sceneRequested(route.id))
                  }
                }
              }
            }
          }
        }

        sidebarFooter()
      }
      .listStyle(.sidebar)
    }
  }

  public extension MacWorkspaceShellView where SidebarFooter == EmptyView {
    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: MacWorkspaceShellConfiguration = .default,
      @ViewBuilder content: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> Content
    ) {
      self.init(
        store: store,
        configuration: configuration,
        sidebarFooter: { EmptyView() },
        content: content
      )
    }
  }

  private struct MacWorkspaceCommandPalette<RouteID: Hashable & Sendable>: View {
    @Bindable var store: StoreOf<WorkspaceFeature<RouteID>>

    let configuration: MacWorkspaceShellConfiguration
    @FocusState private var isSearchFocused: Bool

    var body: some View {
      ZStack(alignment: .top) {
        Rectangle()
          .fill(.black.opacity(0.16))
          .ignoresSafeArea()
          .onTapGesture {
            store.send(.commandPaletteDismissed)
          }

        VStack(spacing: 0) {
          searchField
          Divider()
          results
        }
        .frame(width: configuration.commandPaletteWidth, height: 440)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(.quaternary, lineWidth: 1)
        }
        .shadow(radius: 24, y: 12)
        .padding(.top, 56)
      }
      .onAppear {
        store.send(.commandPaletteRequested)
        isSearchFocused = true
      }
      .onExitCommand {
        store.send(.commandPaletteDismissed)
      }
      .onMoveCommand { direction in
        switch direction {
        case .down:
          store.send(.commandPaletteMoveSelection(.down))
        case .up:
          store.send(.commandPaletteMoveSelection(.up))
        default:
          break
        }
      }
    }

    private var searchField: some View {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)

        TextField(
          configuration.searchPlaceholder,
          text: Binding(
            get: { store.commandPaletteQuery },
            set: { store.send(.commandPaletteQueryChanged($0)) }
          )
        )
        .textFieldStyle(.plain)
        .focused($isSearchFocused)
        .onSubmit {
          store.send(.commandPaletteReturnKeyPressed)
        }

        if !store.commandPaletteQuery.isEmpty {
          Button {
            store.send(.commandPaletteQueryChanged(""))
          } label: {
            Image(systemName: "xmark.circle.fill")
          }
          .buttonStyle(.plain)
          .foregroundStyle(.secondary)
          .help("Clear Search")
        }
      }
      .padding(.horizontal, 16)
      .frame(height: 48)
    }

    private var results: some View {
      ScrollView {
        LazyVStack(spacing: 0) {
          if store.filteredCommands.isEmpty {
            ContentUnavailableView(
              "No Commands",
              systemImage: "command",
              description: Text("Try another search.")
            )
            .frame(height: 300)
          } else {
            ForEach(store.filteredCommands) { command in
              Button {
                store.send(.commandPaletteCommandSelected(command.id))
              } label: {
                MacWorkspaceCommandRow(
                  command: command,
                  isSelected: store.selectedCommand?.id == command.id
                )
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(8)
      }
    }
  }

  private struct MacWorkspaceCommandRow<RouteID: Hashable & Sendable>: View {
    let command: WorkspaceCommand<RouteID>
    let isSelected: Bool

    var body: some View {
      HStack(spacing: 10) {
        Image(systemName: command.systemImage)
          .frame(width: 22)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 2) {
          Text(command.title)
            .font(.callout)
            .lineLimit(1)
          Text(command.categoryTitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer()

        if let shortcut = command.shortcut {
          Text(shortcut.displayLabel)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 10)
      .frame(height: 44)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.accentColor.opacity(0.18))
        }
      }
      .contentShape(Rectangle())
    }
  }

  /// A macOS command reference surface backed by the shared command registry.
  public struct MacWorkspaceCommandReferenceView<RouteID: Hashable & Sendable>: View {
    private let commands: [WorkspaceCommand<RouteID>]
    private let configuration: WorkspaceCommandReferenceConfiguration

    public init(
      commands: [WorkspaceCommand<RouteID>],
      configuration: WorkspaceCommandReferenceConfiguration = .default
    ) {
      self.commands = commands
      self.configuration = configuration
    }

    public init(
      state: WorkspaceFeature<RouteID>.State,
      configuration: WorkspaceCommandReferenceConfiguration = .default
    ) {
      self.init(
        commands: state.availableCommands,
        configuration: configuration
      )
    }

    public var body: some View {
      List {
        ForEach(sections) { section in
          Section(section.title) {
            ForEach(section.commands) { command in
              MacWorkspaceCommandRow(
                command: command,
                isSelected: false
              )
            }
          }
        }
      }
      .navigationTitle("Commands")
    }

    private var sections: [WorkspaceCommandSection<RouteID>] {
      WorkspaceCommandSections.make(
        for: commands,
        grouping: configuration.grouping,
        includesDisabledCommands: configuration.includesDisabledCommands
      )
    }
  }
#else
  public enum MacWorkspaceShellUnavailable {}
#endif
