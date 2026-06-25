import Foundation

/// Storage-agnostic workspace state shared across platform shells.
public struct WorkspaceRestoration<RouteID: Hashable & Sendable>: Equatable, Sendable {
  public var collapsedSectionIDs: Set<WorkspaceRouteSectionID>
  public var recentCommandIDs: [WorkspaceCommandIdentifier<RouteID>]
  public var selectedRouteID: RouteID

  public init(
    selectedRouteID: RouteID,
    collapsedSectionIDs: Set<WorkspaceRouteSectionID> = [],
    recentCommandIDs: [WorkspaceCommandIdentifier<RouteID>] = []
  ) {
    self.collapsedSectionIDs = collapsedSectionIDs
    self.recentCommandIDs = recentCommandIDs
    self.selectedRouteID = selectedRouteID
  }
}

extension WorkspaceRestoration: Codable where RouteID: Codable {}
