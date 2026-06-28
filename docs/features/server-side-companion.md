# Server-Side Companion

Last updated: 2026-06-28

## Principle

iCloud and local storage remain primary for user-owned data. The server is a
companion service, not the source of truth for documents, workspace state, or
local-first preferences.

## Good Server Responsibilities

- Account identity and team membership.
- Licensing and entitlement checks.
- Feature flags and remote configuration.
- Template and starter catalog delivery.
- AI jobs that are too expensive or private to run locally.
- Import, export, OCR, transcription, and enrichment jobs.
- Webhook relay for third-party integrations.
- Notification fanout.
- Diagnostics upload.
- Support bundle exchange.
- Integration credential brokering.

## Bad Server Responsibilities

- Owning the user's canonical documents.
- Replacing iCloud sync.
- Owning route restoration.
- Owning local preferences.
- Hiding conflict resolution inside a remote API.
- Making the engine unusable offline.

## Client Boundary

The engine may model commands and route metadata that cause app-owned work.
The app feature decides whether that work is local, CloudKit-backed, or server
backed.

Server calls should live in app features or optional client products, not inside
`WorkspaceCore` or `WorkspaceTCA`.

## Optional Package

`WorkspaceServerClient` is now an optional product backed by Comet:

```text
WorkspaceServerClient
  typed Comet requests
  request metadata, retry, cache policy, and diagnostics snapshots
  request and response models
  retry policy helpers
  auth token injection hooks
  no dependency from WorkspaceCore
```

Test and fixture workflows can add `WorkspaceServerTesting`, which layers
CometTesting recording, replay, strict contracts, and JSON reports on top of the
same typed client. Production app targets should not import it.

The product is suitable for apps that already need companion capabilities. It is
not required by the core engine, TCA reducer, bundled renderers, persistence, or
iCloud contracts.

## Initial API Areas

- `GET /v1/entitlements`
- `GET /v1/templates`
- `POST /v1/jobs`
- `GET /v1/jobs/{id}`
- `POST /v1/diagnostics`

Feature flags, webhook relay, integration credentials, and support bundle
exchange remain future contract areas.

## Implementation Gate

No live server workflow should be added to an app until the app identifies:

- the first concrete workflow,
- the authentication model,
- the entitlement source of truth,
- the request and response payloads,
- offline behavior,
- retry and cancellation behavior,
- privacy and retention requirements.

Until those decisions exist, use documentation, command delegates, and app-owned
effects. `WorkspaceCore`, `WorkspaceTCA`, and platform shells must continue to
work without a companion server.
