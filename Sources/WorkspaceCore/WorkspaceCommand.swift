import Foundation

/// The surface that contributed a command to the unified command registry.
public enum WorkspaceCommandSource: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
  case app
  case navigation
  case primaryAction
  case system
  case toolbar

  public var displayTitle: String {
    switch self {
    case .app:
      "App"
    case .navigation:
      "Navigation"
    case .primaryAction:
      "Primary"
    case .system:
      "Workspace"
    case .toolbar:
      "Toolbar"
    }
  }
}

/// The semantic behavior represented by a command.
public enum WorkspaceCommandRole: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
  case appAction
  case navigation
  case primaryAction
  case scene
  case system
  case toolbarAction

  public var displayTitle: String {
    switch self {
    case .appAction:
      "App Action"
    case .navigation:
      "Navigation"
    case .primaryAction:
      "Primary Action"
    case .scene:
      "Scene"
    case .system:
      "System"
    case .toolbarAction:
      "Toolbar Action"
    }
  }
}

/// Directional movement through command search results.
public enum WorkspaceCommandSelectionDirection: Equatable, Sendable {
  case down
  case up
}

/// The surface or automation path requesting command execution.
public enum WorkspaceCommandInvocation: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
  case automation
  case commandMenu
  case commandPalette
  case control
}

/// A typed command identifier that remains stable across surfaces.
public enum WorkspaceCommandIdentifier<RouteID: Hashable & Sendable>:
  Equatable,
  Hashable,
  Sendable
{
  case appAction(WorkspaceCommandID)
  case primaryAction(WorkspaceCommandID)
  case route(RouteID)
  case scene(RouteID)
  case system(WorkspaceCommandID)
  case toolbarAction(WorkspaceCommandID)
}

extension WorkspaceCommandIdentifier: Codable where RouteID: Codable {}

/// The behavior the engine should execute when a command is selected.
public enum WorkspaceCommandTarget<RouteID: Hashable & Sendable>: Equatable, Sendable {
  case appAction(WorkspaceCommandID)
  case primaryAction(WorkspaceCommandID)
  case route(RouteID)
  case scene(RouteID)
  case system(WorkspaceCommandID)
  case toolbarAction(WorkspaceCommandID)

  public var role: WorkspaceCommandRole {
    switch self {
    case .appAction:
      .appAction
    case .primaryAction:
      .primaryAction
    case .route:
      .navigation
    case .scene:
      .scene
    case .system:
      .system
    case .toolbarAction:
      .toolbarAction
    }
  }
}

extension WorkspaceCommandTarget: Codable where RouteID: Codable {}

/// A searchable command palette and menu command entry.
public struct WorkspaceCommand<RouteID: Hashable & Sendable>:
  Equatable,
  Identifiable,
  Sendable
{
  public var disabledReason: String?
  public var id: WorkspaceCommandIdentifier<RouteID>
  public var isEnabled: Bool
  public var isHidden: Bool
  public var keywords: [String]
  public var sectionTitle: String?
  public var shortcut: WorkspaceKeyboardShortcut?
  public var source: WorkspaceCommandSource
  public var subtitle: String?
  public var systemImage: String
  public var target: WorkspaceCommandTarget<RouteID>
  public var title: String

  public init(
    id: WorkspaceCommandIdentifier<RouteID>,
    title: String,
    systemImage: String,
    subtitle: String? = nil,
    keywords: [String] = [],
    shortcut: WorkspaceKeyboardShortcut? = nil,
    sectionTitle: String? = nil,
    source: WorkspaceCommandSource,
    target: WorkspaceCommandTarget<RouteID>,
    isEnabled: Bool = true,
    disabledReason: String? = nil,
    isHidden: Bool = false
  ) {
    self.disabledReason = disabledReason
    self.id = id
    self.isEnabled = isEnabled
    self.isHidden = isHidden
    self.keywords = keywords
    self.sectionTitle = sectionTitle
    self.shortcut = shortcut
    self.source = source
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.target = target
    self.title = title
  }

  public static func appAction(
    id: WorkspaceCommandID,
    title: String,
    systemImage: String,
    subtitle: String? = nil,
    keywords: [String] = [],
    shortcut: WorkspaceKeyboardShortcut? = nil,
    sectionTitle: String? = nil,
    isEnabled: Bool = true,
    disabledReason: String? = nil,
    isHidden: Bool = false
  ) -> Self {
    Self(
      id: .appAction(id),
      title: title,
      systemImage: systemImage,
      subtitle: subtitle,
      keywords: keywords,
      shortcut: shortcut,
      sectionTitle: sectionTitle,
      source: .app,
      target: .appAction(id),
      isEnabled: isEnabled,
      disabledReason: disabledReason,
      isHidden: isHidden
    )
  }

  public static func primaryAction(
    id: WorkspaceCommandID,
    title: String,
    systemImage: String,
    subtitle: String? = nil,
    keywords: [String] = [],
    shortcut: WorkspaceKeyboardShortcut? = nil,
    sectionTitle: String? = nil,
    isEnabled: Bool = true,
    disabledReason: String? = nil,
    isHidden: Bool = false
  ) -> Self {
    Self(
      id: .primaryAction(id),
      title: title,
      systemImage: systemImage,
      subtitle: subtitle,
      keywords: keywords,
      shortcut: shortcut,
      sectionTitle: sectionTitle,
      source: .primaryAction,
      target: .primaryAction(id),
      isEnabled: isEnabled,
      disabledReason: disabledReason,
      isHidden: isHidden
    )
  }

  public static func system(
    id: WorkspaceCommandID,
    title: String,
    systemImage: String,
    subtitle: String? = nil,
    keywords: [String] = [],
    shortcut: WorkspaceKeyboardShortcut? = nil,
    sectionTitle: String? = nil,
    isEnabled: Bool = true,
    disabledReason: String? = nil,
    isHidden: Bool = false
  ) -> Self {
    Self(
      id: .system(id),
      title: title,
      systemImage: systemImage,
      subtitle: subtitle,
      keywords: keywords,
      shortcut: shortcut,
      sectionTitle: sectionTitle,
      source: .system,
      target: .system(id),
      isEnabled: isEnabled,
      disabledReason: disabledReason,
      isHidden: isHidden
    )
  }

  public static func toolbarAction(
    id: WorkspaceCommandID,
    title: String,
    systemImage: String,
    subtitle: String? = nil,
    keywords: [String] = [],
    shortcut: WorkspaceKeyboardShortcut? = nil,
    sectionTitle: String? = nil,
    isEnabled: Bool = true,
    disabledReason: String? = nil,
    isHidden: Bool = false
  ) -> Self {
    Self(
      id: .toolbarAction(id),
      title: title,
      systemImage: systemImage,
      subtitle: subtitle,
      keywords: keywords,
      shortcut: shortcut,
      sectionTitle: sectionTitle,
      source: .toolbar,
      target: .toolbarAction(id),
      isEnabled: isEnabled,
      disabledReason: disabledReason,
      isHidden: isHidden
    )
  }

  public var availability: WorkspaceAvailability {
    get {
      if isHidden { return .hidden }
      return isEnabled ? .available : .disabled(reason: disabledReason)
    }
    set {
      switch newValue {
      case .available:
        disabledReason = nil
        isEnabled = true
        isHidden = false
      case .disabled(let reason):
        disabledReason = reason
        isEnabled = false
        isHidden = false
      case .hidden:
        disabledReason = nil
        isEnabled = false
        isHidden = true
      }
    }
  }

  public var categoryTitle: String {
    sectionTitle ?? source.displayTitle
  }

  public var role: WorkspaceCommandRole {
    target.role
  }
}

