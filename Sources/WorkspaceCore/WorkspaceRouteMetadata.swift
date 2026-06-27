import Foundation

/// A field-level update used by metadata patches.
public enum WorkspaceValuePatch<Value: Equatable & Sendable>: Equatable, Sendable {
  case unchanged
  case set(Value)

  @discardableResult
  public func apply(to value: inout Value) -> Bool {
    switch self {
    case .unchanged:
      return false

    case .set(let nextValue):
      guard value != nextValue
      else { return false }
      value = nextValue
      return true
    }
  }
}

extension WorkspaceValuePatch: Codable where Value: Codable {}

/// A route metadata patch for live badges, availability, labels, shortcuts, and search metadata.
public struct WorkspaceRouteMetadataPatch<RouteID: Hashable & Sendable>:
  Equatable,
  Sendable
{
  public var availability: WorkspaceValuePatch<WorkspaceAvailability>
  public var badge: WorkspaceValuePatch<Int?>
  public var contentState: WorkspaceValuePatch<WorkspaceRouteContentState>
  public var isProminent: WorkspaceValuePatch<Bool>
  public var keywords: WorkspaceValuePatch<[String]>
  public var presentation: WorkspaceValuePatch<WorkspaceRoutePresentation>
  public var routeID: RouteID
  public var scenePresentation: WorkspaceValuePatch<WorkspaceScenePresentation>
  public var shortcut: WorkspaceValuePatch<WorkspaceKeyboardShortcut?>
  public var subtitle: WorkspaceValuePatch<String?>
  public var systemImage: WorkspaceValuePatch<String>
  public var title: WorkspaceValuePatch<String>

  public init(
    routeID: RouteID,
    availability: WorkspaceValuePatch<WorkspaceAvailability> = .unchanged,
    badge: WorkspaceValuePatch<Int?> = .unchanged,
    contentState: WorkspaceValuePatch<WorkspaceRouteContentState> = .unchanged,
    isProminent: WorkspaceValuePatch<Bool> = .unchanged,
    keywords: WorkspaceValuePatch<[String]> = .unchanged,
    presentation: WorkspaceValuePatch<WorkspaceRoutePresentation> = .unchanged,
    scenePresentation: WorkspaceValuePatch<WorkspaceScenePresentation> = .unchanged,
    shortcut: WorkspaceValuePatch<WorkspaceKeyboardShortcut?> = .unchanged,
    subtitle: WorkspaceValuePatch<String?> = .unchanged,
    systemImage: WorkspaceValuePatch<String> = .unchanged,
    title: WorkspaceValuePatch<String> = .unchanged
  ) {
    self.availability = availability
    self.badge = badge
    self.contentState = contentState
    self.isProminent = isProminent
    self.keywords = keywords
    self.presentation = presentation
    self.routeID = routeID
    self.scenePresentation = scenePresentation
    self.shortcut = shortcut
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.title = title
  }
}

extension WorkspaceRouteMetadataPatch: Codable where RouteID: Codable {}

extension WorkspaceRouteDescriptor {
  @discardableResult
  public mutating func apply(
    _ patch: WorkspaceRouteMetadataPatch<RouteID>
  ) -> Bool {
    guard id == patch.routeID
    else { return false }

    var changed = false
    changed = patch.availability.apply(to: &availability) || changed
    changed = patch.badge.apply(to: &badge) || changed
    changed = patch.contentState.apply(to: &contentState) || changed
    changed = patch.isProminent.apply(to: &isProminent) || changed
    changed = patch.keywords.apply(to: &keywords) || changed
    changed = patch.presentation.apply(to: &presentation) || changed
    changed = patch.scenePresentation.apply(to: &scenePresentation) || changed
    changed = patch.shortcut.apply(to: &shortcut) || changed
    changed = patch.subtitle.apply(to: &subtitle) || changed
    changed = patch.systemImage.apply(to: &systemImage) || changed
    changed = patch.title.apply(to: &title) || changed
    return changed
  }

  public func applying(
    _ patch: WorkspaceRouteMetadataPatch<RouteID>
  ) -> Self {
    var route = self
    route.apply(patch)
    return route
  }
}

extension WorkspaceRouteSection {
  @discardableResult
  public mutating func apply(
    _ patches: [WorkspaceRouteMetadataPatch<RouteID>]
  ) -> Bool {
    apply(patchesByRouteID: Dictionary(grouping: patches, by: \.routeID))
  }

  @discardableResult
  mutating func apply(
    patchesByRouteID: [RouteID: [WorkspaceRouteMetadataPatch<RouteID>]]
  ) -> Bool {
    var changed = false
    for index in routes.indices {
      guard let routePatches = patchesByRouteID[routes[index].id]
      else { continue }
      for patch in routePatches {
        changed = routes[index].apply(patch) || changed
      }
    }
    return changed
  }

  public func applying(
    _ patches: [WorkspaceRouteMetadataPatch<RouteID>]
  ) -> Self {
    var section = self
    section.apply(patches)
    return section
  }
}

extension WorkspaceNavigationRegistry {
  @discardableResult
  public mutating func apply(
    _ patches: [WorkspaceRouteMetadataPatch<RouteID>]
  ) -> Bool {
    let patchesByRouteID = Dictionary(grouping: patches, by: \.routeID)
    var changed = false
    for index in sections.indices {
      changed = sections[index].apply(patchesByRouteID: patchesByRouteID) || changed
    }
    return changed
  }

  public func applying(
    _ patches: [WorkspaceRouteMetadataPatch<RouteID>]
  ) -> Self {
    var registry = self
    registry.apply(patches)
    return registry
  }
}
