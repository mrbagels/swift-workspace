# Server-Side Companion

Last updated: 2026-06-25

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

## Future Package

A future server client should be an optional product:

```text
WorkspaceServerClient
  OpenAPI or typed URLSession client
  request and response models
  retry policy helpers
  auth token injection hooks
  no dependency from WorkspaceCore
```

## Initial API Areas

- `GET /v1/entitlements`
- `GET /v1/feature-flags`
- `GET /v1/templates`
- `POST /v1/jobs/import`
- `POST /v1/jobs/export`
- `POST /v1/jobs/ai`
- `GET /v1/jobs/{id}`
- `POST /v1/diagnostics`
- `POST /v1/webhooks/relay`

These are placeholders for product planning. They should not be implemented
until an app workflow proves the need.
