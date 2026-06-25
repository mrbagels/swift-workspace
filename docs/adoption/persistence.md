# Persistence Adapter Guide

`WorkspacePersistence` is for small shared engine payloads, not app documents.

## UserDefaults

Use `WorkspaceUserDefaultsPersistence` for small restoration payloads:

```swift
let persistence = WorkspaceUserDefaultsPersistence<MyRoute>(
  key: "workspace.restoration"
)
try persistence.save(store.restorationState)
let restored = try persistence.load()
```

## File Storage

Use `WorkspaceFilePersistence` when the app wants an explicit JSON file:

```swift
let persistence = WorkspaceFilePersistence<MyRoute>(
  fileURL: applicationSupportURL.appendingPathComponent("workspace.json")
)
try persistence.save(store.restorationState)
```

The file store creates missing parent directories and writes atomically.

## CloudKit

`WorkspaceCloudKit` currently defines contracts: record names, zones, conflict
policy, restoration envelopes, route metadata envelopes, and an async adapter
protocol. It does not perform live CloudKit sync yet.

Apps should keep iCloud as the primary store for user-owned data and wire live
CloudKit operations in app-owned features.
