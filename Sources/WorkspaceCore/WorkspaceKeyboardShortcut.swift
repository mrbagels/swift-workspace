import Foundation

/// Keyboard modifier metadata used for display and platform command mapping.
public struct WorkspaceKeyboardModifiers:
  Codable,
  Equatable,
  Hashable,
  OptionSet,
  Sendable
{
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let command = Self(rawValue: 1 << 0)
  public static let control = Self(rawValue: 1 << 1)
  public static let option = Self(rawValue: 1 << 2)
  public static let shift = Self(rawValue: 1 << 3)

  public var displayPrefix: String {
    var symbols: [String] = []
    if contains(.command) { symbols.append("⌘") }
    if contains(.shift) { symbols.append("⇧") }
    if contains(.option) { symbols.append("⌥") }
    if contains(.control) { symbols.append("⌃") }
    return symbols.joined()
  }
}

/// A platform-neutral shortcut that renderers can map to native commands.
public struct WorkspaceKeyboardShortcut: Codable, Equatable, Hashable, Sendable {
  public var displayTitle: String?
  public var key: String
  public var modifiers: WorkspaceKeyboardModifiers

  public init(
    key: String,
    modifiers: WorkspaceKeyboardModifiers = .command,
    displayTitle: String? = nil
  ) {
    self.displayTitle = displayTitle
    self.key = key
    self.modifiers = modifiers
  }

  public static let commandPalette = Self(key: "k")

  public static func command(_ key: String) -> Self {
    Self(key: key, modifiers: .command)
  }

  public var displayLabel: String {
    displayTitle ?? "\(modifiers.displayPrefix)\(key.uppercased())"
  }
}
