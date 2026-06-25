#if os(macOS)
  import AppKit
  import Foundation
  import SwiftUI

  /// High-level macOS shell rendering style.
  public enum MacWorkspaceShellStyle: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case automatic
    case custom
    case nativeSplitView

    var resolved: Self {
      switch self {
      case .automatic:
        .custom
      case .custom, .nativeSplitView:
        self
      }
    }
  }

  /// Semantic tint used by shell navigation and brand marks.
  public enum MacWorkspaceTint: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case blue
    case green
    case indigo
    case orange
    case rose

    public var accent: Color {
      switch self {
      case .blue: Color(red: 0.14, green: 0.36, blue: 0.86)
      case .green: Color(red: 0.03, green: 0.48, blue: 0.32)
      case .indigo: Color(red: 0.26, green: 0.24, blue: 0.72)
      case .orange: Color(red: 0.78, green: 0.31, blue: 0.08)
      case .rose: Color(red: 0.72, green: 0.18, blue: 0.36)
      }
    }
  }

  /// The app identity shown in the shell sidebar titlebar region.
  public struct MacWorkspaceBrand: Codable, Equatable, Sendable {
    public var systemImage: String?
    public var tint: MacWorkspaceTint
    public var title: String

    public init(
      title: String = "Workspace",
      systemImage: String? = nil,
      tint: MacWorkspaceTint = .indigo
    ) {
      self.systemImage = systemImage
      self.tint = tint
      self.title = title
    }
  }

  /// Information density for Mac shell chrome.
  public enum MacWorkspaceDensity: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case compact
    case comfortable

    public var title: String {
      switch self {
      case .compact: "Compact"
      case .comfortable: "Comfortable"
      }
    }

    public var toggled: Self {
      self == .compact ? .comfortable : .compact
    }
  }

  /// Resolved dimensions for shell rows and compact controls at a given density.
  public struct MacWorkspaceDensityMetrics: Equatable, Sendable {
    public var badgeFont: CGFloat
    public var commandIconFont: CGFloat
    public var commandIconSize: CGFloat
    public var commandRowPaddingVertical: CGFloat
    public var commandRowSpacing: CGFloat
    public var commandSubtitleFont: CGFloat
    public var commandTitleFont: CGFloat
    public var emptyStateIconContainer: CGFloat
    public var emptyStateIconFont: CGFloat
    public var emptyStateTitleFont: CGFloat
    public var headerTitleFont: CGFloat
    public var keycapFont: CGFloat
    public var routeIconFont: CGFloat
    public var routeIconProminentFont: CGFloat
    public var routeIconProminentSize: CGFloat
    public var routeIconWidth: CGFloat
    public var rowCornerRadius: CGFloat
    public var rowPaddingHorizontal: CGFloat
    public var rowPaddingVertical: CGFloat
    public var rowSpacing: CGFloat
    public var rowTitleFont: CGFloat
    public var sectionHeaderFont: CGFloat

    public init(density: MacWorkspaceDensity) {
      switch density {
      case .compact:
        badgeFont = 11
        commandIconFont = 14
        commandIconSize = 22
        commandRowPaddingVertical = 9
        commandRowSpacing = 11
        commandSubtitleFont = 11
        commandTitleFont = 13
        emptyStateIconContainer = 38
        emptyStateIconFont = 18
        emptyStateTitleFont = 14
        headerTitleFont = 14
        keycapFont = 10
        routeIconFont = 13
        routeIconProminentFont = 11
        routeIconProminentSize = 18
        routeIconWidth = 18
        rowCornerRadius = 6
        rowPaddingHorizontal = 8
        rowPaddingVertical = 5
        rowSpacing = 8
        rowTitleFont = 13
        sectionHeaderFont = 10

      case .comfortable:
        badgeFont = 12
        commandIconFont = 16
        commandIconSize = 26
        commandRowPaddingVertical = 11
        commandRowSpacing = 13
        commandSubtitleFont = 12
        commandTitleFont = 14
        emptyStateIconContainer = 44
        emptyStateIconFont = 21
        emptyStateTitleFont = 15.5
        headerTitleFont = 15.5
        keycapFont = 11
        routeIconFont = 15
        routeIconProminentFont = 12.5
        routeIconProminentSize = 22
        routeIconWidth = 22
        rowCornerRadius = 7
        rowPaddingHorizontal = 10
        rowPaddingVertical = 7
        rowSpacing = 10
        rowTitleFont = 14
        sectionHeaderFont = 11
      }
    }

    public static let compact = Self(density: .compact)
  }

  private struct MacWorkspaceDensityKey: EnvironmentKey {
    static let defaultValue = MacWorkspaceDensity.compact
  }

  private struct MacWorkspaceDensityMetricsKey: EnvironmentKey {
    static let defaultValue = MacWorkspaceDensityMetrics.compact
  }

  public extension EnvironmentValues {
    var macWorkspaceDensity: MacWorkspaceDensity {
      get { self[MacWorkspaceDensityKey.self] }
      set { self[MacWorkspaceDensityKey.self] = newValue }
    }

    var macWorkspaceDensityMetrics: MacWorkspaceDensityMetrics {
      get { self[MacWorkspaceDensityMetricsKey.self] }
      set { self[MacWorkspaceDensityMetricsKey.self] = newValue }
    }
  }

  public extension View {
    func macWorkspaceDensity(_ density: MacWorkspaceDensity) -> some View {
      environment(\.macWorkspaceDensity, density)
        .environment(\.macWorkspaceDensityMetrics, MacWorkspaceDensityMetrics(density: density))
    }
  }

  /// Resizable shell columns.
  public enum MacWorkspaceColumn: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case detail
    case inspector
    case list
    case sidebar

    var accessibilityTitle: String {
      switch self {
      case .detail: "Detail"
      case .inspector: "Inspector"
      case .list: "List"
      case .sidebar: "Sidebar"
      }
    }
  }

  /// Min and max width constraints for a shell column.
  public struct MacWorkspaceColumnWidthRange: Codable, Equatable, Sendable {
    public var maximum: CGFloat
    public var minimum: CGFloat

    public init(minimum: CGFloat, maximum: CGFloat) {
      self.maximum = maximum
      self.minimum = minimum
    }
  }

  /// Layout metrics for the Mac workspace shell.
  public struct MacWorkspaceShellLayout: Codable, Equatable, Sendable {
    public var contentTopOffset: CGFloat
    public var defaultListWidth: CGFloat
    public var detailMinimumWidth: CGFloat
    public var dividerWidth: CGFloat
    public var headerHeight: CGFloat
    public var inspectorMaximumWidth: CGFloat
    public var inspectorMinimumWidth: CGFloat
    public var listMaximumWidth: CGFloat
    public var listMinimumWidth: CGFloat
    public var minimumWindowHeight: CGFloat
    public var sidebarMaximumWidth: CGFloat
    public var sidebarMinimumWidth: CGFloat
    public var sidebarWidth: CGFloat
    public var titlebarEdgePadding: CGFloat
    public var trafficLightSlotWidth: CGFloat

    public init(
      contentTopOffset: CGFloat = 36,
      defaultListWidth: CGFloat = 350,
      detailMinimumWidth: CGFloat = 560,
      dividerWidth: CGFloat = 1,
      headerHeight: CGFloat = 56,
      inspectorMaximumWidth: CGFloat = 520,
      inspectorMinimumWidth: CGFloat = 260,
      listMaximumWidth: CGFloat = 520,
      listMinimumWidth: CGFloat = 260,
      minimumWindowHeight: CGFloat = 680,
      sidebarMaximumWidth: CGFloat = 380,
      sidebarMinimumWidth: CGFloat = 220,
      sidebarWidth: CGFloat = 276,
      titlebarEdgePadding: CGFloat = 20,
      trafficLightSlotWidth: CGFloat = 104
    ) {
      self.contentTopOffset = contentTopOffset
      self.defaultListWidth = defaultListWidth
      self.detailMinimumWidth = detailMinimumWidth
      self.dividerWidth = dividerWidth
      self.headerHeight = headerHeight
      self.inspectorMaximumWidth = inspectorMaximumWidth
      self.inspectorMinimumWidth = inspectorMinimumWidth
      self.listMaximumWidth = listMaximumWidth
      self.listMinimumWidth = listMinimumWidth
      self.minimumWindowHeight = minimumWindowHeight
      self.sidebarMaximumWidth = sidebarMaximumWidth
      self.sidebarMinimumWidth = sidebarMinimumWidth
      self.sidebarWidth = sidebarWidth
      self.titlebarEdgePadding = titlebarEdgePadding
      self.trafficLightSlotWidth = trafficLightSlotWidth
    }

    public static let `default` = Self()

    public var minimumContentWidth: CGFloat {
      defaultListWidth + detailMinimumWidth + dividerWidth
    }

    public var preferredWindowSize: CGSize {
      CGSize(width: 1180, height: 820)
    }

    public func minimumContentWidth(for columnWidths: MacWorkspaceColumnWidths) -> CGFloat {
      resolvedWidth(for: .list, columnWidths: columnWidths)
        + resolvedWidth(for: .detail, columnWidths: columnWidths)
        + dividerWidth
    }

    public func resolvedWidth(
      for column: MacWorkspaceColumn,
      columnWidths: MacWorkspaceColumnWidths
    ) -> CGFloat {
      clampedWidth(columnWidths[column] ?? defaultWidth(for: column), for: column)
    }

    public func clampedWidth(_ width: CGFloat, for column: MacWorkspaceColumn) -> CGFloat {
      guard width.isFinite
      else { return defaultWidth(for: column) }

      let range = widthRange(for: column)
      return min(max(width, range.minimum), range.maximum)
    }

    public func defaultWidth(for column: MacWorkspaceColumn) -> CGFloat {
      switch column {
      case .detail:
        detailMinimumWidth
      case .inspector:
        inspectorMinimumWidth
      case .list:
        defaultListWidth
      case .sidebar:
        sidebarWidth
      }
    }

    public func widthRange(for column: MacWorkspaceColumn) -> MacWorkspaceColumnWidthRange {
      switch column {
      case .detail:
        MacWorkspaceColumnWidthRange(minimum: detailMinimumWidth, maximum: 1_200)
      case .inspector:
        MacWorkspaceColumnWidthRange(minimum: inspectorMinimumWidth, maximum: inspectorMaximumWidth)
      case .list:
        MacWorkspaceColumnWidthRange(minimum: listMinimumWidth, maximum: listMaximumWidth)
      case .sidebar:
        MacWorkspaceColumnWidthRange(minimum: sidebarMinimumWidth, maximum: sidebarMaximumWidth)
      }
    }
  }

  /// View behavior knobs for transitions and command palette sizing.
  public struct MacWorkspaceShellBehavior: Codable, Equatable, Sendable {
    public var animatesCommandPalettePresentation: Bool
    public var animatesSidebarVisibility: Bool
    public var commandPaletteResultsMaximumHeight: CGFloat
    public var commandPaletteTopPadding: CGFloat
    public var commandPaletteWidth: CGFloat

    public init(
      animatesCommandPalettePresentation: Bool = true,
      animatesSidebarVisibility: Bool = true,
      commandPaletteResultsMaximumHeight: CGFloat = 380,
      commandPaletteTopPadding: CGFloat = 88,
      commandPaletteWidth: CGFloat = 520
    ) {
      self.animatesCommandPalettePresentation = animatesCommandPalettePresentation
      self.animatesSidebarVisibility = animatesSidebarVisibility
      self.commandPaletteResultsMaximumHeight = commandPaletteResultsMaximumHeight
      self.commandPaletteTopPadding = commandPaletteTopPadding
      self.commandPaletteWidth = commandPaletteWidth
    }

    public static let `default` = Self()
  }

  /// Colors used by the Mac workspace shell.
  public struct MacWorkspaceShellTheme: @unchecked Sendable {
    public var canvas: Color
    public var commandPaletteScrim: Color
    public var divider: Color
    public var fill: Color
    public var fillRaised: Color
    public var hover: Color
    public var mutedText: Color
    public var primaryControlBackground: Color
    public var primaryControlForeground: Color
    public var primaryControlHoverOverlay: Color
    public var selection: Color
    public var strongText: Color
    public var subtleText: Color

    public init(
      canvas: Color = Color(nsColor: .windowBackgroundColor),
      commandPaletteScrim: Color = Color.black.opacity(0.16),
      divider: Color = Color(nsColor: .separatorColor).opacity(0.55),
      fill: Color = Color(nsColor: .controlBackgroundColor),
      fillRaised: Color = Color(nsColor: .textBackgroundColor),
      hover: Color = Color(nsColor: .selectedContentBackgroundColor).opacity(0.09),
      mutedText: Color = Color(nsColor: .secondaryLabelColor),
      primaryControlBackground: Color = Color.accentColor,
      primaryControlForeground: Color = .white,
      primaryControlHoverOverlay: Color = Color.black.opacity(0.08),
      selection: Color = Color(nsColor: .selectedContentBackgroundColor).opacity(0.12),
      strongText: Color = Color(nsColor: .labelColor),
      subtleText: Color = Color(nsColor: .tertiaryLabelColor)
    ) {
      self.canvas = canvas
      self.commandPaletteScrim = commandPaletteScrim
      self.divider = divider
      self.fill = fill
      self.fillRaised = fillRaised
      self.hover = hover
      self.mutedText = mutedText
      self.primaryControlBackground = primaryControlBackground
      self.primaryControlForeground = primaryControlForeground
      self.primaryControlHoverOverlay = primaryControlHoverOverlay
      self.selection = selection
      self.strongText = strongText
      self.subtleText = subtleText
    }

    public static let system = Self()
  }

  /// macOS-specific renderer configuration.
  public struct MacWorkspaceShellConfiguration: Sendable {
    public var behavior: MacWorkspaceShellBehavior
    public var brand: MacWorkspaceBrand
    public var layout: MacWorkspaceShellLayout
    public var searchPlaceholder: String
    public var style: MacWorkspaceShellStyle
    public var theme: MacWorkspaceShellTheme

    public var commandPaletteWidth: Double {
      get { Double(behavior.commandPaletteWidth) }
      set { behavior.commandPaletteWidth = CGFloat(newValue) }
    }

    public var detailMinimumWidth: Double {
      get { Double(layout.detailMinimumWidth) }
      set { layout.detailMinimumWidth = CGFloat(newValue) }
    }

    public var sidebarIdealWidth: Double {
      get { Double(layout.sidebarWidth) }
      set { layout.sidebarWidth = CGFloat(newValue) }
    }

    public var sidebarMaximumWidth: Double {
      get { Double(layout.sidebarMaximumWidth) }
      set { layout.sidebarMaximumWidth = CGFloat(newValue) }
    }

    public var sidebarMinimumWidth: Double {
      get { Double(layout.sidebarMinimumWidth) }
      set { layout.sidebarMinimumWidth = CGFloat(newValue) }
    }

    public var title: String {
      get { brand.title }
      set { brand.title = newValue }
    }

    public init(
      brand: MacWorkspaceBrand = .init(),
      style: MacWorkspaceShellStyle = .custom,
      layout: MacWorkspaceShellLayout = .default,
      theme: MacWorkspaceShellTheme = .system,
      behavior: MacWorkspaceShellBehavior = .default,
      searchPlaceholder: String = "Search"
    ) {
      self.behavior = behavior
      self.brand = brand
      self.layout = layout
      self.searchPlaceholder = searchPlaceholder
      self.style = style
      self.theme = theme
    }

    public init(
      title: String = "Workspace",
      style: MacWorkspaceShellStyle = .custom,
      commandPaletteWidth: Double = 560,
      detailMinimumWidth: Double = 520,
      searchPlaceholder: String = "Search commands and routes",
      sidebarMinimumWidth: Double = 220,
      sidebarIdealWidth: Double = 268,
      sidebarMaximumWidth: Double = 380,
      brandSystemImage: String? = nil,
      brandTint: MacWorkspaceTint = .indigo,
      theme: MacWorkspaceShellTheme = .system
    ) {
      var layout = MacWorkspaceShellLayout.default
      layout.detailMinimumWidth = CGFloat(detailMinimumWidth)
      layout.sidebarMinimumWidth = CGFloat(sidebarMinimumWidth)
      layout.sidebarWidth = CGFloat(sidebarIdealWidth)
      layout.sidebarMaximumWidth = CGFloat(sidebarMaximumWidth)

      var behavior = MacWorkspaceShellBehavior.default
      behavior.commandPaletteWidth = CGFloat(commandPaletteWidth)

      self.behavior = behavior
      self.brand = MacWorkspaceBrand(
        title: title,
        systemImage: brandSystemImage,
        tint: brandTint
      )
      self.layout = layout
      self.searchPlaceholder = searchPlaceholder
      self.style = style
      self.theme = theme
    }

    public static let `default` = Self(brand: .init())
    public static let nativeSplitView = Self(brand: .init(), style: .nativeSplitView)
    public static let custom = Self(brand: .init(), style: .custom)
  }
#endif
