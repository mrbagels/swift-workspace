import CloudKit
import Foundation
import WorkspaceCore

/// Declares which CloudKit database should hold a workspace adapter record.
public enum WorkspaceCloudKitDatabaseScope:
  String,
  CaseIterable,
  Codable,
  Equatable,
  Sendable
{
  case `private`
  case shared
}

/// Logical CloudKit payload groups supported by the workspace adapter contracts.
public enum WorkspaceCloudKitSyncScope:
  String,
  CaseIterable,
  Codable,
  Equatable,
  Sendable
{
  case restoration
  case routeMetadata
  case scenes
}

/// App-level conflict policy for CloudKit payloads.
public enum WorkspaceCloudKitConflictPolicy:
  String,
  CaseIterable,
  Codable,
  Equatable,
  Sendable
{
  case appDefined
  case newestModifiedAt
  case preferLocal
  case preferRemote

  public func resolution(
    localModifiedAt: Date,
    remoteModifiedAt: Date
  ) -> WorkspaceCloudKitConflictResolution {
    switch self {
    case .appDefined:
      .unresolved
    case .newestModifiedAt:
      localModifiedAt >= remoteModifiedAt ? .local : .remote
    case .preferLocal:
      .local
    case .preferRemote:
      .remote
    }
  }
}

/// Which side of a CloudKit conflict should win.
public enum WorkspaceCloudKitConflictResolution:
  String,
  CaseIterable,
  Codable,
  Equatable,
  Sendable
{
  case local
  case remote
  case unresolved
}

/// Stable record name wrapper for CloudKit adapter payloads.
public struct WorkspaceCloudKitRecordName:
  Codable,
  Equatable,
  ExpressibleByStringLiteral,
  Hashable,
  Sendable
{
  public var rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }

  public static func restoration(_ id: String = "default") -> Self {
    Self("workspace.restoration.\(id)")
  }

  public static func routeMetadata(_ routeID: String) -> Self {
    Self("workspace.route-metadata.\(routeID)")
  }

  public static func scene(_ id: String) -> Self {
    Self("workspace.scene.\(id)")
  }
}

/// CloudKit custom zone configuration used by future live adapters.
public struct WorkspaceCloudKitZoneConfiguration: Codable, Equatable, Sendable {
  public var name: String

  public init(name: String = "Workspace") {
    self.name = name
  }

  public static let `default` = Self()
}

/// Configuration for CloudKit-backed workspace adapter implementations.
public struct WorkspaceCloudKitConfiguration: Codable, Equatable, Sendable {
  public var containerIdentifier: String?
  public var conflictPolicy: WorkspaceCloudKitConflictPolicy
  public var databaseScope: WorkspaceCloudKitDatabaseScope
  public var restorationRecordType: String
  public var routeMetadataRecordType: String
  public var zone: WorkspaceCloudKitZoneConfiguration

  public init(
    containerIdentifier: String? = nil,
    databaseScope: WorkspaceCloudKitDatabaseScope = .private,
    zone: WorkspaceCloudKitZoneConfiguration = .default,
    restorationRecordType: String = "WorkspaceRestoration",
    routeMetadataRecordType: String = "WorkspaceRouteMetadata",
    conflictPolicy: WorkspaceCloudKitConflictPolicy = .newestModifiedAt
  ) {
    self.containerIdentifier = containerIdentifier
    self.conflictPolicy = conflictPolicy
    self.databaseScope = databaseScope
    self.restorationRecordType = restorationRecordType
    self.routeMetadataRecordType = routeMetadataRecordType
    self.zone = zone
  }
}

/// Names used by a future CloudKit adapter when encoding engine-owned state.
public enum WorkspaceCloudKitField {
  public static let availabilityState = "availabilityState"
  public static let badge = "badge"
  public static let data = "data"
  public static let deviceIdentifier = "deviceIdentifier"
  public static let disabledReason = "disabledReason"
  public static let modifiedAt = "modifiedAt"
  public static let recordName = "recordName"
  public static let revision = "revision"
  public static let routeID = "routeID"
  public static let scope = "scope"
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

extension WorkspaceCloudRouteMetadata: Codable where RouteID: Codable {}

/// CloudKit payload wrapper for shared workspace restoration.
public struct WorkspaceCloudKitRestorationEnvelope<RouteID: Codable & Hashable & Sendable>:
  Codable,
  Equatable,
  Sendable
{
  public var deviceIdentifier: String
  public var modifiedAt: Date
  public var recordName: WorkspaceCloudKitRecordName
  public var restoration: WorkspaceRestoration<RouteID>
  public var revision: Int
  public var scope: WorkspaceCloudKitSyncScope

  public init(
    restoration: WorkspaceRestoration<RouteID>,
    recordName: WorkspaceCloudKitRecordName = .restoration(),
    revision: Int = 0,
    modifiedAt: Date = Date(),
    deviceIdentifier: String,
    scope: WorkspaceCloudKitSyncScope = .restoration
  ) {
    self.deviceIdentifier = deviceIdentifier
    self.modifiedAt = modifiedAt
    self.recordName = recordName
    self.restoration = restoration
    self.revision = max(0, revision)
    self.scope = scope
  }
}

/// CloudKit payload wrapper for route metadata deltas.
public struct WorkspaceCloudKitRouteMetadataEnvelope<RouteID: Codable & Hashable & Sendable>:
  Codable,
  Equatable,
  Sendable
{
  public var deviceIdentifier: String
  public var metadata: WorkspaceCloudRouteMetadata<RouteID>
  public var modifiedAt: Date
  public var recordName: WorkspaceCloudKitRecordName
  public var revision: Int
  public var scope: WorkspaceCloudKitSyncScope

  public init(
    metadata: WorkspaceCloudRouteMetadata<RouteID>,
    recordName: WorkspaceCloudKitRecordName,
    revision: Int = 0,
    modifiedAt: Date = Date(),
    deviceIdentifier: String,
    scope: WorkspaceCloudKitSyncScope = .routeMetadata
  ) {
    self.deviceIdentifier = deviceIdentifier
    self.metadata = metadata
    self.modifiedAt = modifiedAt
    self.recordName = recordName
    self.revision = max(0, revision)
    self.scope = scope
  }
}

/// Async contract that app-owned CloudKit clients can implement.
public protocol WorkspaceCloudKitSyncAdapter {
  associatedtype RouteID: Codable & Hashable & Sendable

  func loadRestoration(
    recordName: WorkspaceCloudKitRecordName
  ) async throws -> WorkspaceCloudKitRestorationEnvelope<RouteID>?

  func loadRouteMetadata() async throws -> [WorkspaceCloudKitRouteMetadataEnvelope<RouteID>]

  func removeRestoration(
    recordName: WorkspaceCloudKitRecordName
  ) async throws

  func saveRestoration(
    _ envelope: WorkspaceCloudKitRestorationEnvelope<RouteID>
  ) async throws

  func saveRouteMetadata(
    _ envelopes: [WorkspaceCloudKitRouteMetadataEnvelope<RouteID>]
  ) async throws
}
