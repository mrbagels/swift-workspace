# ``WorkspaceServerClient``

Optional Comet-backed client for thin workspace companion services.

## Overview

`WorkspaceServerClient` is an optional product for apps that need companion
server capabilities such as entitlements, templates, background jobs, and
diagnostics upload.

The server client is not primary storage. User-owned documents, workspace
restoration, and local-first preferences should remain local or iCloud-primary.

Requests carry stable Comet operation metadata, workspace tags, `/v1` versioning,
deduplication keys for reads, conservative retry policy, and template cache
policy hints. The client also exposes Comet activity and trace streams so apps
can add HTTP, trace, and cache snapshots to workspace diagnostics uploads.

Use this module for:

- health checks,
- entitlement checks,
- template catalogs,
- job submission and status,
- diagnostics upload,
- server diagnostic event snapshots,
- TCA request effects through Comet.

## Topics

### Client

- ``WorkspaceServerClient``

### Requests

- ``WorkspaceServerRequests``

### Models

- ``WorkspaceServerHealth``
- ``WorkspaceEntitlements``
- ``WorkspaceTemplateList``
- ``WorkspaceTemplateSummary``
- ``WorkspaceJobID``
- ``WorkspaceJobSubmission``
- ``WorkspaceJobPhase``
- ``WorkspaceJobStatus``
- ``WorkspaceServerDiagnosticSource``
- ``WorkspaceServerDiagnosticEvent``
- ``WorkspaceDiagnosticsUpload``
- ``WorkspaceDiagnosticsReceipt``
