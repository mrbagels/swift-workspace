import Foundation

/// The scene behavior a route prefers when opened outside the current surface.
public enum WorkspaceSceneKind: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
  case document
  case primary
  case singleton
  case utility
}

/// Presentation metadata for opening a route in the current surface or another scene.
public struct WorkspaceScenePresentation: Codable, Equatable, Hashable, Sendable {
  public var kind: WorkspaceSceneKind
  public var preferredSceneID: WorkspaceSceneID?
  public var title: String?

  public init(
    kind: WorkspaceSceneKind,
    preferredSceneID: WorkspaceSceneID? = nil,
    title: String? = nil
  ) {
    self.kind = kind
    self.preferredSceneID = preferredSceneID
    self.title = title
  }

  public static let primary = Self(kind: .primary)

  public static func document(title: String? = nil) -> Self {
    Self(kind: .document, title: title)
  }

  public static func singleton(
    id: WorkspaceSceneID,
    title: String? = nil
  ) -> Self {
    Self(kind: .singleton, preferredSceneID: id, title: title)
  }

  public static func utility(
    id: WorkspaceSceneID,
    title: String? = nil
  ) -> Self {
    Self(kind: .utility, preferredSceneID: id, title: title)
  }

  public var opensInSeparateScene: Bool {
    kind != .primary
  }

  public var systemImage: String {
    switch kind {
    case .document:
      "doc"
    case .primary:
      "macwindow"
    case .singleton:
      "macwindow.on.rectangle"
    case .utility:
      "sidebar.right"
    }
  }
}

/// The path that requested a scene.
public enum WorkspaceSceneRequestSource: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
  case command
  case openRouteRequest
  case routeAction
}

/// A typed request emitted when a route should open in another scene.
public struct WorkspaceSceneRequest<RouteID: Hashable & Sendable>: Equatable, Sendable {
  public var presentation: WorkspaceScenePresentation
  public var routeID: RouteID
  public var source: WorkspaceSceneRequestSource

  public init(
    routeID: RouteID,
    presentation: WorkspaceScenePresentation,
    source: WorkspaceSceneRequestSource
  ) {
    self.presentation = presentation
    self.routeID = routeID
    self.source = source
  }
}

extension WorkspaceSceneRequest: Codable where RouteID: Codable {}

/// A Codable value suitable for SwiftUI scene restoration and opening.
public struct WorkspaceSceneValue<RouteID: Codable & Hashable & Sendable>:
  Codable,
  Equatable,
  Hashable,
  Identifiable,
  Sendable
{
  public var id: String
  public var kind: WorkspaceSceneKind
  public var restorationKey: String
  public var route: RouteID
  public var source: WorkspaceSceneRequestSource
  public var title: String?

  public init(
    id: String,
    route: RouteID,
    kind: WorkspaceSceneKind,
    source: WorkspaceSceneRequestSource,
    title: String? = nil,
    restorationKey: String? = nil
  ) {
    self.id = id
    self.kind = kind
    self.restorationKey = restorationKey ?? Self.defaultRestorationKey(for: id)
    self.route = route
    self.source = source
    self.title = title
  }

  public init(
    request: WorkspaceSceneRequest<RouteID>,
    sequence: Int,
    encodeRouteID: @Sendable (RouteID) -> String,
    restorationKey: @Sendable (String) -> String = Self.defaultRestorationKey
  ) {
    let id = Self.sceneID(
      for: request,
      sequence: sequence,
      encodeRouteID: encodeRouteID
    )
    self.init(
      id: id,
      route: request.routeID,
      kind: request.presentation.kind,
      source: request.source,
      title: request.presentation.title,
      restorationKey: restorationKey(id)
    )
  }

  public static func sceneID(
    for request: WorkspaceSceneRequest<RouteID>,
    sequence: Int,
    encodeRouteID: @Sendable (RouteID) -> String
  ) -> String {
    if request.presentation.kind == .document {
      return "\(encodeRouteID(request.routeID))-document-\(sequence)"
    }

    if let preferredSceneID = request.presentation.preferredSceneID {
      return preferredSceneID.rawValue
    }

    return "\(encodeRouteID(request.routeID))-\(request.presentation.kind.rawValue)"
  }

  public static func defaultRestorationKey(for id: String) -> String {
    "Workspace.scene.\(id)"
  }
}

