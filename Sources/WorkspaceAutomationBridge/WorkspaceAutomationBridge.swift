import Foundation
import WorkspaceCore

/// Whether an automation should open the host app or run through app-owned inline logic.
public enum WorkspaceAutomationLaunchPolicy: String, Codable, Equatable, Sendable {
  case inline
  case openApp
}

/// The system-facing command family exposed by the automation bridge.
public enum WorkspaceAutomationKind: String, Codable, Equatable, Sendable {
  case appAction
  case openRoute
  case openScene
  case primaryAction
  case systemAction
  case toolbarAction
}

/// Serializable command metadata suitable for App Intents, Shortcuts, widgets, controls, and tests.
public struct WorkspaceAutomationCommandDescriptor:
  Codable,
  Equatable,
  Identifiable,
  Sendable
{
  public var id: String
  public var disabledReason: String?
  public var isEnabled: Bool
  public var kind: WorkspaceAutomationKind
  public var launchPolicy: WorkspaceAutomationLaunchPolicy
  public var phraseTemplates: [String]
  public var role: WorkspaceCommandRole
  public var routeID: String?
  public var shortcutLabel: String?
  public var source: WorkspaceCommandSource
  public var subtitle: String?
  public var systemImage: String
  public var title: String

  public init(
    id: String,
    title: String,
    systemImage: String,
    kind: WorkspaceAutomationKind,
    launchPolicy: WorkspaceAutomationLaunchPolicy,
    role: WorkspaceCommandRole,
    source: WorkspaceCommandSource,
    subtitle: String? = nil,
    routeID: String? = nil,
    shortcutLabel: String? = nil,
    phraseTemplates: [String] = [],
    isEnabled: Bool = true,
    disabledReason: String? = nil
  ) {
    self.id = id
    self.disabledReason = disabledReason
    self.isEnabled = isEnabled
    self.kind = kind
    self.launchPolicy = launchPolicy
    self.phraseTemplates = phraseTemplates
    self.role = role
    self.routeID = routeID
    self.shortcutLabel = shortcutLabel
    self.source = source
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.title = title
  }
}

/// A small handoff payload an App Intent can pass back to the main app scene.
public struct WorkspaceAutomationHandoff: Codable, Equatable, Identifiable, Sendable {
  public var id: UUID
  public var commandID: String
  public var kind: WorkspaceAutomationKind
  public var routeID: String?
  public var source: String

  public init(
    id: UUID = UUID(),
    commandID: String,
    kind: WorkspaceAutomationKind,
    routeID: String? = nil,
    source: String = "app-intent"
  ) {
    self.id = id
    self.commandID = commandID
    self.kind = kind
    self.routeID = routeID
    self.source = source
  }
}

/// App Shortcut metadata that host app targets can bind to concrete App Intent types.
public struct WorkspaceAppShortcutDescriptor: Codable, Equatable, Identifiable, Sendable {
  public var id: String
  public var commandID: String
  public var phraseTemplates: [String]
  public var shortTitle: String
  public var systemImageName: String

  public init(
    id: String,
    commandID: String,
    shortTitle: String,
    systemImageName: String,
    phraseTemplates: [String]
  ) {
    self.id = id
    self.commandID = commandID
    self.phraseTemplates = phraseTemplates
    self.shortTitle = shortTitle
    self.systemImageName = systemImageName
  }
}

/// Builds an automation catalog from the shared workspace command registry.
public struct WorkspaceAutomationCatalog: Codable, Equatable, Sendable {
  public var commands: [WorkspaceAutomationCommandDescriptor]
  public var shortcuts: [WorkspaceAppShortcutDescriptor]

  public init(
    commands: [WorkspaceAutomationCommandDescriptor],
    shortcuts: [WorkspaceAppShortcutDescriptor]
  ) {
    self.commands = commands
    self.shortcuts = shortcuts
  }

  public func command(id: String) -> WorkspaceAutomationCommandDescriptor? {
    commands.first { $0.id == id }
  }

  public func handoff(
    for commandID: String,
    source: String = "app-intent"
  ) -> WorkspaceAutomationHandoff? {
    command(id: commandID).map {
      WorkspaceAutomationHandoff(
        commandID: $0.id,
        kind: $0.kind,
        routeID: $0.routeID,
        source: source
      )
    }
  }

