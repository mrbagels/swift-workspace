import Foundation

/// Builds typed route-open requests from URLs using an app-owned route map.
public struct WorkspaceRouteOpenURLParser<RouteID: Hashable & Sendable>: Sendable {
  public var defaultMode: WorkspaceRouteOpenMode
  public var routeCandidates: @Sendable (URL) -> [String]
  public var routeIDForPath: @Sendable (String) -> RouteID?

  public init(
    routesByPath: [String: RouteID],
    defaultMode: WorkspaceRouteOpenMode = .currentScene,
    routeCandidates: @escaping @Sendable (URL) -> [String] = Self.defaultRouteCandidates
  ) {
    let routesByNormalizedPath = Dictionary(
      uniqueKeysWithValues: routesByPath.map { path, routeID in
        (Self.normalizedPath(path), routeID)
      }
    )
    self.init(
      defaultMode: defaultMode,
      routeCandidates: routeCandidates
    ) { path in
      routesByNormalizedPath[Self.normalizedPath(path)]
    }
  }

  public init(
    defaultMode: WorkspaceRouteOpenMode = .currentScene,
    routeCandidates: @escaping @Sendable (URL) -> [String] = Self.defaultRouteCandidates,
    routeIDForPath: @escaping @Sendable (String) -> RouteID?
  ) {
    self.defaultMode = defaultMode
    self.routeCandidates = routeCandidates
    self.routeIDForPath = routeIDForPath
  }

  public func request(
    for url: URL,
    mode: WorkspaceRouteOpenMode? = nil
  ) -> WorkspaceRouteOpenRequest<RouteID>? {
    for candidate in routeCandidates(url) {
      let normalizedPath = Self.normalizedPath(candidate)
      guard !normalizedPath.isEmpty,
            let routeID = routeIDForPath(normalizedPath)
      else { continue }

      return .deepLink(
        routeID,
        url: url.absoluteString,
        mode: mode ?? defaultMode
      )
    }

    return nil
  }

  public static func defaultRouteCandidates(for url: URL) -> [String] {
    var candidates: [String] = []
    let host = url.host
    let path = normalizedPath(url.path)

    if let host, !host.isEmpty {
      if !path.isEmpty {
        candidates.append("\(host)/\(path)")
      }
      candidates.append(host)
    }

    if !path.isEmpty {
      candidates.append(path)
    }

    return candidates.reduce(into: []) { uniqueCandidates, candidate in
      let normalizedCandidate = normalizedPath(candidate)
      guard !normalizedCandidate.isEmpty,
            !uniqueCandidates.contains(normalizedCandidate)
      else { return }
      uniqueCandidates.append(normalizedCandidate)
    }
  }

  public static func normalizedPath(_ path: String) -> String {
    path
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      .components(separatedBy: "/")
      .filter { !$0.isEmpty }
      .joined(separator: "/")
      .lowercased()
  }
}
