# ``WorkspacePersistence``

Storage helpers for small shared workspace restoration payloads.

## Overview

`WorkspacePersistence` encodes and stores `WorkspaceRestoration` values. It is
for shared engine state, not app documents or workflow data.

Use this module for:

- JSON encoding and decoding,
- UserDefaults-backed restoration,
- file-backed restoration.

Apps own when persistence runs. Platform shells should not write storage
directly.

## Topics

### Codecs And Stores

- ``WorkspaceJSONCodec``
- ``WorkspaceUserDefaultsPersistence``
- ``WorkspaceFilePersistence``