  public static func make<RouteID: Hashable & Sendable>(
    from registry: WorkspaceNavigationRegistry<RouteID>,
    routeIdentifier: @escaping @Sendable (RouteID) -> String,
    appNamePlaceholder: String = "{applicationName}",
    inlineRoles: Set<WorkspaceCommandRole> = [.appAction, .primaryAction, .system, .toolbarAction],
    shortcutLimit: Int = 6
  ) -> Self {
    let commands = (registry.routeCommands + registry.sceneCommands + registry.commands)
      .filter { !$0.isHidden }
      .map { command in
        descriptor(
          for: command,
          routeIdentifier: routeIdentifier,
          appNamePlaceholder: appNamePlaceholder,
          inlineRoles: inlineRoles
        )
      }

    let shortcuts = commands
      .filter(\.isEnabled)
      .prefix(max(0, shortcutLimit))
      .map { command in
        WorkspaceAppShortcutDescriptor(
          id: "shortcut.\(command.id)",
          commandID: command.id,
          shortTitle: command.title,
          systemImageName: command.systemImage,
          phraseTemplates: command.phraseTemplates
        )
      }

    return Self(commands: commands, shortcuts: Array(shortcuts))
  }

  private static func descriptor<RouteID: Hashable & Sendable>(
    for command: WorkspaceCommand<RouteID>,
    routeIdentifier: @escaping @Sendable (RouteID) -> String,
    appNamePlaceholder: String,
    inlineRoles: Set<WorkspaceCommandRole>
  ) -> WorkspaceAutomationCommandDescriptor {
    let routeID: String?
    let kind: WorkspaceAutomationKind
    switch command.target {
    case .appAction:
      routeID = nil
      kind = .appAction
    case .primaryAction:
      routeID = nil
      kind = .primaryAction
    case .route(let id):
      routeID = routeIdentifier(id)
      kind = .openRoute
    case .scene(let id):
      routeID = routeIdentifier(id)
      kind = .openScene
    case .system:
      routeID = nil
      kind = .systemAction
    case .toolbarAction:
      routeID = nil
      kind = .toolbarAction
    }

    return WorkspaceAutomationCommandDescriptor(
      id: automationIdentifier(for: command.id, routeIdentifier: routeIdentifier),
      title: command.title,
      systemImage: command.systemImage,
      kind: kind,
      launchPolicy: inlineRoles.contains(command.role) ? .inline : .openApp,
      role: command.role,
      source: command.source,
      subtitle: command.subtitle,
      routeID: routeID,
      shortcutLabel: command.shortcut?.displayLabel,
      phraseTemplates: phraseTemplates(
        for: command,
        kind: kind,
        appNamePlaceholder: appNamePlaceholder
      ),
      isEnabled: command.isEnabled,
      disabledReason: command.disabledReason
    )
  }

  private static func automationIdentifier<RouteID: Hashable & Sendable>(
    for id: WorkspaceCommandIdentifier<RouteID>,
    routeIdentifier: @escaping @Sendable (RouteID) -> String
  ) -> String {
    switch id {
    case .appAction(let id):
      "app.\(id.rawValue)"
    case .primaryAction(let id):
      "primary.\(id.rawValue)"
    case .route(let id):
      "route.\(routeIdentifier(id))"
    case .scene(let id):
      "scene.\(routeIdentifier(id))"
    case .system(let id):
      "system.\(id.rawValue)"
    case .toolbarAction(let id):
      "toolbar.\(id.rawValue)"
    }
  }

  private static func phraseTemplates<RouteID: Hashable & Sendable>(
    for command: WorkspaceCommand<RouteID>,
    kind: WorkspaceAutomationKind,
    appNamePlaceholder: String
  ) -> [String] {
    switch kind {
    case .openRoute:
      [
        "Open \(command.title) in \(appNamePlaceholder)",
        "Show \(command.title) in \(appNamePlaceholder)",
      ]
    case .openScene:
      [
        "Open \(command.title) in a new window with \(appNamePlaceholder)",
      ]
    case .appAction, .primaryAction, .systemAction, .toolbarAction:
      [
        "\(command.title) with \(appNamePlaceholder)",
      ]
    }
  }
}