extension WorkspaceCommand: Codable where RouteID: Codable {}

/// Why a command execution request was blocked before reaching app behavior.
public enum WorkspaceCommandExecutionDeniedReason: String, Codable, Equatable, Sendable {
  case automationNotAllowed
  case commandDenied
  case sourceDenied
}

/// A command execution request blocked by a command policy.
public struct WorkspaceCommandExecutionDenial<RouteID: Hashable & Sendable>:
  Equatable,
  Sendable
{
  public var commandID: WorkspaceCommandIdentifier<RouteID>
  public var invocation: WorkspaceCommandInvocation
  public var reason: WorkspaceCommandExecutionDeniedReason
  public var source: WorkspaceCommandSource

  public init(
    commandID: WorkspaceCommandIdentifier<RouteID>,
    invocation: WorkspaceCommandInvocation,
    reason: WorkspaceCommandExecutionDeniedReason,
    source: WorkspaceCommandSource
  ) {
    self.commandID = commandID
    self.invocation = invocation
    self.reason = reason
    self.source = source
  }
}

extension WorkspaceCommandExecutionDenial: Codable where RouteID: Codable {}

/// App-owned policy for blocking or allow-listing command execution.
public struct WorkspaceCommandExecutionPolicy<RouteID: Hashable & Sendable>:
  Equatable,
  Sendable
{
  public var automationAllowedCommandIDs: Set<WorkspaceCommandIdentifier<RouteID>>?
  public var deniedCommandIDs: Set<WorkspaceCommandIdentifier<RouteID>>
  public var deniedSources: Set<WorkspaceCommandSource>

  public init(
    deniedCommandIDs: Set<WorkspaceCommandIdentifier<RouteID>> = [],
    deniedSources: Set<WorkspaceCommandSource> = [],
    automationAllowedCommandIDs: Set<WorkspaceCommandIdentifier<RouteID>>? = nil
  ) {
    self.automationAllowedCommandIDs = automationAllowedCommandIDs
    self.deniedCommandIDs = deniedCommandIDs
    self.deniedSources = deniedSources
  }

  public static var allowAll: Self {
    Self()
  }

  public func denial(
    for command: WorkspaceCommand<RouteID>,
    invocation: WorkspaceCommandInvocation
  ) -> WorkspaceCommandExecutionDenial<RouteID>? {
    if deniedCommandIDs.contains(command.id) {
      return WorkspaceCommandExecutionDenial(
        commandID: command.id,
        invocation: invocation,
        reason: .commandDenied,
        source: command.source
      )
    }

    if deniedSources.contains(command.source) {
      return WorkspaceCommandExecutionDenial(
        commandID: command.id,
        invocation: invocation,
        reason: .sourceDenied,
        source: command.source
      )
    }

    if invocation == .automation,
       let automationAllowedCommandIDs,
       !automationAllowedCommandIDs.contains(command.id) {
      return WorkspaceCommandExecutionDenial(
        commandID: command.id,
        invocation: invocation,
        reason: .automationNotAllowed,
        source: command.source
      )
    }

    return nil
  }
}

extension WorkspaceCommandExecutionPolicy: Codable where RouteID: Codable {}
