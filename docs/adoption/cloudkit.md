# CloudKit Adoption Guide

`WorkspaceCloudKit` defines iCloud adapter contracts for shared engine payloads.
It does not perform live CloudKit sync yet. Apps own CloudKit containers,
authentication state, subscriptions, conflict resolution, retries, and effects.

## Storage Boundary

iCloud remains primary for user-owned data. The workspace package can help encode
engine payloads, but it must not become the canonical store for app documents.

Good workspace CloudKit payloads:

- selected route restoration,
- collapsed route sections,
- recent command IDs,
- route metadata envelopes,
- lightweight scene values,
- app-visible sync metadata.

App-owned payloads:

- documents,
- project data,
- user-generated content,
- workflow state,
- account data,
- integration credentials.

## Contracts

Use `WorkspaceCloudKitConfiguration` to describe the CloudKit surface the app
chooses:

```swift
let configuration = WorkspaceCloudKitConfiguration(
  containerIdentifier: "iCloud.com.example.workspace",
  database: .private,
  syncScope: .userPrivate,
  zone: .workspaceDefault
)
```

Use record-name helpers for stable names:

```swift
let restorationName = WorkspaceCloudKitRecordName.restoration("main")
let routeMetadataName = WorkspaceCloudKitRecordName.routeMetadata("inbox")
```

Use envelopes to encode shared payloads:

```swift
let envelope = WorkspaceCloudKitRestorationEnvelope(
  restoration: restoration,
  schemaVersion: 1,
  modifiedAt: Date()
)
```

## Live Adapter Shape

Apps that implement live CloudKit sync should conform an app-owned service to
`WorkspaceCloudKitSyncAdapter`. The adapter protocol is async and leaves all
CloudKit details outside the engine.

```swift
struct AppWorkspaceCloudKitSync: WorkspaceCloudKitSyncAdapter {
  func loadRestoration<RouteID>(
    for recordName: WorkspaceCloudKitRecordName,
    as routeIDType: RouteID.Type
  ) async throws -> WorkspaceCloudKitRestorationEnvelope<RouteID>?
  where RouteID: Codable & Hashable & Sendable {
    // App-owned CloudKit fetch and decoding.
  }

  func saveRestoration<RouteID>(
    _ envelope: WorkspaceCloudKitRestorationEnvelope<RouteID>,
    recordName: WorkspaceCloudKitRecordName,
    conflictPolicy: WorkspaceCloudKitConflictPolicy
  ) async throws where RouteID: Codable & Hashable & Sendable {
    // App-owned CloudKit write and conflict handling.
  }
}
```

## Conflict Policy

Choose a policy per payload, not globally:

- `.clientWins` for local preference changes the user just made.
- `.serverWins` for server-generated metadata where local state is stale.
- `.merge` when route metadata can be field-merged safely.
- `.manual` when the app must present or log a conflict.

Do not hide document conflict resolution inside workspace restoration. Documents
need app-specific merge behavior.

## Recommended Flow

1. Load app documents from the app's iCloud model.
2. Load workspace restoration as a small companion payload.
3. Initialize `WorkspaceFeature.State` with restored shared state.
4. Let the app feature observe reducer state changes.
5. Debounce and save restoration through the app-owned CloudKit adapter.
6. Apply route metadata patches from CloudKit only after validating route IDs
   against the current registry.

## Verification

Current package tests cover envelope encoding, record names, conflict policy
values, and adapter contracts:

```sh
swift test --filter WorkspaceCloudKit
```

Live CloudKit tests belong in consuming apps because they depend on real
containers, accounts, entitlements, and app-specific conflict behavior.
