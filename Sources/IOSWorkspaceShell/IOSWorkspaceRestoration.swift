import Foundation
import WorkspaceCore

/// Preferred column shown when restoring an iOS or iPadOS workspace shell.
public enum IOSWorkspaceColumnPreference:
  String,
  CaseIterable,
  Codable,
  Equatable,
  Hashable,
  Sendable
{
  case automatic
  case content
  case sidebar
}

/// iOS and iPadOS restoration payload composed around shared workspace state.
public struct IOSWorkspaceRestoration<RouteID: Hashable & Sendable>: Equatable, Sendable {
  public var columnPreference: IOSWorkspaceColumnPreference
  public var compactNavigationPath: [RouteID]
  public var workspace: WorkspaceRestoration<RouteID>

  public init(
    workspace: WorkspaceRestoration<RouteID>,
    columnPreference: IOSWorkspaceColumnPreference = .automatic,
    compactNavigationPath: [RouteID] = []
  ) {
    self.columnPreference = columnPreference
    self.compactNavigationPath = compactNavigationPath
    self.workspace = workspace
  }
}

extension IOSWorkspaceRestoration: Codable where RouteID: Codable {}
