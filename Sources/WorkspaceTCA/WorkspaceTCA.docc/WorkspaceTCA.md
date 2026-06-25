# ``WorkspaceTCA``

Composable Architecture reducer for shared workspace behavior.

## Overview

`WorkspaceTCA` wraps `WorkspaceCore` in `WorkspaceFeature`, a platform-neutral
reducer. It owns shared state transitions while leaving presentation, storage,
networking, and app domain behavior to the consumer.

Use this module when a client wants:

- route selection,
- command execution,
- command palette lifecycle,
- command policy enforcement,
- route-open rejection,
- scene request delegates,
- recent command tracking,
- collapsed section tracking,
- restoration loading,
- navigation registry replacement,
- route metadata reconciliation.

Platform shells consume this reducer. Custom renderers can consume it directly.

## Topics

### Reducer

- ``WorkspaceFeature``
