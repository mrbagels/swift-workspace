# ``WorkspaceServerClient``

Optional Comet-backed client for thin workspace companion services.

## Overview

`WorkspaceServerClient` is an optional product for apps that need companion
server capabilities such as entitlements, templates, background jobs, and
diagnostics upload.

The server client is not primary storage. User-owned documents, workspace
restoration, and local-first preferences should remain local or iCloud-primary.

Use this module for:

- health checks,
- entitlement checks,
- template catalogs,
- job submission and status,
- diagnostics upload,
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
- ``WorkspaceDiagnosticsUpload``
- ``WorkspaceDiagnosticsReceipt``
