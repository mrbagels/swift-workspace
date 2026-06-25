import Foundation

/// Stable identifier for app-owned commands and engine-level command surfaces.
public struct WorkspaceCommandID:
  Codable,
  CustomStringConvertible,
  Equatable,
  ExpressibleByStringLiteral,
  Hashable,
  RawRepresentable,
  Sendable
{
  public var rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable identifier for route sections in a workspace registry.
public typealias WorkspaceRouteSectionID = String

/// Stable identifier for singleton and utility scenes.
public struct WorkspaceSceneID:
  Codable,
  CustomStringConvertible,
  Equatable,
  ExpressibleByStringLiteral,
  Hashable,
  RawRepresentable,
  Sendable
{
  public var rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}
