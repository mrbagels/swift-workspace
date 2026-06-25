# ``WorkspaceCloudKit``

Optional CloudKit contracts for iCloud-primary workspace integration.

## Overview

`WorkspaceCloudKit` defines record names, configuration values, envelopes,
conflict policies, and an async adapter protocol. It does not perform live sync.

Apps own CloudKit containers, accounts, subscriptions, retries, and conflict
resolution. User documents remain app-owned and iCloud-primary.

Use this module for:

- private or shared database scope decisions,
- workspace record names,
- restoration envelopes,
- route metadata envelopes,
- app-owned live adapter contracts.

## Topics

### Configuration

- ``WorkspaceCloudKitDatabaseScope``
- ``WorkspaceCloudKitSyncScope``
- ``WorkspaceCloudKitConflictPolicy``
- ``WorkspaceCloudKitConflictResolution``
- ``WorkspaceCloudKitRecordName``
- ``WorkspaceCloudKitZoneConfiguration``
- ``WorkspaceCloudKitConfiguration``
- ``WorkspaceCloudKitField``

### Payloads And Adapters

- ``WorkspaceCloudRouteMetadata``
- ``WorkspaceCloudKitRestorationEnvelope``
- ``WorkspaceCloudKitRouteMetadataEnvelope``
- ``WorkspaceCloudKitSyncAdapter``
