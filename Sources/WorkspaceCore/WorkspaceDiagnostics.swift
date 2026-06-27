import Foundation

/// Severity for registry validation and adoption diagnostics.
public enum WorkspaceDiagnosticSeverity: String, CaseIterable, Codable, Equatable, Sendable {
  case info
  case warning
  case error
}

/// Stable diagnostic codes emitted by workspace validation.
public enum WorkspaceDiagnosticCode: String, CaseIterable, Codable, Equatable, Sendable {
  case duplicateCommandID
  case duplicateRouteID
  case duplicateSceneID
  case duplicateSectionID
  case duplicateShortcut
  case emptyCommandTitle
  case emptyRouteSystemImage
  case emptyRouteTitle
  case emptySectionTitle
  case hiddenSelectedRoute
  case missingPinnedRoute
  case missingRecentRoute
  case missingSelectedRoute
  case unavailableSelectedRoute
}

/// A single validation issue suitable for CI logs, debug UI, or release checks.
public struct WorkspaceDiagnostic: Codable, Equatable, Sendable {
  public var code: WorkspaceDiagnosticCode
  public var message: String
  public var path: String
  public var relatedPaths: [String]
  public var severity: WorkspaceDiagnosticSeverity

  public init(
    code: WorkspaceDiagnosticCode,
    severity: WorkspaceDiagnosticSeverity,
    message: String,
    path: String,
    relatedPaths: [String] = []
  ) {
    self.code = code
    self.message = message
    self.path = path
    self.relatedPaths = relatedPaths
    self.severity = severity
  }
}

/// A deterministic validation report for a workspace registry.
public struct WorkspaceDiagnosticsReport: Codable, Equatable, Sendable {
  public var diagnostics: [WorkspaceDiagnostic]

  public init(diagnostics: [WorkspaceDiagnostic] = []) {
    self.diagnostics = diagnostics
  }

  public var errors: [WorkspaceDiagnostic] {
    diagnostics.filter { $0.severity == .error }
  }

  public var warnings: [WorkspaceDiagnostic] {
    diagnostics.filter { $0.severity == .warning }
  }

  public var hasErrors: Bool {
    !errors.isEmpty
  }
}

public extension WorkspaceNavigationRegistry {
  /// Validates route, command, shortcut, scene, and personalized navigation state.
  func validate(
    selectedRouteID: RouteID? = nil,
    pinnedRouteIDs: [RouteID] = [],
    recentRouteIDs: [RouteID] = []
  ) -> WorkspaceDiagnosticsReport {
    var diagnostics: [WorkspaceDiagnostic] = []
    var sectionPathsByID: [WorkspaceRouteSectionID: [String]] = [:]
    var routePathsByID: [RouteID: [String]] = [:]
    var commandPathsByID: [WorkspaceCommandIdentifier<RouteID>: [String]] = [:]
    var scenePathsByID: [WorkspaceSceneID: [String]] = [:]
    var shortcutOwnersByKey: [WorkspaceKeyboardShortcutKey: [WorkspaceShortcutOwner]] = [:]

    for (sectionIndex, section) in sections.enumerated() {
      let sectionPath = "sections[\(sectionIndex)]"
      sectionPathsByID[section.id, default: []].append(sectionPath)

      if section.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        diagnostics.append(
          WorkspaceDiagnostic(
            code: .emptySectionTitle,
            severity: .warning,
            message: "Section \(section.id) has an empty title.",
            path: "\(sectionPath).title"
          )
        )
      }

      for (routeIndex, route) in section.routes.enumerated() {
        let routePath = "\(sectionPath).routes[\(routeIndex)]"
        routePathsByID[route.id, default: []].append(routePath)

        if route.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          diagnostics.append(
            WorkspaceDiagnostic(
              code: .emptyRouteTitle,
              severity: .error,
              message: "Route \(route.id) has an empty title.",
              path: "\(routePath).title"
            )
          )
        }

        if route.systemImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          diagnostics.append(
            WorkspaceDiagnostic(
              code: .emptyRouteSystemImage,
              severity: .warning,
              message: "Route \(route.id) has an empty system image.",
              path: "\(routePath).systemImage"
            )
          )
        }

        if let shortcut = route.shortcut {
          shortcutOwnersByKey[WorkspaceKeyboardShortcutKey(shortcut), default: []].append(
            WorkspaceShortcutOwner(
              label: "route \(route.id)",
              path: "\(routePath).shortcut"
            )
          )
        }

