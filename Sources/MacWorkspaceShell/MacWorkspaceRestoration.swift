#if os(macOS)
  import Foundation
  import WorkspaceCore

  /// Restorable macOS column widths layered around shared workspace restoration.
  public struct MacWorkspaceColumnWidths: Codable, Equatable, Sendable {
    public var detail: Double?
    public var inspector: Double?
    public var sidebar: Double?

    public init(
      sidebar: Double? = nil,
      detail: Double? = nil,
      inspector: Double? = nil
    ) {
      self.detail = Self.sanitized(detail)
      self.inspector = Self.sanitized(inspector)
      self.sidebar = Self.sanitized(sidebar)
    }

    public var sanitized: Self {
      Self(
        sidebar: sidebar,
        detail: detail,
        inspector: inspector
      )
    }

    private static func sanitized(_ width: Double?) -> Double? {
      guard let width, width.isFinite, width > 0
      else { return nil }
      return width
    }
  }

  /// macOS chrome restoration composed with shared engine restoration.
  public struct MacWorkspaceRestoration<RouteID: Hashable & Sendable>: Equatable, Sendable {
    public var columnWidths: MacWorkspaceColumnWidths
    public var isInspectorPresented: Bool
    public var isSidebarVisible: Bool
    public var style: MacWorkspaceShellStyle
    public var workspace: WorkspaceRestoration<RouteID>

    public init(
      workspace: WorkspaceRestoration<RouteID>,
      isSidebarVisible: Bool = true,
      isInspectorPresented: Bool = false,
      columnWidths: MacWorkspaceColumnWidths = .init(),
      style: MacWorkspaceShellStyle = .nativeSplitView
    ) {
      self.columnWidths = columnWidths.sanitized
      self.isInspectorPresented = isInspectorPresented
      self.isSidebarVisible = isSidebarVisible
      self.style = style
      self.workspace = workspace
    }
  }

  extension MacWorkspaceRestoration: Codable where RouteID: Codable {}
#endif
