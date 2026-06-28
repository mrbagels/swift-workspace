# Server Client Guide

Use `WorkspaceServerClient` only when a consuming app has a real companion
server workflow. The package does not require a server for core navigation,
shells, restoration, iCloud, or local-first behavior.

`WorkspaceServerClient` uses [Comet](https://github.com/mrbagels/comet) for
typed HTTP requests, request metadata, activity streams, traces, cache policy
hints, and TCA-friendly request effects.

## Install

```swift
.product(name: "WorkspaceServerClient", package: "swift-workspace")
```

For fixture and contract workflows in test targets, also add:

```swift
.product(name: "WorkspaceServerTesting", package: "swift-workspace")
```

## Create A Client

```swift
import WorkspaceServerClient

let client = WorkspaceServerClient.live(
  baseURL: URL(string: "https://api.example.com")!,
  bearerToken: {
    await tokenStore.currentAccessToken
  }
)
```

The live client uses Comet `0.4.1` or newer. Workspace requests carry stable
operation IDs, `workspace-server` tags, `/v1` API versioning, conservative retry
policy, deduplication keys for read requests, and stale-while-revalidate cache
policy for template catalogs.

## Supported Contract Areas

The first client is intentionally thin:

- `health()`
- `entitlements(userID:)`
- `templates()`
- `submitJob(_:)`
- `jobStatus(id:)`
- `uploadDiagnostics(_:)`

These are companion capabilities. They are not canonical storage for documents,
workspace restoration, or user-owned data.

## Diagnostics

`WorkspaceServerClient` exposes Comet activity and trace streams through
`client.activity` and `client.traces`. Convert those events into uploadable
workspace snapshots when a support or proof workflow needs a single diagnostics
payload:

```swift
for await event in client.activity {
  let snapshot = WorkspaceServerDiagnosticEvent(event: event)
  await diagnosticsBuffer.append(snapshot)
}
```

Completed traces can also contribute request and cache entries:

```swift
for await trace in client.traces {
  let requestEvent = WorkspaceServerDiagnosticEvent(trace: trace)
  let cacheEvents = WorkspaceServerDiagnosticEvent.cacheEvents(for: trace)
  await diagnosticsBuffer.append(contentsOf: [requestEvent] + cacheEvents)
}
```

Then include those snapshots with normal registry diagnostics:

```swift
try await client.uploadDiagnostics(
  WorkspaceDiagnosticsUpload(
    diagnostics: registry.validate().diagnostics,
    serverEvents: await diagnosticsBuffer.snapshot()
  )
)
```

## Record, Replay, Contract

Use `WorkspaceServerTesting` from tests or local proof tools:

```swift
import WorkspaceServerTesting

let session = WorkspaceServerContractWorkflow.recordingSession(
  baseURL: URL(string: "https://api.example.com")!,
  baseTransport: URLSessionTransport()
)

_ = try await session.client.templates()
try await session.writeCassette(
  to: URL(fileURLWithPath: "Tests/Fixtures/templates.json")
)
```

After reviewing and approving the cassette, replay it deterministically:

```swift
let client = try WorkspaceServerContractWorkflow.replayClient(
  baseURL: URL(string: "https://api.example.com")!,
  cassetteURL: URL(fileURLWithPath: "Tests/Fixtures/templates.json")
)

_ = try await client.templates()
```

Promote the same cassette into a strict contract when request shape drift should
fail the test:

```swift
let contract = try WorkspaceServerContractWorkflow.contractSession(
  baseURL: URL(string: "https://api.example.com")!,
  cassetteURL: URL(fileURLWithPath: "Tests/Fixtures/templates.json")
)

_ = try await contract.client.templates()
try await contract.verifyComplete()
try await contract.writeReport(
  to: URL(fileURLWithPath: "TestResults/workspace-server-contract.json")
)
```

## OpenAPI Generation

Comet 0.4.1 and newer include the `CometOpenAPIPlugin` command plugin. Use it for
app-specific generated clients or to validate a companion API contract before
hand-curating workspace-facing models:

```sh
swift package --allow-writing-to-package-directory comet-openapi-generate \
  --input path/to/openapi.yaml \
  --output Sources/AppServerClient/GeneratedWorkspaceAPI.swift
```

Keep generated files in an app-owned target unless the generated type names and
payload shapes match the public `WorkspaceServerClient` API you want to expose.

## TCA Usage

```swift
return .workspaceServerRequest(
  WorkspaceServerRequests.Entitlements(userID: userID),
  using: client
) { result in
  .entitlementsResponse(result)
}
```

Apps own authentication, retries beyond Comet defaults, offline behavior,
privacy, retention, and user-facing error handling.

## Storage Boundary

Keep iCloud primary for user-owned data. Use the server for things iCloud should
not own:

- entitlements,
- template catalogs,
- long-running jobs,
- diagnostics,
- integrations,
- support workflows.