        if let sceneID = route.scenePresentation.preferredSceneID {
          scenePathsByID[sceneID, default: []].append("\(routePath).scenePresentation")
        }
      }
    }

    for (commandIndex, command) in commands.enumerated() {
      let commandPath = "commands[\(commandIndex)]"
      commandPathsByID[command.id, default: []].append(commandPath)

      if command.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        diagnostics.append(
          WorkspaceDiagnostic(
            code: .emptyCommandTitle,
            severity: .error,
            message: "Command \(command.id) has an empty title.",
            path: "\(commandPath).title"
          )
        )
      }

      if let shortcut = command.shortcut {
        shortcutOwnersByKey[WorkspaceKeyboardShortcutKey(shortcut), default: []].append(
          WorkspaceShortcutOwner(
            label: "command \(command.id)",
            path: "\(commandPath).shortcut"
          )
        )
      }
    }

    diagnostics.append(contentsOf: duplicateDiagnostics(
      for: sectionPathsByID,
      code: .duplicateSectionID,
      severity: .error,
      label: "section"
    ))
    diagnostics.append(contentsOf: duplicateDiagnostics(
      for: routePathsByID,
      code: .duplicateRouteID,
      severity: .error,
      label: "route"
    ))
    diagnostics.append(contentsOf: duplicateDiagnostics(
      for: commandPathsByID,
      code: .duplicateCommandID,
      severity: .error,
      label: "command"
    ))
    diagnostics.append(contentsOf: duplicateDiagnostics(
      for: scenePathsByID,
      code: .duplicateSceneID,
      severity: .warning,
      label: "scene"
    ))

    for (shortcutKey, owners) in shortcutOwnersByKey where owners.count > 1 {
      diagnostics.append(
        WorkspaceDiagnostic(
          code: .duplicateShortcut,
          severity: .warning,
          message: "Shortcut \(shortcutKey.displayLabel) is used by \(owners.map(\.label).joined(separator: ", ")).",
          path: owners[0].path,
          relatedPaths: Array(owners.dropFirst().map(\.path))
        )
      )
    }

    if let selectedRouteID {
      if let route = route(for: selectedRouteID) {
        if !route.availability.isVisible {
          diagnostics.append(
            WorkspaceDiagnostic(
              code: .hiddenSelectedRoute,
              severity: .error,
              message: "Selected route \(selectedRouteID) is hidden.",
              path: "selectedRouteID"
            )
          )
        } else if !route.availability.isEnabled {
          diagnostics.append(
            WorkspaceDiagnostic(
              code: .unavailableSelectedRoute,
              severity: .warning,
              message: "Selected route \(selectedRouteID) is disabled.",
              path: "selectedRouteID"
            )
          )
        }
      } else {
        diagnostics.append(
          WorkspaceDiagnostic(
            code: .missingSelectedRoute,
            severity: .error,
            message: "Selected route \(selectedRouteID) does not exist in the registry.",
            path: "selectedRouteID"
          )
        )
      }
    }

    for (index, routeID) in pinnedRouteIDs.enumerated()
    where visibleRoute(for: routeID) == nil {
      diagnostics.append(
        WorkspaceDiagnostic(
          code: .missingPinnedRoute,
          severity: .warning,
          message: "Pinned route \(routeID) is missing or hidden.",
          path: "pinnedRouteIDs[\(index)]"
        )
      )
    }

    for (index, routeID) in recentRouteIDs.enumerated()
    where visibleRoute(for: routeID) == nil {
      diagnostics.append(
        WorkspaceDiagnostic(
          code: .missingRecentRoute,
          severity: .info,
          message: "Recent route \(routeID) is missing or hidden.",
          path: "recentRouteIDs[\(index)]"
        )
      )
    }

    return WorkspaceDiagnosticsReport(diagnostics: diagnostics)
  }
}

private struct WorkspaceShortcutOwner: Sendable {
  var label: String
  var path: String
}

private struct WorkspaceKeyboardShortcutKey: Hashable, Sendable {
  var key: String
  var modifiers: WorkspaceKeyboardModifiers

  init(_ shortcut: WorkspaceKeyboardShortcut) {
    self.key = shortcut.key.lowercased()
    self.modifiers = shortcut.modifiers
  }

  var displayLabel: String {
    "\(modifiers.displayPrefix)\(key.uppercased())"
  }
}

private func duplicateDiagnostics<Key: Hashable>(
  for pathsByKey: [Key: [String]],
  code: WorkspaceDiagnosticCode,
  severity: WorkspaceDiagnosticSeverity,
  label: String
) -> [WorkspaceDiagnostic] {
  pathsByKey.compactMap { key, paths in
    guard paths.count > 1
    else { return nil }
    return WorkspaceDiagnostic(
      code: code,
      severity: severity,
      message: "Duplicate \(label) identifier \(key).",
      path: paths[0],
      relatedPaths: Array(paths.dropFirst())
    )
  }
  .sorted { lhs, rhs in
    if lhs.path == rhs.path { return lhs.message < rhs.message }
    return lhs.path < rhs.path
  }
}
