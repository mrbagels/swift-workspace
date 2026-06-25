import Foundation

/// Shared route presentation intent. Platform renderers decide the exact UI.
public enum WorkspaceRoutePresentation: String, CaseIterable, Codable, Equatable, Sendable {
  case listDetail
  case fullWidth
}

/// A section containing route descriptors.
public struct WorkspaceRouteSection<RouteID: Hashable & Sendable>:
  Equatable,
  Identifiable,
  Sendable
{
  public var id: WorkspaceRouteSectionID
  public var isCollapsible: Bool
  public var routes: [WorkspaceRouteDescriptor<RouteID>]
  public var title: String

  public init(
    id: WorkspaceRouteSectionID,
    title: String,
    isCollapsible: Bool = false,
    routes: [WorkspaceRouteDescriptor<RouteID>]
  ) {
    self.id = id
    self.title = title
    self.isCollapsible = isCollapsible
    self.routes = routes
  }

  public func withRoutes(_ routes: [WorkspaceRouteDescriptor<RouteID>]) -> Self {
    var section = self
    section.routes = routes
    return section
  }
}

extension WorkspaceRouteSection: Codable where RouteID: Codable {}

/// A route that can be rendered by any platform shell or custom client.
public struct WorkspaceRouteDescriptor<RouteID: Hashable & Sendable>:
  Equatable,
  Identifiable,
  Sendable
{
  public var availability: WorkspaceAvailability
  public var badge: Int?
  public var id: RouteID
  public var isProminent: Bool
  public var keywords: [String]
  public var presentation: WorkspaceRoutePresentation
  public var scenePresentation: WorkspaceScenePresentation
  public var shortcut: WorkspaceKeyboardShortcut?
  public var subtitle: String?
  public var systemImage: String
  public var title: String

  public init(
    id: RouteID,
    title: String,
    systemImage: String,
    availability: WorkspaceAvailability = .available,
    subtitle: String? = nil,
    badge: Int? = nil,
    keywords: [String] = [],
    shortcut: WorkspaceKeyboardShortcut? = nil,
    isProminent: Bool = false,
    presentation: WorkspaceRoutePresentation = .listDetail,
    scenePresentation: WorkspaceScenePresentation = .primary
  ) {
    self.availability = availability
    self.badge = badge
    self.id = id
    self.isProminent = isProminent
    self.keywords = keywords
    self.presentation = presentation
    self.scenePresentation = scenePresentation
    self.shortcut = shortcut
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.title = title
  }
}

extension WorkspaceRouteDescriptor: Codable where RouteID: Codable {}

/// The app-owned source of truth for route sections and app commands.
public struct WorkspaceNavigationRegistry<RouteID: Hashable & Sendable>:
  Equatable,
  Sendable
{
  public var commands: [WorkspaceCommand<RouteID>]
  public var sections: [WorkspaceRouteSection<RouteID>]

  public init(
    sections: [WorkspaceRouteSection<RouteID>],
    commands: [WorkspaceCommand<RouteID>] = []
  ) {
    self.commands = commands
    self.sections = sections
  }

  public var routeCommands: [WorkspaceCommand<RouteID>] {
    sections.flatMap { section in
      section.routes.compactMap { route in
        guard route.availability.isVisible
        else { return nil }

        return WorkspaceCommand(
          id: .route(route.id),
          title: route.title,
          systemImage: route.systemImage,
          subtitle: route.subtitle,
          keywords: route.keywords,
          shortcut: route.shortcut,
          sectionTitle: section.title,
          source: .navigation,
          target: .route(route.id),
          isEnabled: route.availability.isEnabled,
          disabledReason: route.availability.disabledReason
        )
      }
    }
  }

  public var sceneCommands: [WorkspaceCommand<RouteID>] {
    sections.flatMap { section in
      section.routes.compactMap { route in
        guard route.availability.isVisible,
              route.scenePresentation.opensInSeparateScene
        else { return nil }

        return WorkspaceCommand(
          id: .scene(route.id),
          title: "Open \(route.title) in New Window",
          systemImage: route.scenePresentation.systemImage,
          subtitle: route.scenePresentation.title ?? route.subtitle,
          keywords: route.keywords + ["window", "scene", "open"],
          sectionTitle: section.title,
          source: .navigation,
          target: .scene(route.id),
          isEnabled: route.availability.isEnabled,
          disabledReason: route.availability.disabledReason
        )
      }
    }
  }
}

extension WorkspaceNavigationRegistry: Codable where RouteID: Codable {}
