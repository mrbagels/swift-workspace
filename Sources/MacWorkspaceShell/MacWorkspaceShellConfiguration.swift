#if os(macOS)
  import Foundation

  /// High-level macOS shell rendering style.
  public enum MacWorkspaceShellStyle: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case automatic
    case custom
    case nativeSplitView
  }

  /// macOS-specific renderer configuration.
  public struct MacWorkspaceShellConfiguration: Codable, Equatable, Sendable {
    public var commandPaletteWidth: Double
    public var detailMinimumWidth: Double
    public var searchPlaceholder: String
    public var sidebarIdealWidth: Double
    public var sidebarMaximumWidth: Double
    public var sidebarMinimumWidth: Double
    public var style: MacWorkspaceShellStyle
    public var title: String

    public init(
      title: String = "Workspace",
      style: MacWorkspaceShellStyle = .nativeSplitView,
      commandPaletteWidth: Double = 560,
      detailMinimumWidth: Double = 520,
      searchPlaceholder: String = "Search commands and routes",
      sidebarMinimumWidth: Double = 220,
      sidebarIdealWidth: Double = 268,
      sidebarMaximumWidth: Double = 380
    ) {
      self.commandPaletteWidth = commandPaletteWidth
      self.detailMinimumWidth = detailMinimumWidth
      self.searchPlaceholder = searchPlaceholder
      self.sidebarIdealWidth = sidebarIdealWidth
      self.sidebarMaximumWidth = sidebarMaximumWidth
      self.sidebarMinimumWidth = sidebarMinimumWidth
      self.style = style
      self.title = title
    }

    public static let `default` = Self()
  }
#endif
