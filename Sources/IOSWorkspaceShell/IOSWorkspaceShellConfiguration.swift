import Foundation

/// High-level iOS and iPadOS navigation style preference.
public enum IOSWorkspaceNavigationStyle: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
  case automatic
  case split
  case stack

  public func usesStackNavigation(isCompactWidth: Bool) -> Bool {
    switch self {
    case .automatic:
      isCompactWidth
    case .split:
      false
    case .stack:
      true
    }
  }
}

/// iOS and iPadOS renderer configuration.
public struct IOSWorkspaceShellConfiguration: Codable, Equatable, Sendable {
  public var commandSearchPlaceholder: String
  public var navigationStyle: IOSWorkspaceNavigationStyle
  public var prefersBadges: Bool
  public var title: String

  public init(
    title: String = "Workspace",
    navigationStyle: IOSWorkspaceNavigationStyle = .automatic,
    commandSearchPlaceholder: String = "Search commands and routes",
    prefersBadges: Bool = true
  ) {
    self.commandSearchPlaceholder = commandSearchPlaceholder
    self.navigationStyle = navigationStyle
    self.prefersBadges = prefersBadges
    self.title = title
  }

  public static let `default` = Self()

  public func usesStackNavigation(isCompactWidth: Bool) -> Bool {
    navigationStyle.usesStackNavigation(isCompactWidth: isCompactWidth)
  }
}
