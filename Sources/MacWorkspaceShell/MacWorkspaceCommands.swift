#if os(macOS)
  import ComposableArchitecture
  import SwiftUI
  import WorkspaceCore
  import WorkspaceTCA

  /// Native menu configuration for workspace commands on macOS.
  public struct MacWorkspaceCommandMenuConfiguration: Equatable, Sendable {
    /// Whether disabled commands remain visible but disabled in the menu.
    public var includesDisabledCommands: Bool
    /// Whether the command palette command appears at the top of the custom menu.
    public var includesPaletteCommand: Bool
    /// How command entries are organized inside the custom menu.
    public var grouping: WorkspaceCommandGrouping

    public init(
      includesDisabledCommands: Bool = true,
      includesPaletteCommand: Bool = true,
      grouping: WorkspaceCommandGrouping = .category
    ) {
      self.includesDisabledCommands = includesDisabledCommands
      self.includesPaletteCommand = includesPaletteCommand
      self.grouping = grouping
    }

    public static let `default` = Self()
  }

  /// Installs workspace-level macOS menu commands for a workspace store.
  public struct MacWorkspaceCommands<RouteID: Hashable & Sendable>: Commands {
    private let configuration: MacWorkspaceCommandMenuConfiguration
    private let menuTitle: String
    private let replacesNewItem: Bool
    private let store: StoreOf<WorkspaceFeature<RouteID>>

    public init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      menuTitle: String = "Workspace",
      replacesNewItem: Bool = true,
      configuration: MacWorkspaceCommandMenuConfiguration = .default
    ) {
      self.configuration = configuration
      self.menuTitle = menuTitle
      self.replacesNewItem = replacesNewItem
      self.store = store
    }

    public var body: some Commands {
      if replacesNewItem {
        CommandGroup(replacing: .newItem) {
          MacWorkspaceNewItemCommands(store: store)
        }
      } else {
        CommandGroup(after: .newItem) {
          MacWorkspaceNewItemCommands(store: store)
        }
      }

      CommandMenu(menuTitle) {
        MacWorkspaceCommandMenuContent(
          store: store,
          configuration: configuration
        )
      }
    }
  }

  private struct MacWorkspaceNewItemCommands<RouteID: Hashable & Sendable>: View {
    @Bindable var store: StoreOf<WorkspaceFeature<RouteID>>

    var body: some View {
      ForEach(primaryCommands) { command in
        Button(command.title) {
          store.send(.commandMenuCommandSelected(command.id))
        }
        .macWorkspaceKeyboardShortcut(command.shortcut)
        .help(command.disabledReason ?? command.subtitle ?? command.title)
        .disabled(!command.isEnabled)
      }

      Button("Command Palette") {
        store.send(.commandPaletteRequested)
      }
      .macWorkspaceKeyboardShortcut(.commandPalette)
    }

    private var primaryCommands: [WorkspaceCommand<RouteID>] {
      store.availableCommands.filter { command in
        command.role == .primaryAction && !command.isHidden
      }
    }
  }

  private struct MacWorkspaceCommandMenuContent<RouteID: Hashable & Sendable>: View {
    @Bindable var store: StoreOf<WorkspaceFeature<RouteID>>
    let configuration: MacWorkspaceCommandMenuConfiguration

    var body: some View {
      if configuration.includesPaletteCommand {
        Button("Command Palette") {
          store.send(.commandPaletteRequested)
        }
        .macWorkspaceKeyboardShortcut(.commandPalette)

        Divider()
      }

      switch configuration.grouping {
      case .flat:
        ForEach(menuCommands) { command in
          commandButton(command)
        }

      case .category, .role, .source:
        ForEach(commandSections) { section in
          Section(section.title) {
            ForEach(section.commands) { command in
              commandButton(command)
            }
          }
        }
      }
    }

    private var commandSections: [WorkspaceCommandSection<RouteID>] {
      WorkspaceCommandSections.make(
        for: store.availableCommands,
        grouping: configuration.grouping,
        includesDisabledCommands: configuration.includesDisabledCommands
      )
    }

    private var menuCommands: [WorkspaceCommand<RouteID>] {
      WorkspaceCommandSections.make(
        for: store.availableCommands,
        grouping: .flat,
        includesDisabledCommands: configuration.includesDisabledCommands
      )
      .first?
      .commands ?? []
    }

    private func commandButton(_ command: WorkspaceCommand<RouteID>) -> some View {
      Button(command.title) {
        store.send(.commandMenuCommandSelected(command.id))
      }
      .macWorkspaceKeyboardShortcut(command.shortcut)
      .help(command.disabledReason ?? command.subtitle ?? command.title)
      .disabled(!command.isEnabled)
    }
  }
#endif
