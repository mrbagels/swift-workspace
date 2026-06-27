# Server Client Guide

Use `WorkspaceServerClient` only when a consuming app has a real companion
server workflow. The package does not require a server for core navigation,
shells, restoration, iCloud, or local-first behavior.

`WorkspaceServerClient` uses [Comet](https://github.com/mrbagels/comet) for
typed HTTP requests and TCA-friendly request effects.

## Install

```swift
.product(name: "WorkspaceServerClient", package: "swift-workspace")
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
