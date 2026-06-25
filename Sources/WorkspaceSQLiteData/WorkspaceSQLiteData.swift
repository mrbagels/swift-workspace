import Foundation
import SQLiteData
import WorkspaceCore

/// SQLiteData record for encoded workspace restoration state.
@Table("workspaceRestorationRecords")
public struct WorkspaceRestorationRecord: Codable, Equatable, Identifiable, Sendable {
  public let id: String
  public var data: Data
  public var updatedAt: Date

  public init(
    id: String,
    data: Data,
    updatedAt: Date
  ) {
    self.id = id
    self.data = data
    self.updatedAt = updatedAt
  }
}

/// SQLiteData record for live route metadata that can be merged into registries.
@Table("workspaceRouteMetadataRecords")
public struct WorkspaceRouteMetadataRecord: Codable, Equatable, Identifiable, Sendable {
  public let id: String
  public var availabilityState: String
  public var badge: Int?
  public var disabledReason: String?
  public var updatedAt: Date

  public init(
    id: String,
    badge: Int? = nil,
    availability: WorkspaceAvailability = .available,
    updatedAt: Date
  ) {
    self.id = id
    self.availabilityState = WorkspaceRouteAvailabilityState(availability).rawValue
    self.badge = badge
    self.disabledReason = availability.disabledReason
    self.updatedAt = updatedAt
  }

  public var availability: WorkspaceAvailability {
    get {
      switch WorkspaceRouteAvailabilityState(rawValue: availabilityState) {
      case .available, .none:
        .available
      case .disabled:
        .disabled(reason: disabledReason)
      case .hidden:
        .hidden
      }
    }
    set {
      availabilityState = WorkspaceRouteAvailabilityState(newValue).rawValue
      disabledReason = newValue.disabledReason
    }
  }
}

/// Persisted availability states for route metadata records.
public enum WorkspaceRouteAvailabilityState: String, Codable, CaseIterable, Equatable, Sendable {
  case available
  case disabled
  case hidden

  public init(_ availability: WorkspaceAvailability) {
    switch availability {
    case .available:
      self = .available
    case .disabled:
      self = .disabled
    case .hidden:
      self = .hidden
    }
  }
}

/// SQLiteData migration helpers for swift-workspace adapter tables.
public enum WorkspaceSQLiteDataMigrations {
  public static let createWorkspaceRestorationRecordsSQL = """
    CREATE TABLE "workspaceRestorationRecords" (
      "id" TEXT PRIMARY KEY NOT NULL,
      "data" BLOB NOT NULL,
      "updatedAt" TEXT NOT NULL
    ) STRICT
    """

  public static let createRouteMetadataRecordsSQL = """
    CREATE TABLE "workspaceRouteMetadataRecords" (
      "id" TEXT PRIMARY KEY NOT NULL,
      "availabilityState" TEXT NOT NULL,
      "badge" INTEGER,
      "disabledReason" TEXT,
      "updatedAt" TEXT NOT NULL
    ) STRICT
    """

  public static func createWorkspaceRestorationRecords(
    in db: Database
  ) throws {
    try #sql(
      """
      CREATE TABLE "workspaceRestorationRecords" (
        "id" TEXT PRIMARY KEY NOT NULL,
        "data" BLOB NOT NULL,
        "updatedAt" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)
  }

  public static func createRouteMetadataRecords(
    in db: Database
  ) throws {
    try #sql(
      """
      CREATE TABLE "workspaceRouteMetadataRecords" (
        "id" TEXT PRIMARY KEY NOT NULL,
        "availabilityState" TEXT NOT NULL,
        "badge" INTEGER,
        "disabledReason" TEXT,
        "updatedAt" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)
  }
}

/// Encodes and decodes workspace restoration state for SQLiteData storage.
public struct WorkspaceSQLiteDataCodec<RouteID: Codable & Hashable & Sendable> {
  public var decoder: JSONDecoder
  public var encoder: JSONEncoder

  public init(
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.decoder = decoder
    self.encoder = encoder
  }

  public func record(
    id: String = "default",
    restorationState: WorkspaceRestoration<RouteID>,
    updatedAt: Date = Date()
  ) throws -> WorkspaceRestorationRecord {
    try WorkspaceRestorationRecord(
      id: id,
      data: encoder.encode(restorationState),
      updatedAt: updatedAt
    )
  }

  public func restorationState(
    from record: WorkspaceRestorationRecord
  ) throws -> WorkspaceRestoration<RouteID> {
    try decoder.decode(WorkspaceRestoration<RouteID>.self, from: record.data)
  }
}

/// Typed route metadata decoded from SQLiteData records.
public struct WorkspaceRouteMetadata<RouteID: Hashable & Sendable>: Equatable, Sendable {
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

/// Converts between typed route metadata and SQLiteData records.
public struct WorkspaceSQLiteDataRouteMetadataCodec<RouteID: Hashable & Sendable>: Sendable {
  public var decodeRouteID: @Sendable (String) -> RouteID?
  public var encodeRouteID: @Sendable (RouteID) -> String

  public init(
    encodeRouteID: @escaping @Sendable (RouteID) -> String,
    decodeRouteID: @escaping @Sendable (String) -> RouteID?
  ) {
    self.decodeRouteID = decodeRouteID
    self.encodeRouteID = encodeRouteID
  }

  public func record(
    routeID: RouteID,
    badge: Int? = nil,
    availability: WorkspaceAvailability = .available,
    updatedAt: Date = Date()
  ) -> WorkspaceRouteMetadataRecord {
    WorkspaceRouteMetadataRecord(
      id: encodeRouteID(routeID),
      badge: badge,
      availability: availability,
      updatedAt: updatedAt
    )
  }

  public func metadata(
    from record: WorkspaceRouteMetadataRecord
  ) -> WorkspaceRouteMetadata<RouteID>? {
    guard let routeID = decodeRouteID(record.id)
    else { return nil }
    return WorkspaceRouteMetadata(
      routeID: routeID,
      badge: record.badge,
      availability: record.availability,
      updatedAt: record.updatedAt
    )
  }

  public func metadata(
    from records: some Sequence<WorkspaceRouteMetadataRecord>
  ) -> [WorkspaceRouteMetadata<RouteID>] {
    records.compactMap(metadata(from:))
  }

  public func apply(
    records: some Sequence<WorkspaceRouteMetadataRecord>,
    to sections: [WorkspaceRouteSection<RouteID>]
  ) -> [WorkspaceRouteSection<RouteID>] {
    apply(metadata: metadata(from: records), to: sections)
  }

  public func apply(
    metadata: some Sequence<WorkspaceRouteMetadata<RouteID>>,
    to sections: [WorkspaceRouteSection<RouteID>]
  ) -> [WorkspaceRouteSection<RouteID>] {
    var metadataByRoute: [RouteID: WorkspaceRouteMetadata<RouteID>] = [:]
    for item in metadata {
      guard let existing = metadataByRoute[item.routeID] else {
        metadataByRoute[item.routeID] = item
        continue
      }
      if item.updatedAt >= existing.updatedAt {
        metadataByRoute[item.routeID] = item
      }
    }

    return sections.map { section in
      section.withRoutes(
        section.routes.map { route in
          guard let metadata = metadataByRoute[route.id]
          else { return route }
          var route = route
          route.availability = metadata.availability
          route.badge = metadata.badge
          return route
        }
      )
    }
  }
}
