import Foundation

/// Visibility and enabled-state metadata shared by routes and commands.
public enum WorkspaceAvailability: Codable, Equatable, Sendable {
  case available
  case disabled(reason: String?)
  case hidden

  public var disabledReason: String? {
    switch self {
    case .available, .hidden:
      nil
    case .disabled(let reason):
      reason
    }
  }

  public var isEnabled: Bool {
    self == .available
  }

  public var isVisible: Bool {
    self != .hidden
  }
}
