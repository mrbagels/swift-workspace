#if os(macOS)
  import CoreGraphics
  import Foundation
  import WorkspaceCore

  /// Restorable macOS column widths layered around shared workspace restoration.
  public struct MacWorkspaceColumnWidths: Codable, Equatable, Sendable {
    public var detail: CGFloat?
    public var inspector: CGFloat?
    public var list: CGFloat?
    public var sidebar: CGFloat?

    public init(
      sidebar: CGFloat? = nil,
      list: CGFloat? = nil,
      detail: CGFloat? = nil,
      inspector: CGFloat? = nil
    ) {
      self.detail = Self.sanitized(detail)
      self.inspector = Self.sanitized(inspector)
      self.list = Self.sanitized(list)
      self.sidebar = Self.sanitized(sidebar)
    }

    public var sanitized: Self {
      Self(
        sidebar: sidebar,
        list: list,
        detail: detail,
        inspector: inspector
      )
    }

    public subscript(column: MacWorkspaceColumn) -> CGFloat? {
      get {
        switch column {
        case .detail:
          detail
        case .inspector:
          inspector
        case .list:
          list
        case .sidebar:
          sidebar
        }
      }
      set {
        switch column {
        case .detail:
          detail = Self.sanitized(newValue)
        case .inspector:
          inspector = Self.sanitized(newValue)
        case .list:
          list = Self.sanitized(newValue)
        case .sidebar:
          sidebar = Self.sanitized(newValue)
        }
      }
    }

    private static func sanitized(_ width: CGFloat?) -> CGFloat? {
      guard let width, width.isFinite, width > 0
      else { return nil }
      return width
    }
  }

  /// macOS chrome restoration composed with shared engine restoration.
  public struct MacWorkspaceRestoration<RouteID: Hashable & Sendable>: Equatable, Sendable {
    public var columnWidths: MacWorkspaceColumnWidths
    public var density: MacWorkspaceDensity
    public var isInspectorPresented: Bool
    public var isSidebarVisible: Bool
    public var style: MacWorkspaceShellStyle
    public var workspace: WorkspaceRestoration<RouteID>

    public init(
      workspace: WorkspaceRestoration<RouteID>,
      isSidebarVisible: Bool = true,
      isInspectorPresented: Bool = false,
      columnWidths: MacWorkspaceColumnWidths = .init(),
      density: MacWorkspaceDensity = .compact,
      style: MacWorkspaceShellStyle = .nativeSplitView
    ) {
      self.columnWidths = columnWidths.sanitized
      self.density = density
      self.isInspectorPresented = isInspectorPresented
      self.isSidebarVisible = isSidebarVisible
      self.style = style
      self.workspace = workspace
    }
  }

  extension MacWorkspaceRestoration: Codable where RouteID: Codable {}
#endif
