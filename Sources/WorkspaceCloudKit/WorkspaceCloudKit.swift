import CloudKit
import Foundation
import WorkspaceCore

/// Declares which CloudKit database should hold a workspace adapter record.
public enum WorkspaceCloudKitDatabaseScope: String, Codable, Equatable, Sendable {
  case `private`
  case shared
}

/// Configuration for CloudKit-backed workspace adapter implementations.
public struct WorkspaceCloudKitConfiguration: Equatable, Sendable {
  public var containerIdentifier: String?
  public var databaseScope: WorkspaceCloudKitDatabaseScope
  public var restorationRecordType: String
  public var routeMetadataRecordType: String

  public init(
    containerIdentifier: String? = nil,
    databaseScope: WorkspaceCloudKitDatabaseScope = .private,
    restorationRecordType: String = "WorkspaceRestoration",
    routeMetadataRecordType: String = "WorkspaceRouteMetadata"
  ) {
    self.containerIdentifier = containerIdentifier
    self.databaseScope = databaseScope
    self.restorationRecordType = restorationRecordType
    self.routeMetadataRecordType = routeMetadataRecordType
  }
}

/// Names used by a future CloudKit adapter when encoding engine-owned state.
public enum WorkspaceCloudKitField {
  public static let availabilityState = "availabilityState"
  public static let badge = "badge"
  public static let data = "data"
  public static let disabledReason = "disabledReason"
  public static let routeID = "routeID"
  public static let updatedAt = "updatedAt"
}

/// A small value object for route metadata that can be mapped to CloudKit.
public struct WorkspaceCloudRouteMetadata<RouteID: Hashable & Sendable>:
  Equatable,
  Sendable
{
  public var availability: WorkspaceAvailability
  public var badge: Int?
  public var routeID: RouteID
  public var updatedAt: Date

  public init(
    routeID: RouteID,
    badge: Int?,
    availability: WorkspaceAvailability,
    updatedAt: Date
  ) {
    self.availability = availability
    self.badge = badge
    self.routeID = routeID
    self.updatedAt = updatedAt
  }
}
