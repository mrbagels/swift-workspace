# ``WorkspaceSQLiteData``

Optional SQLiteData records, migrations, and codecs for workspace payloads.

## Overview

`WorkspaceSQLiteData` is for apps that already own a SQLiteData database and
want typed helpers for workspace restoration or route metadata. It does not own
the app database lifecycle, dependency wiring, write effects, or app documents.

Use this module for:

- restoration records,
- route metadata records,
- migration helpers,
- route metadata codecs.

## Topics

### Records

- ``WorkspaceRestorationRecord``
- ``WorkspaceRouteMetadataRecord``
- ``WorkspaceRouteAvailabilityState``

### Migrations And Codecs

- ``WorkspaceSQLiteDataMigrations``
- ``WorkspaceSQLiteDataCodec``
- ``WorkspaceSQLiteDataRouteMetadataCodec``
- ``WorkspaceRouteMetadata``
