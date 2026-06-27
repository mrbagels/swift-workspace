import Foundation

/// Storage-agnostic workspace state shared across platform shells.
public struct WorkspaceRestoration<RouteID: Hashable & Sendable>: Equatable, Sendable {
  public var collapsedSectionIDs: Set<WorkspaceRouteSectionID>
  public var pinnedRouteIDs: [RouteID]
  public var recentCommandIDs: [WorkspaceCommandIdentifier<RouteID>]
  public var recentRouteIDs: [RouteID]
  public var selectedRouteID: RouteID

  public init(
    selectedRouteID: RouteID,
    collapsedSectionIDs: Set<WorkspaceRouteSectionID> = [],
    pinnedRouteIDs: [RouteID] = [],
    recentCommandIDs: [WorkspaceCommandIdentifier<RouteID>] = [],
    recentRouteIDs: [RouteID] = []
  ) {
    self.collapsedSectionIDs = collapsedSectionIDs
    self.pinnedRouteIDs = pinnedRouteIDs
    self.recentCommandIDs = recentCommandIDs
    self.recentRouteIDs = recentRouteIDs
    self.selectedRouteID = selectedRouteID
  }
}

extension WorkspaceRestoration: Codable where RouteID: Codable {
  private enum CodingKeys: String, CodingKey {
    case collapsedSectionIDs
    case pinnedRouteIDs
    case recentCommandIDs
    case recentRouteIDs
    case selectedRouteID
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      selectedRouteID: try container.decode(RouteID.self, forKey: .selectedRouteID),
      collapsedSectionIDs: try container.decodeIfPresent(
        Set<WorkspaceRouteSectionID>.self,
        forKey: .collapsedSectionIDs
      ) ?? [],
      pinnedRouteIDs: try container.decodeIfPresent([RouteID].self, forKey: .pinnedRouteIDs) ?? [],
      recentCommandIDs: try container.decodeIfPresent(
        [WorkspaceCommandIdentifier<RouteID>].self,
        forKey: .recentCommandIDs
      ) ?? [],
      recentRouteIDs: try container.decodeIfPresent([RouteID].self, forKey: .recentRouteIDs) ?? []
    )
  }
}
