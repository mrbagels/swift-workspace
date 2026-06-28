# Workspace Engine Split

Last updated: 2026-06-28

## Goal

`swift-workspace` turns the Mac Shell prototype into a reusable engine and a family
of renderers. A client should be able to import the smallest useful product, or
adopt the whole engine and a platform shell with very little glue.

The engine owns shared application mechanics. Platform shells own presentation.
Adapters own persistence and external integration.

## Product Boundary

### WorkspaceCore

`WorkspaceCore` is pure Swift. It owns the vocabulary every platform and client
can share:

- typed command IDs,
- typed route descriptors,
- route sections,
- availability,
- command search,
- command reference grouping,
- command execution policy,
- keyboard shortcut metadata,
- route-open requests,
- route-open URL parsing,
- route-open rejections,
- route metadata patches,
- scene requests,
- scene values,
- scene collections,
- workspace restoration payloads.

It must not import SwiftUI, TCA, SQLiteData, CloudKit, AppKit, or UIKit.

### WorkspaceTCA

`WorkspaceTCA` wraps `WorkspaceCore` in a reusable reducer. It owns state
transitions that are shared across platforms:

- selecting routes,
- executing commands,
- opening command palette state,
- filtering and moving command selection,
- enforcing command policies,
- emitting app-owned command delegates,
- emitting scene requests,
- restoring shared workspace state,
- applying route metadata patches,
- replacing navigation registries,
- tracking recent commands,
- tracking collapsed sections.

It must not own Mac chrome, iOS navigation presentation, database writes,
CloudKit writes, server calls, or app domain behavior.

### WorkspaceEngine

`WorkspaceEngine` is the convenience umbrella for clients that want the default
engine wholesale. It re-exports `WorkspaceCore`, `WorkspaceTCA`,
`WorkspacePersistence`, and TCA.

Optional adapters remain separate products so clients are not forced to link
SQLiteData, CloudKit, or server clients.

### WorkspacePersistence

`WorkspacePersistence` owns small storage helpers that do not require a larger
database dependency:

- JSON encoding and decoding,
- UserDefaults restoration storage,
- future file-backed stores,
- future dependency wrappers for app-controlled persistence.

### WorkspaceSQLiteData

`WorkspaceSQLiteData` is optional. It owns SQLiteData records, codecs, and
migration helpers for apps that already use a local SQLiteData database.

The package may provide:

- workspace restoration records,
- route metadata records,
- route metadata codecs,
- migration helpers,
- stores for app-owned scene state.

Apps still own their database lifecycle, database dependencies, migrations list,
and write effects.

### WorkspaceCloudKit

`WorkspaceCloudKit` is optional. It exists because iCloud is the primary storage
model for user-owned data.

This target should define stable adapter contracts first, then add live
CloudKit workflows when the local engine API is stable.

It should support:

- private database user preferences,
- shared database collaboration metadata,
- route metadata records,
- workspace restoration records,
- conflict policy hooks,
- explicit app-owned sync decisions.

It must not make CloudKit a hidden dependency of the core engine.

### WorkspaceShellDesignSystem

`WorkspaceShellDesignSystem` is optional SwiftUI presentation infrastructure. It
owns small reusable primitives shared by bundled shells and custom renderers:

- badges,
- keycaps,
- section labels,
- route status views,
- palette and metrics values.

It must not own routing, command execution, persistence, server behavior, or app
domain state.

### WorkspaceAutomationBridge

`WorkspaceAutomationBridge` is optional. It turns the command registry into a
serializable automation catalog and stable handoff payloads for app-owned App
Intents, Shortcuts, widgets, and controls.

It does not define concrete App Intent types. Host app targets own their intent
types, phrases, permissions, entities, and runtime handoff routing.

### WorkspaceServerClient

`WorkspaceServerClient` is optional and Comet-backed. It provides typed
companion service requests for entitlements, templates, jobs, diagnostics, and
health checks.

It must remain separate from `WorkspaceCore`, `WorkspaceTCA`, and renderers. The
shared reducer may emit command delegates that an app maps to server effects,
but the engine should not call the server directly.

### WorkspaceServerTesting

`WorkspaceServerTesting` is optional and CometTesting-backed. It provides
recording, replay, cassette promotion, strict contract, and report helpers for
tests and local proof workflows around `WorkspaceServerClient`.

It must not be imported by production app targets, platform renderers, or core
engine products.

### MacWorkspaceShell

`MacWorkspaceShell` renders `WorkspaceTCA` on macOS. It may use SwiftUI, AppKit,
menus, titlebar configuration, keyboard commands, split views, inspectors,
column widths, and Mac-native restoration affordances.

It must not become the engine. If a behavior should work on iOS or in a custom
client renderer, move that behavior down into `WorkspaceCore` or `WorkspaceTCA`.

### IOSWorkspaceShell

`IOSWorkspaceShell` renders the same engine on iOS and iPadOS. It should use
platform-appropriate navigation, including `NavigationSplitView`, stack
navigation, search, scene behavior, and compact layouts.

It does not need to mimic the Mac shell. It needs to preserve the engine
contracts.

### Server Companion

Server functionality is optional and thin. It should provide companion
capabilities:

- accounts,
- licensing,
- feature flags,
- templates,
- AI or import jobs,
- export jobs,
- webhook relay,
- diagnostics,
- support bundles,
- integration credentials.

It should not become the canonical storage system for user-authored documents or
workspace state. iCloud and local storage remain primary.

