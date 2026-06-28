# API Stability Review: 0.1.0

Date: 2026-06-27

## Decision

`swift-workspace` is acceptable to publish as `0.1.0` after manual demo QA.
The package surface is coherent enough for early adopters, and the remaining
work is either manual release validation or explicitly decision-gated product
work.

Because this is a `0.x` release, source-breaking API changes remain possible
before `1.0.0`. Even so, public types should now be treated as reviewed product
surface: changes should come with migration notes, focused tests, and updated
adoption docs.

## Reviewed Scope

- `WorkspaceCore`
- `WorkspaceTCA`
- `WorkspaceEngine`
- `WorkspacePersistence`
- `WorkspaceSQLiteData`
- `WorkspaceCloudKit`
- `WorkspaceShellDesignSystem`
- `WorkspaceAutomationBridge`
- `WorkspaceServerClient`
- `WorkspaceServerTesting`
- `MacWorkspaceShell`
- `IOSWorkspaceShell`
- Demo targets, starter apps, custom renderer example, adoption docs, package
  map, and release checklist

## Findings

Package boundaries: pass.

- `WorkspaceCore` stays platform-neutral and imports Foundation only.
- `WorkspaceTCA` depends on `WorkspaceCore` and TCA.
- `WorkspaceEngine` remains a convenience product, not a behavior owner.
- SQLiteData and CloudKit support are optional products.
- Platform shells depend on shared reducer behavior rather than duplicating
  routing or command execution.

Naming: pass.

- Shared public concepts use the `Workspace...` prefix.
- Mac-only concepts use the `MacWorkspace...` prefix.
- iOS-only concepts use the `IOSWorkspace...` prefix.
- The old native split-view style API is not active source.
- `MacWorkspaceSidebarPresentation` is the reviewed customization point for
  edge-to-edge and floating custom sidebar presentation.

Sendable and Codable: pass for current intended storage boundaries.

- Route, command, scene, metadata, restoration, CloudKit, and persistence
  payloads are `Sendable`.
- Storage-safe generic payloads use conditional `Codable` conformance where
  route IDs control encodability.
- Persistence-significant enums use stable raw values where practical.

Renderer rules: pass.

- Renderers do not write persistence directly.
- Renderers do not call a server.
- Renderers do not own app documents or workflow state.
- Platform chrome restoration is wrapped separately from shared workspace
  restoration.
- Accessibility identifiers are stable and suitable for UI automation.

Reducer rules: pass.

- `WorkspaceFeature` owns route selection, command palette state, command
  execution, policy rejection, route-open handling, scene delegates, recents,
  section collapse state, restoration loading, registry replacement, and route
  metadata reconciliation.
- App-specific effects leave through delegate actions.
- No shared effects were introduced without a proven engine-owned behavior.

Adapter rules: pass.

- Persistence helpers encode small workspace restoration payloads, not app
  documents.
- SQLiteData helpers provide records, migrations, and codecs without owning an
  app database lifecycle.
- CloudKit helpers provide contracts and envelopes without owning the app
  container lifecycle.
- `WorkspaceServerClient` is optional, Comet-backed, and not linked by core
  engine, persistence, or renderer products.
- `WorkspaceServerTesting` is optional, CometTesting-backed, and scoped to test
  fixtures, replay, contracts, and reports.
- `WorkspaceAutomationBridge` is descriptor-only and leaves concrete App Intent
  types to host app targets.
- `WorkspaceShellDesignSystem` owns reusable SwiftUI primitives only.

Docs and examples: pass.

- README, package map, adoption docs, DocC landing pages, and operation docs
  agree on product responsibilities.
- Starter apps and `Examples/CustomRendererClient` demonstrate shell and
  engine-only adoption paths.
- The release checklist still requires manual demo QA before a public tag.

## Release Notes For 0.1.0

`0.1.0` should be described as an initial public beta for reusable Swift
workspace routing, command, scene, persistence, CloudKit contract, automation,
optional server client, design-system, Mac shell, and iOS shell APIs.

Known limits:

- Manual demo QA is still required before tagging.
- Server companion behavior is available as an optional typed client only. No
  backend is included.
- Pixel-level visual snapshots are not yet exhaustive.
- The package currently targets iOS 26 and macOS 26.

## Follow-Up Gates

- Do not tag `0.1.0` until Mac and iOS manual QA pass.
- Do not wire `WorkspaceServerClient` into an app flow until the first
  server-backed workflow, authentication model, request payloads, offline
  behavior, retry behavior, cancellation behavior, and privacy requirements are
  known.
- Do not import `WorkspaceServerTesting` from production targets.
- For future public behavior, add reducer and renderer fixtures before merging
  the feature.
