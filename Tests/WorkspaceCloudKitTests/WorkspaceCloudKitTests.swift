import Foundation
import Testing
import WorkspaceCloudKit
import WorkspaceCore

private enum TestRoute: String, Codable, Hashable, Sendable {
  case inbox
  case settings
}

@Test
func cloudKitRestorationEnvelopeRoundTrips() throws {
  let modifiedAt = try #require(ISO8601DateFormatter().date(from: "2026-06-25T12:00:00Z"))
  let envelope = WorkspaceCloudKitRestorationEnvelope(
    restoration: WorkspaceRestoration(
      selectedRouteID: TestRoute.settings,
      collapsedSectionIDs: ["system"],
      recentCommandIDs: [.route(.settings)]
    ),
    recordName: .restoration("main"),
    revision: 3,
    modifiedAt: modifiedAt,
    deviceIdentifier: "device-a"
  )

  let data = try JSONEncoder().encode(envelope)
  let decoded = try JSONDecoder().decode(
    WorkspaceCloudKitRestorationEnvelope<TestRoute>.self,
    from: data
  )

  #expect(decoded == envelope)
  #expect(decoded.recordName.rawValue == "workspace.restoration.main")
  #expect(decoded.scope == .restoration)
}

@Test
func cloudKitRouteMetadataEnvelopeRoundTrips() throws {
  let modifiedAt = try #require(ISO8601DateFormatter().date(from: "2026-06-25T12:30:00Z"))
  let metadata = WorkspaceCloudRouteMetadata(
    routeID: TestRoute.inbox,
    badge: 8,
    availability: .disabled(reason: "Syncing"),
    updatedAt: modifiedAt
  )
  let envelope = WorkspaceCloudKitRouteMetadataEnvelope(
    metadata: metadata,
    recordName: .routeMetadata(TestRoute.inbox.rawValue),
    revision: 2,
    modifiedAt: modifiedAt,
    deviceIdentifier: "device-b"
  )

  let data = try JSONEncoder().encode(envelope)
  let decoded = try JSONDecoder().decode(
    WorkspaceCloudKitRouteMetadataEnvelope<TestRoute>.self,
    from: data
  )

  #expect(decoded == envelope)
  #expect(decoded.recordName.rawValue == "workspace.route-metadata.inbox")
  #expect(decoded.scope == .routeMetadata)
}

@Test
func cloudKitConflictPolicySelectsExpectedVersion() throws {
  let localDate = try #require(ISO8601DateFormatter().date(from: "2026-06-25T12:00:00Z"))
  let remoteDate = try #require(ISO8601DateFormatter().date(from: "2026-06-25T13:00:00Z"))

  #expect(
    WorkspaceCloudKitConflictPolicy.newestModifiedAt.resolution(
      localModifiedAt: localDate,
      remoteModifiedAt: remoteDate
    ) == .remote
  )
  #expect(
    WorkspaceCloudKitConflictPolicy.preferLocal.resolution(
      localModifiedAt: localDate,
      remoteModifiedAt: remoteDate
    ) == .local
  )
  #expect(
    WorkspaceCloudKitConflictPolicy.appDefined.resolution(
      localModifiedAt: localDate,
      remoteModifiedAt: remoteDate
    ) == .unresolved
  )
}
