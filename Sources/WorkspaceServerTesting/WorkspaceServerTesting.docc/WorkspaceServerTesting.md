# ``WorkspaceServerTesting``

Test helpers for Comet-backed workspace companion server workflows.

## Overview

`WorkspaceServerTesting` is an optional product for tests, fixtures, and local
proof workflows around `WorkspaceServerClient`. It builds on CometTesting so app
teams can record a cassette once, approve it in source control, replay it
deterministically, and promote it to a strict contract.

The default recording redaction includes common sensitive headers plus dynamic
trace propagation headers so promoted contracts do not compare generated trace
IDs exactly.

Use this module for:

- recording workspace server traffic into `HTTPCassette` fixtures,
- replaying approved fixtures through `WorkspaceServerClient`,
- converting approved cassettes into strict `ContractTransport` sessions,
- writing contract reports as CI artifacts.

Do not import this product from production app targets. Production code should
use `WorkspaceServerClient` directly.

## Topics

### Workflow

- ``WorkspaceServerContractWorkflow``
- ``WorkspaceServerRecordingSession``
- ``WorkspaceServerContractSession``