## Naming Direction

The prototype used `Shell...` names because the first product was a Mac shell.
The clean product uses `Workspace...` for engine concepts:

- `WorkspaceRouteDescriptor`
- `WorkspaceRouteSection`
- `WorkspaceNavigationRegistry`
- `WorkspaceCommand`
- `WorkspaceCommandSearch`
- `WorkspaceSceneRequest`
- `WorkspaceSceneValue`
- `WorkspaceRestoration`

Mac-specific rendering types may use `MacWorkspace...` names.

## Route Metadata Updates

Routes keep display and behavior metadata in `WorkspaceRouteDescriptor` for now.
This keeps first adoption ergonomic and avoids a premature identity/metadata
split.

Live route changes use `WorkspaceRouteMetadataPatch` rather than direct array
mutation in clients. Patches can update:

- availability,
- badge,
- prominence,
- keywords,
- presentation,
- scene presentation,
- shortcut,
- subtitle,
- system image,
- title.

`WorkspaceNavigationRegistry.apply(_:)` merges patches across all route
sections. `WorkspaceFeature` exposes `routeMetadataPatchesApplied` and then
reconciles selected route, collapsed sections, recent commands, and palette
selection.

If a selected route becomes hidden, disabled, or missing, the reducer falls back
to the first visible enabled route when one exists.

## Command Reference

`WorkspaceCommand` now has an explicit `WorkspaceCommandRole` derived from its
target:

- app action,
- navigation,
- primary action,
- scene,
- system,
- toolbar action.

`WorkspaceCommandSections` groups visible commands for Help, settings,
onboarding, menus, or custom reference surfaces. It can group by flat list,
category, role, or source, and it can include or remove disabled commands.

These helpers live in `WorkspaceCore` because they are pure command registry
logic. Platform renderers decide how sections look.

## Route-Open URL Parsing

Deep-link parsing is app-configurable through `WorkspaceRouteOpenURLParser`.
The core provides candidate extraction and path normalization, while the app
owns the mapping from URL paths to typed route IDs.

The parser emits `WorkspaceRouteOpenRequest` values with `.deepLink` source
metadata. Platform shells and parent app reducers can feed those requests into
`WorkspaceFeature.routeOpenRequested`.

## Dependency Rules

Allowed dependencies:

- `WorkspaceCore`: Foundation only.
- `WorkspaceTCA`: WorkspaceCore, TCA.
- `WorkspaceEngine`: WorkspaceCore, WorkspaceTCA, WorkspacePersistence, TCA.
- `WorkspacePersistence`: WorkspaceCore, Foundation.
- `WorkspaceSQLiteData`: WorkspaceCore, SQLiteData.
- `WorkspaceCloudKit`: WorkspaceCore, CloudKit.
- `WorkspaceShellDesignSystem`: WorkspaceCore, SwiftUI.
- `WorkspaceAutomationBridge`: WorkspaceCore.
- `WorkspaceServerClient`: WorkspaceCore, Comet, CometTCA, TCA.
- `WorkspaceServerTesting`: WorkspaceServerClient, Comet, CometTesting.
- `MacWorkspaceShell`: WorkspaceCore, WorkspaceTCA, WorkspaceShellDesignSystem,
  SwiftUI, AppKit as needed.
- `IOSWorkspaceShell`: WorkspaceCore, WorkspaceTCA, WorkspaceShellDesignSystem,
  SwiftUI, UIKit as needed.

Forbidden dependency directions:

- Core must not depend on any renderer.
- Core must not depend on adapters.
- TCA must not depend on renderers.
- Platform shells must not write directly to persistence without app ownership.
- Optional adapters must not be required by default shell usage.

## Restoration Split

The engine restoration payload should remain shared:

- selected route,
- collapsed sections,
- recent command IDs,
- shared scene values,
- route metadata version markers when needed.

Platform chrome restoration should stay platform-specific:

- Mac sidebar visibility,
- Mac inspector visibility,
- Mac column widths,
- Mac density,
- iPad column preference,
- iOS selected tab or compact navigation state.

This keeps iOS from inheriting meaningless Mac layout data and keeps Mac chrome
from leaking into custom clients.

## Server Boundary

The server should receive explicit work requests from app features. The engine
may model commands that trigger app-owned behavior, but it should not secretly
call a server.

A good server request is:

- "run OCR for this imported file",
- "refresh the template catalog",
- "validate entitlement",
- "send diagnostics bundle",
- "enqueue export job".

A bad server request is:

- "save the user's document as the source of truth",
- "own route restoration",
- "replace CloudKit sync",
- "hide local-first conflict resolution behind a remote API".

## Current Scaffold

The initial scaffold includes:

- a root `Package.swift`,
- an XcodeGen `project.yml`,
- platform-neutral core models,
- command reference and command role helpers,
- route metadata patch helpers,
- route-open URL parser,
- a first TCA reducer,
- reducer reconciliation for navigation and metadata updates,
- optional persistence adapter targets,
- first-pass Mac and iOS shell renderers,
- macOS and iOS demo apps,
- tests for core search, command grouping, metadata patches, deep-link parsing,
  scene identity, reducer state, route-open behavior, command policy, and
  UserDefaults restoration,
- documentation lifecycle folders,
- doctor and verify scripts.

The next implementation phases should harden APIs, add richer renderer
behavior, and bring over proven ideas from the prototype deliberately.