/// App-owned collection state for document, singleton, and utility scenes.
public struct WorkspaceSceneCollection<RouteID: Codable & Hashable & Sendable>:
  Codable,
  Equatable,
  Sendable
{
  public private(set) var values: [WorkspaceSceneValue<RouteID>]
  private var nextDocumentSequence: Int

  public init(values: [WorkspaceSceneValue<RouteID>] = []) {
    self.values = values
    self.nextDocumentSequence = Self.nextSequence(after: values)
  }

  @discardableResult
  public mutating func open(
    _ request: WorkspaceSceneRequest<RouteID>,
    encodeRouteID: @Sendable (RouteID) -> String,
    restorationKey: @Sendable (String) -> String = WorkspaceSceneValue<RouteID>.defaultRestorationKey
  ) -> WorkspaceSceneValue<RouteID> {
    let sequence = nextDocumentSequence
    let value = WorkspaceSceneValue(
      request: request,
      sequence: sequence,
      encodeRouteID: encodeRouteID,
      restorationKey: restorationKey
    )

    if request.presentation.kind == .document {
      nextDocumentSequence += 1
      values.append(value)
    } else if let index = values.firstIndex(where: { $0.id == value.id }) {
      values[index] = value
    } else {
      values.append(value)
    }

    return value
  }

  public mutating func close(id: WorkspaceSceneValue<RouteID>.ID) {
    values.removeAll { $0.id == id }
  }

  public mutating func restore(_ restoredValues: [WorkspaceSceneValue<RouteID>]) {
    values = restoredValues
    nextDocumentSequence = Self.nextSequence(after: restoredValues)
  }

  public func values(for route: RouteID) -> [WorkspaceSceneValue<RouteID>] {
    values.filter { $0.route == route }
  }

  private static func nextSequence(after values: [WorkspaceSceneValue<RouteID>]) -> Int {
    let documentSequences = values.compactMap { value -> Int? in
      guard value.kind == .document,
            let sequence = value.id.split(separator: "-").last.flatMap({ Int($0) })
      else { return nil }
      return sequence
    }
    return (documentSequences.max() ?? 0) + 1
  }
}

/// How a programmatic route open should be resolved.
public enum WorkspaceRouteOpenMode: String, CaseIterable, Codable, Equatable, Sendable {
  case currentScene
  case preferredScene
}

/// The origin of a programmatic route-open request.
public enum WorkspaceRouteOpenSource: Codable, Equatable, Sendable {
  case deepLink(String)
  case externalEvent(String)
  case programmatic
  case restoration
}

/// A typed navigation request from a deep link, restoration flow, or parent reducer.
public struct WorkspaceRouteOpenRequest<RouteID: Hashable & Sendable>: Equatable, Sendable {
  public var mode: WorkspaceRouteOpenMode
  public var routeID: RouteID
  public var source: WorkspaceRouteOpenSource

  public init(
    routeID: RouteID,
    mode: WorkspaceRouteOpenMode = .currentScene,
    source: WorkspaceRouteOpenSource = .programmatic
  ) {
    self.mode = mode
    self.routeID = routeID
    self.source = source
  }

  public static func deepLink(
    _ routeID: RouteID,
    url: String,
    mode: WorkspaceRouteOpenMode = .currentScene
  ) -> Self {
    Self(routeID: routeID, mode: mode, source: .deepLink(url))
  }
}

extension WorkspaceRouteOpenRequest: Codable where RouteID: Codable {}

/// Why a route-open request could not be fulfilled.
public enum WorkspaceRouteOpenRejectionReason: String, CaseIterable, Codable, Equatable, Sendable {
  case routeDisabled
  case routeHidden
  case routeNotFound
}

/// A rejected route-open request and its reason.
public struct WorkspaceRouteOpenRejection<RouteID: Hashable & Sendable>: Equatable, Sendable {
  public var reason: WorkspaceRouteOpenRejectionReason
  public var request: WorkspaceRouteOpenRequest<RouteID>

  public init(
    request: WorkspaceRouteOpenRequest<RouteID>,
    reason: WorkspaceRouteOpenRejectionReason
  ) {
    self.reason = reason
    self.request = request
  }
}

extension WorkspaceRouteOpenRejection: Codable where RouteID: Codable {}
