#if os(macOS)
  import AppKit
  import ComposableArchitecture
  import SwiftUI
  import WorkspaceCore
  import WorkspaceTCA

  /// Reusable macOS workspace shell view for TCA-backed applications.
  public struct MacWorkspaceShellView<
    RouteID: Hashable & Sendable,
    ListContent: View,
    DetailContent: View,
    FullWidthContent: View,
    HeaderLeadingContent: View,
    HeaderCenterContent: View,
    HeaderTrailingContent: View,
    InspectorContent: View,
    SidebarFooterContent: View
  >: View {
    @Bindable public var store: StoreOf<WorkspaceFeature<RouteID>>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var columnWidths: MacWorkspaceColumnWidths
    @State private var density: MacWorkspaceDensity
    @State private var isInspectorPresented: Bool
    @State private var isSidebarVisible: Bool

    private let configuration: MacWorkspaceShellConfiguration
    private let detailContent: (WorkspaceRouteDescriptor<RouteID>) -> DetailContent
    private let fullWidthContent: (WorkspaceRouteDescriptor<RouteID>) -> FullWidthContent
    private let hasInspector: Bool
    private let headerCenterContent: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderCenterContent
    private let headerLeadingContent: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderLeadingContent
    private let headerTrailingContent: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderTrailingContent
    private let inspectorContent: (WorkspaceRouteDescriptor<RouteID>?) -> InspectorContent
    private let listContent: (WorkspaceRouteDescriptor<RouteID>) -> ListContent
    private let prefersSinglePaneContent: Bool
    private let sidebarFooterContent: () -> SidebarFooterContent

    /// Creates a shell view with custom header, inspector, sidebar, list, detail, and full-width slots.
    public init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: MacWorkspaceShellConfiguration = .default,
      restoration: MacWorkspaceRestoration<RouteID>? = nil,
      @ViewBuilder headerLeading: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderLeadingContent,
      @ViewBuilder headerCenter: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderCenterContent,
      @ViewBuilder headerTrailing: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderTrailingContent,
      @ViewBuilder inspector: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> InspectorContent,
      @ViewBuilder sidebarFooter: @escaping () -> SidebarFooterContent,
      @ViewBuilder list: @escaping (WorkspaceRouteDescriptor<RouteID>) -> ListContent,
      @ViewBuilder detail: @escaping (WorkspaceRouteDescriptor<RouteID>) -> DetailContent,
      @ViewBuilder fullWidth: @escaping (WorkspaceRouteDescriptor<RouteID>) -> FullWidthContent
    ) {
      self.store = store
      self.configuration = configuration
      self.detailContent = detail
      self.fullWidthContent = fullWidth
      self.hasInspector = true
      self.headerCenterContent = headerCenter
      self.headerLeadingContent = headerLeading
      self.headerTrailingContent = headerTrailing
      self.inspectorContent = inspector
      self.listContent = list
      self.prefersSinglePaneContent = false
      self.sidebarFooterContent = sidebarFooter
      _columnWidths = State(initialValue: restoration?.columnWidths ?? .init())
      _density = State(initialValue: restoration?.density ?? .compact)
      _isInspectorPresented = State(initialValue: restoration?.isInspectorPresented ?? false)
      _isSidebarVisible = State(initialValue: restoration?.isSidebarVisible ?? true)
    }

    public var body: some View {
      ZStack {
        shellContent
          .id(style)
          .transaction { transaction in
            transaction.animation = nil
          }

        if store.isCommandPalettePresented {
          MacWorkspaceCommandPalette(
            store: store,
            behavior: configuration.behavior,
            layout: configuration.layout,
            searchPlaceholder: configuration.searchPlaceholder,
            theme: configuration.theme
          )
          .transition(commandPaletteTransition)
          .zIndex(2)
        }
      }
      .background(
        MacWorkspaceTitlebarConfigurator(
          layout: configuration.layout,
          style: style
        )
        .id(style)
      )
      .macWorkspaceDensity(density)
    }

    /// The default preferred size for host windows that render the shell.
    public static var preferredWindowSize: CGSize {
      MacWorkspaceShellLayout.default.preferredWindowSize
    }

    private var style: MacWorkspaceShellStyle {
      configuration.style.resolved
    }

    @ViewBuilder
    private var shellContent: some View {
      switch style {
      case .automatic:
        nativeSplitShell
      case .custom:
        workspaceColumns
          .ignoresSafeArea(.container, edges: .top)
      case .nativeSplitView:
        nativeSplitShell
      }
    }

    private var workspaceColumns: some View {
      GeometryReader { geometry in
        let metrics = customMetrics(for: geometry.size)
        HStack(spacing: 0) {
          if isSidebarVisible {
            MacWorkspaceSidebar(
              store: store,
              brand: configuration.brand,
              footer: sidebarFooterContent,
              layout: configuration.layout,
              searchPlaceholder: configuration.searchPlaceholder,
              theme: configuration.theme
            )
            .frame(width: metrics.sidebarColumnWidth)
            .frame(maxHeight: .infinity)
            .clipped()
            .transition(sidebarTransition)

            MacWorkspaceResizeDivider(
              column: .sidebar,
              currentWidth: metrics.sidebarColumnWidth,
              layout: configuration.layout,
              theme: configuration.theme
            ) { width in
              columnWidths[.sidebar] = width
            } onReset: {
              columnWidths[.sidebar] = nil
            }
          }

          contentRegion(
            width: metrics.contentWidth,
            isNativeStyle: false
          )
          .frame(width: metrics.contentWidth)
          .frame(maxHeight: .infinity)
          .clipped()
          .layoutPriority(1)
        }
        .animation(shellAnimation, value: isSidebarVisible)
        .frame(width: metrics.width, height: metrics.height, alignment: .leading)
      }
      .frame(
        minWidth: minimumWindowWidth,
        idealWidth: max(minimumWindowWidth, Self.preferredWindowSize.width),
        minHeight: configuration.layout.minimumWindowHeight,
        idealHeight: max(configuration.layout.minimumWindowHeight, Self.preferredWindowSize.height)
      )
      .background(configuration.theme.canvas.ignoresSafeArea())
    }

    private var nativeSplitShell: some View {
      GeometryReader { geometry in
        let metrics = nativeMetrics(for: geometry.size)
        HStack(spacing: 0) {
          if isSidebarVisible {
            nativeSidebar(width: metrics.sidebarColumnWidth)
              .frame(width: metrics.sidebarOuterWidth)
              .transition(sidebarTransition)
          }

          contentRegion(
            width: metrics.contentWidth,
            isNativeStyle: true
          )
          .frame(width: metrics.contentWidth)
          .frame(maxHeight: .infinity)
          .clipped()
          .layoutPriority(1)
        }
        .animation(shellAnimation, value: isSidebarVisible)
        .frame(width: metrics.width, height: metrics.height, alignment: .leading)
      }
      .frame(
        minWidth: minimumWindowWidth,
        idealWidth: max(minimumWindowWidth, Self.preferredWindowSize.width),
        minHeight: configuration.layout.minimumWindowHeight,
        idealHeight: max(configuration.layout.minimumWindowHeight, Self.preferredWindowSize.height)
      )
      .background(Color(nsColor: .windowBackgroundColor).ignoresSafeArea())
      .ignoresSafeArea(.container, edges: .top)
    }

    private func nativeSidebar(width: CGFloat) -> some View {
      MacWorkspaceSidebar(
        store: store,
        brand: configuration.brand,
        footer: sidebarFooterContent,
        reservesFooterSpace: false,
        layout: configuration.layout,
        searchPlaceholder: configuration.searchPlaceholder,
        theme: configuration.theme
      )
      .frame(width: width)
      .frame(maxHeight: .infinity)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: NativeMetrics.sidebarCornerRadius, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: NativeMetrics.sidebarCornerRadius, style: .continuous)
          .stroke(configuration.theme.divider, lineWidth: 1)
      }
      .padding(.leading, NativeMetrics.sidebarLeadingInset)
      .padding(.trailing, NativeMetrics.sidebarTrailingInset)
      .padding(.vertical, NativeMetrics.sidebarVerticalInset)
    }

    private func contentRegion(
      width: CGFloat,
      isNativeStyle: Bool
    ) -> some View {
      MacWorkspaceContentRegion(
        store: store,
        columnWidths: $columnWidths,
        hasInspector: hasInspector,
        headerCenter: headerCenterContent,
        headerLeading: headerLeadingContent,
        headerTrailing: headerTrailingContent,
        inspector: inspectorContent,
        isInspectorPresented: $isInspectorPresented,
        isNativeStyle: isNativeStyle,
        isSidebarVisible: $isSidebarVisible,
        layout: configuration.layout,
        list: listContent,
        prefersSinglePaneContent: prefersSinglePaneContent,
        theme: configuration.theme,
        width: width,
        detail: detailContent,
        fullWidth: fullWidthContent
      )
    }

    private var minimumWindowWidth: CGFloat {
      let layout = configuration.layout
      let inspectorFootprint = hasInspector && isInspectorPresented
        ? layout.resolvedWidth(for: .inspector, columnWidths: columnWidths) + layout.dividerWidth
        : 0
      let sidebarWidth = layout.resolvedWidth(for: .sidebar, columnWidths: columnWidths)
      let sidebarFootprint = isSidebarVisible
        ? sidebarWidth + (style == .nativeSplitView ? NativeMetrics.sidebarHorizontalFootprint : layout.dividerWidth)
        : 0
      return sidebarFootprint + layout.minimumContentWidth(for: columnWidths) + inspectorFootprint
    }

    private func customMetrics(for size: CGSize) -> ShellMetrics {
      let layout = configuration.layout
      let inspectorFootprint = hasInspector && isInspectorPresented
        ? layout.resolvedWidth(for: .inspector, columnWidths: columnWidths) + layout.dividerWidth
        : 0
      let minimumContentWidth = layout.minimumContentWidth(for: columnWidths) + inspectorFootprint
      let sidebarColumnWidth = layout.resolvedWidth(for: .sidebar, columnWidths: columnWidths)
      let sidebarOuterWidth = isSidebarVisible ? sidebarColumnWidth + layout.dividerWidth : 0
      let width = stableDimension(
        max(size.width, sidebarOuterWidth + minimumContentWidth),
        fallback: sidebarOuterWidth + minimumContentWidth
      )
      let height = stableDimension(size.height, fallback: layout.minimumWindowHeight)
      let contentWidth = stableDimension(width - sidebarOuterWidth, fallback: minimumContentWidth)

      return ShellMetrics(
        contentWidth: contentWidth,
        height: height,
        sidebarColumnWidth: sidebarColumnWidth,
        sidebarOuterWidth: sidebarOuterWidth,
        width: width
      )
    }

    private func nativeMetrics(for size: CGSize) -> ShellMetrics {
      let layout = configuration.layout
      let inspectorFootprint = hasInspector && isInspectorPresented
        ? layout.resolvedWidth(for: .inspector, columnWidths: columnWidths) + layout.dividerWidth
        : 0
      let minimumContentWidth = layout.minimumContentWidth(for: columnWidths) + inspectorFootprint
      let sidebarColumnWidth = layout.resolvedWidth(for: .sidebar, columnWidths: columnWidths)
      let sidebarOuterWidth = isSidebarVisible
        ? sidebarColumnWidth + NativeMetrics.sidebarHorizontalFootprint
        : 0
      let width = stableDimension(
        max(size.width, sidebarOuterWidth + minimumContentWidth),
        fallback: sidebarOuterWidth + minimumContentWidth
      )
      let height = stableDimension(size.height, fallback: layout.minimumWindowHeight)
      let contentWidth = stableDimension(width - sidebarOuterWidth, fallback: minimumContentWidth)

      return ShellMetrics(
        contentWidth: contentWidth,
        height: height,
        sidebarColumnWidth: sidebarColumnWidth,
        sidebarOuterWidth: sidebarOuterWidth,
        width: width
      )
    }

    private var commandPaletteTransition: AnyTransition {
      guard configuration.behavior.animatesCommandPalettePresentation
      else { return .identity }
      return reduceMotion
        ? .identity
        : .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
    }

    private var shellAnimation: Animation? {
      guard configuration.behavior.animatesSidebarVisibility
      else { return nil }
      return reduceMotion ? nil : .easeOut(duration: 0.18)
    }

    private var sidebarTransition: AnyTransition {
      reduceMotion ? .identity : .move(edge: .leading).combined(with: .opacity)
    }

    private func stableDimension(
      _ value: CGFloat,
      fallback: CGFloat
    ) -> CGFloat {
      guard value.isFinite, value > 0
      else { return max(1, fallback) }
      return value
    }
  }

  public extension MacWorkspaceShellView
  where
    HeaderLeadingContent == EmptyView,
    HeaderCenterContent == EmptyView,
    HeaderTrailingContent == EmptyView
  {
    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: MacWorkspaceShellConfiguration = .default,
      restoration: MacWorkspaceRestoration<RouteID>? = nil,
      @ViewBuilder inspector: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> InspectorContent,
      @ViewBuilder sidebarFooter: @escaping () -> SidebarFooterContent,
      @ViewBuilder list: @escaping (WorkspaceRouteDescriptor<RouteID>) -> ListContent,
      @ViewBuilder detail: @escaping (WorkspaceRouteDescriptor<RouteID>) -> DetailContent,
      @ViewBuilder fullWidth: @escaping (WorkspaceRouteDescriptor<RouteID>) -> FullWidthContent
    ) {
      self.init(
        store: store,
        configuration: configuration,
        restoration: restoration,
        headerLeading: { _ in EmptyView() },
        headerCenter: { _ in EmptyView() },
        headerTrailing: { _ in EmptyView() },
        inspector: inspector,
        sidebarFooter: sidebarFooter,
        list: list,
        detail: detail,
        fullWidth: fullWidth
      )
    }
  }

  public extension MacWorkspaceShellView
  where
    HeaderLeadingContent == EmptyView,
    HeaderCenterContent == EmptyView,
    HeaderTrailingContent == EmptyView,
    InspectorContent == EmptyView,
    SidebarFooterContent == EmptyView
  {
    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: MacWorkspaceShellConfiguration = .default,
      restoration: MacWorkspaceRestoration<RouteID>? = nil,
      @ViewBuilder list: @escaping (WorkspaceRouteDescriptor<RouteID>) -> ListContent,
      @ViewBuilder detail: @escaping (WorkspaceRouteDescriptor<RouteID>) -> DetailContent,
      @ViewBuilder fullWidth: @escaping (WorkspaceRouteDescriptor<RouteID>) -> FullWidthContent
    ) {
      self.init(
        store: store,
        configuration: configuration,
        restoration: restoration,
        headerLeading: { _ in EmptyView() },
        headerCenter: { _ in EmptyView() },
        headerTrailing: { _ in EmptyView() },
        inspector: { _ in EmptyView() },
        sidebarFooter: { EmptyView() },
        list: list,
        detail: detail,
        fullWidth: fullWidth,
        hasInspector: false,
        prefersSinglePaneContent: false
      )
    }
  }

  public extension MacWorkspaceShellView
  where
    ListContent == EmptyView,
    DetailContent == FullWidthContent,
    HeaderLeadingContent == EmptyView,
    HeaderCenterContent == EmptyView,
    HeaderTrailingContent == EmptyView,
    InspectorContent == EmptyView
  {
    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: MacWorkspaceShellConfiguration = .default,
      restoration: MacWorkspaceRestoration<RouteID>? = nil,
      @ViewBuilder sidebarFooter: @escaping () -> SidebarFooterContent,
      @ViewBuilder content: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> DetailContent
    ) {
      self.init(
        store: store,
        configuration: configuration,
        restoration: restoration,
        headerLeading: { _ in EmptyView() },
        headerCenter: { _ in EmptyView() },
        headerTrailing: { _ in EmptyView() },
        inspector: { _ in EmptyView() },
        sidebarFooter: sidebarFooter,
        list: { _ in EmptyView() },
        detail: { route in content(route) },
        fullWidth: { route in content(route) },
        hasInspector: false,
        prefersSinglePaneContent: true
      )
    }
  }

  public extension MacWorkspaceShellView
  where
    ListContent == EmptyView,
    DetailContent == FullWidthContent,
    HeaderLeadingContent == EmptyView,
    HeaderCenterContent == EmptyView,
    HeaderTrailingContent == EmptyView,
    InspectorContent == EmptyView,
    SidebarFooterContent == EmptyView
  {
    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: MacWorkspaceShellConfiguration = .default,
      restoration: MacWorkspaceRestoration<RouteID>? = nil,
      @ViewBuilder content: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> DetailContent
    ) {
      self.init(
        store: store,
        configuration: configuration,
        restoration: restoration,
        sidebarFooter: { EmptyView() },
        content: content
      )
    }
  }

  private extension MacWorkspaceShellView {
    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      configuration: MacWorkspaceShellConfiguration,
      restoration: MacWorkspaceRestoration<RouteID>?,
      @ViewBuilder headerLeading: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderLeadingContent,
      @ViewBuilder headerCenter: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderCenterContent,
      @ViewBuilder headerTrailing: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderTrailingContent,
      @ViewBuilder inspector: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> InspectorContent,
      @ViewBuilder sidebarFooter: @escaping () -> SidebarFooterContent,
      @ViewBuilder list: @escaping (WorkspaceRouteDescriptor<RouteID>) -> ListContent,
      @ViewBuilder detail: @escaping (WorkspaceRouteDescriptor<RouteID>) -> DetailContent,
      @ViewBuilder fullWidth: @escaping (WorkspaceRouteDescriptor<RouteID>) -> FullWidthContent,
      hasInspector: Bool,
      prefersSinglePaneContent: Bool
    ) {
      self.store = store
      self.configuration = configuration
      self.detailContent = detail
      self.fullWidthContent = fullWidth
      self.hasInspector = hasInspector
      self.headerCenterContent = headerCenter
      self.headerLeadingContent = headerLeading
      self.headerTrailingContent = headerTrailing
      self.inspectorContent = inspector
      self.listContent = list
      self.prefersSinglePaneContent = prefersSinglePaneContent
      self.sidebarFooterContent = sidebarFooter
      _columnWidths = State(initialValue: restoration?.columnWidths ?? .init())
      _density = State(initialValue: restoration?.density ?? .compact)
      _isInspectorPresented = State(initialValue: hasInspector && (restoration?.isInspectorPresented ?? false))
      _isSidebarVisible = State(initialValue: restoration?.isSidebarVisible ?? true)
    }
  }

  private struct MacWorkspaceSidebar<RouteID: Hashable & Sendable, FooterContent: View>: View {
    @Bindable var store: StoreOf<WorkspaceFeature<RouteID>>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFullScreen = false
    @State private var isSearchHovered = false

    let brand: MacWorkspaceBrand
    let footer: () -> FooterContent
    let layout: MacWorkspaceShellLayout
    let reservesFooterSpace: Bool
    let searchPlaceholder: String
    let theme: MacWorkspaceShellTheme

    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      brand: MacWorkspaceBrand,
      @ViewBuilder footer: @escaping () -> FooterContent,
      reservesFooterSpace: Bool = true,
      layout: MacWorkspaceShellLayout,
      searchPlaceholder: String,
      theme: MacWorkspaceShellTheme
    ) {
      self.store = store
      self.brand = brand
      self.footer = footer
      self.layout = layout
      self.reservesFooterSpace = reservesFooterSpace
      self.searchPlaceholder = searchPlaceholder
      self.theme = theme
    }

    var body: some View {
      VStack(spacing: 0) {
        sidebarHeader

        ScrollView(.vertical, showsIndicators: false) {
          VStack(alignment: .leading, spacing: 18) {
            ForEach(store.visibleSections) { section in
              MacWorkspaceSidebarSectionView(
                isExpanded: !section.isCollapsible || !store.collapsedSectionIDs.contains(section.id),
                section: section,
                selectedRouteID: store.selectedRouteID,
                theme: theme,
                tint: brand.tint
              ) { id in
                store.send(.routeSelected(id))
              } onToggleExpansion: { sectionID in
                store.send(.sectionDisclosureButtonTapped(sectionID))
              } onOpenScene: { id in
                store.send(.sceneRequested(id))
              }
            }
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        if reservesFooterSpace {
          footer()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
      }
      .background(theme.canvas)
      .onAppear { syncFullScreenState() }
      .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
        withAnimation(fullScreenAnimation) { isFullScreen = true }
      }
      .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
        withAnimation(fullScreenAnimation) { isFullScreen = false }
      }
    }

    private var sidebarHeader: some View {
      VStack(alignment: .leading, spacing: 0) {
        titlebarRow

        Button {
          store.send(.commandPaletteRequested)
        } label: {
          HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 12, weight: .regular))
              .foregroundStyle(theme.mutedText)
            Text(searchPlaceholder)
              .font(.system(size: 12))
              .foregroundStyle(theme.mutedText)
              .lineLimit(1)
            Spacer(minLength: 0)
            MacWorkspaceKeycap(WorkspaceKeyboardShortcut.commandPalette.displayLabel, theme: theme)
          }
          .padding(.horizontal, 9)
          .padding(.vertical, 6)
          .frame(maxWidth: .infinity)
          .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
              .fill(theme.fillRaised.opacity(isSearchHovered ? 1 : 0.78))
              .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                  .stroke(theme.divider, lineWidth: 1)
                  .opacity(isSearchHovered ? 0.9 : 0.5)
              }
          )
        }
        .buttonStyle(.plain)
        .onHover { isSearchHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isSearchHovered)
        .macWorkspaceKeyboardShortcut(.commandPalette)
        .accessibilityLabel("Open Command Palette")
        .accessibilityHint("Search commands and routes")
        .padding(.horizontal, 12)
        .padding(.top, layout.contentTopOffset - 8)
      }
      .padding(.bottom, 6)
    }

    private var titlebarRow: some View {
      HStack(spacing: 0) {
        Color.clear.frame(width: isFullScreen ? 0 : layout.trafficLightSlotWidth)

        Spacer(minLength: 0)

        HStack(spacing: 7) {
          if let systemImage = brand.systemImage {
            Image(systemName: systemImage)
              .font(.system(size: 13, weight: .bold))
              .foregroundStyle(Color.white)
              .frame(width: 20, height: 20)
              .background(brand.tint.accent, in: Circle())
          } else {
            Circle()
              .fill(brand.tint.accent)
              .frame(width: 8, height: 8)
          }

          Text(brand.title)
            .font(.system(size: 18.5, weight: .semibold))
            .foregroundStyle(theme.strongText)
            .lineLimit(1)
        }
        .padding(.trailing, layout.titlebarEdgePadding)
        .padding(.leading, isFullScreen ? layout.titlebarEdgePadding : 0)
        .frame(maxWidth: .infinity, alignment: isFullScreen ? .leading : .trailing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(brand.title)
      }
      .frame(height: layout.headerHeight)
    }

    private func syncFullScreenState() {
      let active = NSApplication.shared.windows.contains { window in
        window.styleMask.contains(.fullScreen)
      }
      if isFullScreen != active {
        withAnimation(fullScreenAnimation) {
          isFullScreen = active
        }
      }
    }

    private var fullScreenAnimation: Animation? {
      reduceMotion ? nil : .easeOut(duration: 0.16)
    }
  }

  private struct MacWorkspaceSidebarSectionView<RouteID: Hashable & Sendable>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.macWorkspaceDensityMetrics) private var metrics

    let isExpanded: Bool
    let onOpenScene: (RouteID) -> Void
    let onSelect: (RouteID) -> Void
    let onToggleExpansion: (WorkspaceRouteSectionID) -> Void
    let section: WorkspaceRouteSection<RouteID>
    let selectedRouteID: RouteID
    let theme: MacWorkspaceShellTheme
    let tint: MacWorkspaceTint

    init(
      isExpanded: Bool,
      section: WorkspaceRouteSection<RouteID>,
      selectedRouteID: RouteID,
      theme: MacWorkspaceShellTheme,
      tint: MacWorkspaceTint,
      onSelect: @escaping (RouteID) -> Void,
      onToggleExpansion: @escaping (WorkspaceRouteSectionID) -> Void,
      onOpenScene: @escaping (RouteID) -> Void
    ) {
      self.isExpanded = isExpanded
      self.onOpenScene = onOpenScene
      self.onSelect = onSelect
      self.onToggleExpansion = onToggleExpansion
      self.section = section
      self.selectedRouteID = selectedRouteID
      self.theme = theme
      self.tint = tint
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        sectionHeader

        if isExpanded {
          VStack(spacing: 2) {
            ForEach(section.routes) { route in
              routeRow(route)
            }
          }
          .transition(sectionTransition)
        }
      }
      .animation(sectionAnimation, value: isExpanded)
    }

    private func routeRow(_ route: WorkspaceRouteDescriptor<RouteID>) -> some View {
      let badge = route.badge.map(String.init)
      let disabledReason = route.availability.disabledReason
      let isEnabled = route.availability.isEnabled
      let isSelected = selectedRouteID == route.id
      let shortcutLabel = route.shortcut?.displayLabel

      return MacWorkspaceSidebarRow(
        title: route.title,
        subtitle: route.subtitle,
        badge: badge,
        shortcutLabel: shortcutLabel,
        systemImage: route.systemImage,
        isProminent: route.isProminent,
        isEnabled: isEnabled,
        isSelected: isSelected,
        disabledReason: disabledReason,
        theme: theme,
        tint: tint
      ) {
        onSelect(route.id)
      }
      .contextMenu {
        routeSceneContextMenu(for: route)
      }
    }

    @ViewBuilder
    private var sectionHeader: some View {
      if section.isCollapsible {
        Button {
          onToggleExpansion(section.id)
        } label: {
          HStack(spacing: 5) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
              .font(.system(size: 8, weight: .bold))
              .foregroundStyle(theme.subtleText)
              .frame(width: 10, height: 10)

            Text(section.title.uppercased())
              .font(.system(size: metrics.sectionHeaderFont, weight: .semibold))
              .foregroundStyle(theme.subtleText)
              .lineLimit(1)

            Spacer(minLength: 0)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(isExpanded ? "Collapse" : "Expand") \(section.title)")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .help(isExpanded ? "Collapse \(section.title)" : "Expand \(section.title)")
      } else {
        Text(section.title.uppercased())
          .font(.system(size: metrics.sectionHeaderFont, weight: .semibold))
          .foregroundStyle(theme.subtleText)
          .lineLimit(1)
          .padding(.horizontal, 8)
          .accessibilityLabel(section.title)
      }
    }

    @ViewBuilder
    private func routeSceneContextMenu(for route: WorkspaceRouteDescriptor<RouteID>) -> some View {
      let opensInSeparateScene = route.scenePresentation.opensInSeparateScene
      if opensInSeparateScene {
        Button("Open in New Window") {
          onOpenScene(route.id)
        }
      }
    }

    private var sectionAnimation: Animation? {
      reduceMotion ? nil : .easeOut(duration: 0.14)
    }

    private var sectionTransition: AnyTransition {
      reduceMotion ? .identity : .opacity
    }
  }

  private struct MacWorkspaceSidebarRow: View {
    @Environment(\.macWorkspaceDensityMetrics) private var metrics
    @State private var isHovered = false

    let badge: String?
    let disabledReason: String?
    let isEnabled: Bool
    let isProminent: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let shortcutLabel: String?
    let subtitle: String?
    let systemImage: String
    let theme: MacWorkspaceShellTheme
    let tint: MacWorkspaceTint
    let title: String

    init(
      title: String,
      subtitle: String? = nil,
      badge: String? = nil,
      shortcutLabel: String? = nil,
      systemImage: String,
      isProminent: Bool = false,
      isEnabled: Bool = true,
      isSelected: Bool = false,
      disabledReason: String? = nil,
      theme: MacWorkspaceShellTheme,
      tint: MacWorkspaceTint,
      onTap: @escaping () -> Void
    ) {
      self.badge = badge
      self.disabledReason = disabledReason
      self.isEnabled = isEnabled
      self.isProminent = isProminent
      self.isSelected = isSelected
      self.onTap = onTap
      self.shortcutLabel = shortcutLabel
      self.subtitle = subtitle
      self.systemImage = systemImage
      self.theme = theme
      self.tint = tint
      self.title = title
    }

    var body: some View {
      Button(action: onTap) {
        HStack(spacing: metrics.rowSpacing) {
          MacWorkspaceRouteIcon(
            systemImage: systemImage,
            isProminent: isProminent,
            isSelected: isSelected,
            theme: theme,
            tint: tint
          )

          Text(title)
            .font(.system(size: metrics.rowTitleFont, weight: isSelected ? .medium : .regular))
            .foregroundStyle(theme.strongText)
            .lineLimit(1)

          Spacer(minLength: 0)

          if let badge {
            MacWorkspaceBadge(badge, theme: theme)
          }

          if let shortcutLabel {
            MacWorkspaceKeycap(shortcutLabel, theme: theme)
          }
        }
        .padding(.horizontal, metrics.rowPaddingHorizontal)
        .padding(.vertical, metrics.rowPaddingVertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: metrics.rowCornerRadius, style: .continuous))
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(!isEnabled)
      .onHover { isHovered = $0 }
      .animation(.easeOut(duration: 0.12), value: isHovered)
      .animation(.easeOut(duration: 0.16), value: isSelected)
      .help(disabledReason ?? title)
      .accessibilityLabel(title)
      .accessibilityValue(accessibilityValue)
      .macWorkspaceSelectedAccessibility(isSelected)
    }

    private var rowBackground: Color {
      if isSelected { return theme.selection }
      if isHovered { return theme.hover }
      return .clear
    }

    private var accessibilityValue: String {
      [
        subtitle,
        badge,
        shortcutLabel,
        disabledReason,
      ]
      .compactMap { $0 }
      .joined(separator: ", ")
    }
  }

  private struct MacWorkspaceContentRegion<
    RouteID: Hashable & Sendable,
    ListContent: View,
    DetailContent: View,
    FullWidthContent: View,
    HeaderLeadingContent: View,
    HeaderCenterContent: View,
    HeaderTrailingContent: View,
    InspectorContent: View
  >: View {
    @Bindable var store: StoreOf<WorkspaceFeature<RouteID>>
    @Binding var columnWidths: MacWorkspaceColumnWidths
    @Binding var isInspectorPresented: Bool
    @Binding var isSidebarVisible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let detail: (WorkspaceRouteDescriptor<RouteID>) -> DetailContent
    let fullWidth: (WorkspaceRouteDescriptor<RouteID>) -> FullWidthContent
    let hasInspector: Bool
    let headerCenter: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderCenterContent
    let headerLeading: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderLeadingContent
    let headerTrailing: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderTrailingContent
    let inspector: (WorkspaceRouteDescriptor<RouteID>?) -> InspectorContent
    let isNativeStyle: Bool
    let layout: MacWorkspaceShellLayout
    let list: (WorkspaceRouteDescriptor<RouteID>) -> ListContent
    let prefersSinglePaneContent: Bool
    let theme: MacWorkspaceShellTheme
    let width: CGFloat

    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      columnWidths: Binding<MacWorkspaceColumnWidths>,
      hasInspector: Bool,
      @ViewBuilder headerCenter: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderCenterContent,
      @ViewBuilder headerLeading: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderLeadingContent,
      @ViewBuilder headerTrailing: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderTrailingContent,
      @ViewBuilder inspector: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> InspectorContent,
      isInspectorPresented: Binding<Bool>,
      isNativeStyle: Bool,
      isSidebarVisible: Binding<Bool>,
      layout: MacWorkspaceShellLayout,
      @ViewBuilder list: @escaping (WorkspaceRouteDescriptor<RouteID>) -> ListContent,
      prefersSinglePaneContent: Bool,
      theme: MacWorkspaceShellTheme,
      width: CGFloat,
      @ViewBuilder detail: @escaping (WorkspaceRouteDescriptor<RouteID>) -> DetailContent,
      @ViewBuilder fullWidth: @escaping (WorkspaceRouteDescriptor<RouteID>) -> FullWidthContent
    ) {
      self.store = store
      _columnWidths = columnWidths
      self.hasInspector = hasInspector
      self.headerCenter = headerCenter
      self.headerLeading = headerLeading
      self.headerTrailing = headerTrailing
      self.inspector = inspector
      _isInspectorPresented = isInspectorPresented
      self.isNativeStyle = isNativeStyle
      _isSidebarVisible = isSidebarVisible
      self.layout = layout
      self.list = list
      self.prefersSinglePaneContent = prefersSinglePaneContent
      self.theme = theme
      self.width = width
      self.detail = detail
      self.fullWidth = fullWidth
    }

    var body: some View {
      VStack(spacing: 0) {
        MacWorkspaceContentHeader(
          store: store,
          hasInspector: hasInspector,
          headerCenter: headerCenter,
          headerLeading: headerLeading,
          headerTrailing: headerTrailing,
          isInspectorPresented: $isInspectorPresented,
          isNativeStyle: isNativeStyle,
          isSidebarVisible: $isSidebarVisible,
          layout: layout,
          theme: theme
        )
        MacWorkspaceDivider(axis: .horizontal, thickness: layout.dividerWidth, theme: theme)

        if let route = store.selectedRoute {
          contentBody(route)
        } else {
          MacWorkspaceEmptyStateView(
            title: "No route selected",
            systemImage: "sidebar.left",
            message: "Choose a route from the sidebar to open a workspace.",
            theme: theme
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .background(theme.canvas)
    }

    private var showsInspector: Bool {
      hasInspector && isInspectorPresented
    }

    private var inspectorWidth: CGFloat {
      layout.resolvedWidth(for: .inspector, columnWidths: columnWidths)
    }

    private var mainWidth: CGFloat {
      guard showsInspector
      else { return width }
      return max(
        layout.minimumContentWidth(for: columnWidths),
        width - inspectorWidth - layout.dividerWidth
      )
    }

    private func contentBody(_ route: WorkspaceRouteDescriptor<RouteID>) -> some View {
      HStack(spacing: 0) {
        if prefersSinglePaneContent {
          detail(route)
            .frame(width: mainWidth)
            .frame(maxHeight: .infinity)
            .background(contentSurface)
        } else {
          switch route.presentation {
          case .listDetail:
            splitContent(route, width: mainWidth)
              .frame(width: mainWidth)
          case .fullWidth:
            fullWidth(route)
              .frame(width: mainWidth)
              .frame(maxHeight: .infinity)
              .background(contentSurface)
          }
        }

        if showsInspector {
          MacWorkspaceResizeDivider(
            column: .inspector,
            currentWidth: inspectorWidth,
            direction: -1,
            layout: layout,
            theme: theme
          ) { width in
            columnWidths[.inspector] = width
          } onReset: {
            columnWidths[.inspector] = nil
          }
          .transition(inspectorTransition)

          inspectorPane
            .frame(width: inspectorWidth)
            .transition(inspectorTransition)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .animation(inspectorAnimation, value: showsInspector)
    }

    private func splitContent(
      _ route: WorkspaceRouteDescriptor<RouteID>,
      width: CGFloat
    ) -> some View {
      let listWidth = layout.resolvedWidth(for: .list, columnWidths: columnWidths)
      let detailMinimumWidth = layout.resolvedWidth(for: .detail, columnWidths: columnWidths)
      let detailWidth = max(detailMinimumWidth, width - listWidth - layout.dividerWidth)

      return HStack(spacing: 0) {
        list(route)
          .frame(width: listWidth)
          .frame(maxHeight: .infinity)
          .background(contentSurface)
          .clipped()

        MacWorkspaceResizeDivider(
          column: .list,
          currentWidth: listWidth,
          layout: layout,
          theme: theme
        ) { width in
          columnWidths[.list] = width
        } onReset: {
          columnWidths[.list] = nil
        }

        detail(route)
          .frame(width: detailWidth)
          .frame(maxHeight: .infinity)
          .background(contentSurface)
          .clipped()
          .layoutPriority(1)
      }
    }

    private var contentSurface: Color {
      isNativeStyle ? Color(nsColor: .textBackgroundColor) : theme.canvas
    }

    private var inspectorPane: some View {
      inspector(store.selectedRoute)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.canvas)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Inspector")
    }

    private var inspectorAnimation: Animation? {
      reduceMotion ? nil : .easeOut(duration: 0.18)
    }

    private var inspectorTransition: AnyTransition {
      reduceMotion ? .identity : .move(edge: .trailing).combined(with: .opacity)
    }
  }

  private struct MacWorkspaceContentHeader<
    RouteID: Hashable & Sendable,
    HeaderLeadingContent: View,
    HeaderCenterContent: View,
    HeaderTrailingContent: View
  >: View {
    @Bindable var store: StoreOf<WorkspaceFeature<RouteID>>
    @Binding var isInspectorPresented: Bool
    @Binding var isSidebarVisible: Bool
    @Environment(\.macWorkspaceDensityMetrics) private var metrics

    let hasInspector: Bool
    let headerCenter: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderCenterContent
    let headerLeading: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderLeadingContent
    let headerTrailing: (WorkspaceRouteDescriptor<RouteID>?) -> HeaderTrailingContent
    let isNativeStyle: Bool
    let layout: MacWorkspaceShellLayout
    let theme: MacWorkspaceShellTheme

    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      hasInspector: Bool,
      @ViewBuilder headerCenter: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderCenterContent,
      @ViewBuilder headerLeading: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderLeadingContent,
      @ViewBuilder headerTrailing: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> HeaderTrailingContent,
      isInspectorPresented: Binding<Bool>,
      isNativeStyle: Bool,
      isSidebarVisible: Binding<Bool>,
      layout: MacWorkspaceShellLayout,
      theme: MacWorkspaceShellTheme
    ) {
      self.store = store
      self.hasInspector = hasInspector
      self.headerCenter = headerCenter
      self.headerLeading = headerLeading
      self.headerTrailing = headerTrailing
      _isInspectorPresented = isInspectorPresented
      self.isNativeStyle = isNativeStyle
      _isSidebarVisible = isSidebarVisible
      self.layout = layout
      self.theme = theme
    }

    var body: some View {
      HStack(alignment: .center, spacing: isNativeStyle ? 12 : 6) {
        Color.clear
          .frame(width: sidebarHiddenLeadingReservation)

        sidebarVisibilityButton
        headerLeading(store.selectedRoute)
        titleBlock
        Spacer(minLength: 12)
        headerCenter(store.selectedRoute)
        Spacer(minLength: 12)
        controls
        headerTrailing(store.selectedRoute)
      }
      .padding(.horizontal, isNativeStyle ? 24 : 10)
      .frame(height: layout.headerHeight)
      .background(theme.canvas)
    }

    private var sidebarHiddenLeadingReservation: CGFloat {
      isSidebarVisible ? 0 : max(0, layout.trafficLightSlotWidth - 24)
    }

    private var sidebarVisibilityButton: some View {
      MacWorkspaceToolbarIconButton(
        title: isSidebarVisible ? "Hide Sidebar" : "Show Sidebar",
        systemImage: "sidebar.left",
        theme: theme,
        style: isNativeStyle ? .glass : .custom,
        fontSize: isNativeStyle ? 13 : 15
      ) {
        isSidebarVisible.toggle()
      }
      .macWorkspaceKeyboardShortcut(
        WorkspaceKeyboardShortcut(
          key: "s",
          modifiers: [.command, .control],
          displayTitle: "⌘⌃S"
        )
      )
      .accessibilityHint("Toggles the left navigation column")
    }

    private var titleBlock: some View {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(store.selectedRoute?.title ?? "Workspace")
          .font(.system(size: metrics.headerTitleFont, weight: .semibold))
          .foregroundStyle(theme.strongText)
          .lineLimit(1)

        if let count = store.selectedRoute?.badge {
          Text("\(count)")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(theme.mutedText)
            .monospacedDigit()
            .lineLimit(1)
        }

        if let subtitle = store.selectedRoute?.subtitle {
          Text(subtitle)
            .font(.system(size: 12))
            .foregroundStyle(theme.mutedText)
            .lineLimit(1)
        }
      }
    }

    private var controls: some View {
      HStack(spacing: isNativeStyle ? 8 : 4) {
        if hasInspector {
          inspectorVisibilityButton
        }

        ForEach(visibleToolbarCommands) { command in
          Button {
            if case .toolbarAction(let id) = command.target {
              store.send(.toolbarActionRequested(id))
            }
          } label: {
            Label(command.title, systemImage: command.systemImage)
              .labelStyle(.titleAndIcon)
              .macWorkspaceHeaderControl(theme: theme, style: isNativeStyle ? .glass : .custom)
          }
          .buttonStyle(.plain)
          .disabled(!command.isEnabled)
          .help(command.disabledReason ?? command.title)
          .macWorkspaceKeyboardShortcut(command.shortcut)
          .accessibilityLabel(command.title)
          .accessibilityValue(command.disabledReason ?? "")
        }

        if !visibleToolbarCommands.isEmpty && visiblePrimaryCommand != nil {
          Rectangle()
            .fill(theme.divider)
            .frame(width: 1, height: 20)
            .padding(.horizontal, 6)
        }

        if let primaryCommand = visiblePrimaryCommand {
          Button {
            if case .primaryAction(let id) = primaryCommand.target {
              store.send(.primaryActionRequested(id))
            }
          } label: {
            Label(primaryCommand.title, systemImage: primaryCommand.systemImage)
              .labelStyle(.titleAndIcon)
              .macWorkspaceHeaderControl(theme: theme, isPrimary: true, style: isNativeStyle ? .glass : .custom)
          }
          .buttonStyle(.plain)
          .disabled(!primaryCommand.isEnabled)
          .help(primaryCommand.disabledReason ?? primaryCommand.title)
          .macWorkspaceKeyboardShortcut(primaryCommand.shortcut)
          .accessibilityLabel(primaryCommand.title)
          .accessibilityValue(primaryCommand.disabledReason ?? "")
        }
      }
    }

    private var inspectorVisibilityButton: some View {
      MacWorkspaceToolbarIconButton(
        title: isInspectorPresented ? "Hide Inspector" : "Show Inspector",
        systemImage: "sidebar.trailing",
        theme: theme,
        style: isNativeStyle ? .glass : .custom
      ) {
        isInspectorPresented.toggle()
      }
      .accessibilityHint("Toggles the right inspector panel")
    }

    private var visibleToolbarCommands: [WorkspaceCommand<RouteID>] {
      store.availableCommands.filter { command in
        command.role == .toolbarAction && !command.isHidden
      }
    }

    private var visiblePrimaryCommand: WorkspaceCommand<RouteID>? {
      store.availableCommands.first { command in
        command.role == .primaryAction && !command.isHidden
      }
    }
  }

  private struct MacWorkspaceCommandPalette<RouteID: Hashable & Sendable>: View {
    @Bindable var store: StoreOf<WorkspaceFeature<RouteID>>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isSearchFocused: Bool
    @State private var focusTask: Task<Void, Never>?

    let behavior: MacWorkspaceShellBehavior
    let layout: MacWorkspaceShellLayout
    let searchPlaceholder: String
    let theme: MacWorkspaceShellTheme

    var body: some View {
      ZStack {
        theme.commandPaletteScrim
          .ignoresSafeArea()
          .accessibilityHidden(true)
          .onTapGesture {
            store.send(.commandPaletteDismissed)
          }

        VStack(spacing: 0) {
          searchField
          MacWorkspaceDivider(axis: .horizontal, thickness: layout.dividerWidth, theme: theme)
          results
        }
        .frame(width: behavior.commandPaletteWidth)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(theme.divider, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 30, y: 16)
        .padding(.top, behavior.commandPaletteTopPadding)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Command Palette")
      }
      .onAppear {
        focusSearchField()
      }
      .onDisappear {
        focusTask?.cancel()
      }
      .onExitCommand {
        store.send(.commandPaletteDismissed)
      }
      .onMoveCommand { direction in
        switch direction {
        case .down:
          store.send(.commandPaletteMoveSelection(.down))
        case .up:
          store.send(.commandPaletteMoveSelection(.up))
        default:
          break
        }
      }
    }

    private func focusSearchField() {
      focusTask?.cancel()
      focusTask = Task { @MainActor in
        isSearchFocused = false
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(80))
        guard !Task.isCancelled else { return }
        isSearchFocused = true
      }
    }

    private var searchField: some View {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(theme.mutedText)

        TextField(
          searchPlaceholder,
          text: Binding(
            get: { store.commandPaletteQuery },
            set: { store.send(.commandPaletteQueryChanged($0)) }
          )
        )
        .textFieldStyle(.plain)
        .font(.system(size: 16))
        .focused($isSearchFocused)
        .onSubmit {
          store.send(.commandPaletteReturnKeyPressed)
        }

        if !store.commandPaletteQuery.isEmpty {
          Button {
            store.send(.commandPaletteQueryChanged(""))
          } label: {
            Image(systemName: "xmark.circle.fill")
          }
          .buttonStyle(.plain)
          .foregroundStyle(theme.mutedText)
          .help("Clear Search")
        }
      }
      .padding(16)
    }

    @ViewBuilder
    private var results: some View {
      if store.filteredCommands.isEmpty {
        MacWorkspaceEmptyStateView(
          title: "No commands found",
          systemImage: "magnifyingglass",
          message: "Try a route name, action, shortcut, or keyword.",
          theme: theme
        )
        .frame(height: 180)
      } else {
        ScrollViewReader { proxy in
          ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 3) {
              ForEach(store.filteredCommands) { command in
                MacWorkspaceCommandRow(
                  command: command,
                  isSelected: command.id == store.selectedCommandID,
                  onFocus: {
                    store.send(.commandPaletteSelectionChanged(command.id))
                  },
                  onSelect: {
                    store.send(.commandPaletteCommandSelected(command.id))
                  },
                  theme: theme
                )
                .id(command.id)
                .opacity(command.isEnabled ? 1 : 0.58)
              }
            }
            .padding(8)
          }
          .frame(maxHeight: behavior.commandPaletteResultsMaximumHeight)
          .onChange(of: store.selectedCommandID) { _, newID in
            guard let newID else { return }
            if reduceMotion {
              proxy.scrollTo(newID, anchor: .center)
            } else {
              withAnimation(.easeOut(duration: 0.12)) {
                proxy.scrollTo(newID, anchor: .center)
              }
            }
          }
        }
      }
    }
  }

  private struct MacWorkspaceCommandRow<RouteID: Hashable & Sendable>: View {
    @Environment(\.macWorkspaceDensityMetrics) private var metrics
    @State private var isHovered = false

    let command: WorkspaceCommand<RouteID>
    let isSelected: Bool
    let onFocus: () -> Void
    let onSelect: () -> Void
    let theme: MacWorkspaceShellTheme

    var body: some View {
      Button(action: onSelect) {
        HStack(spacing: metrics.commandRowSpacing) {
          Image(systemName: command.systemImage)
            .font(.system(size: metrics.commandIconFont, weight: .medium))
            .foregroundStyle(theme.mutedText)
            .frame(width: metrics.commandIconSize, height: metrics.commandIconSize)

          VStack(alignment: .leading, spacing: 3) {
            Text(command.title)
              .font(.system(size: metrics.commandTitleFont, weight: .medium))
              .foregroundStyle(theme.strongText)
              .lineLimit(1)

            Text(command.subtitle ?? command.categoryTitle)
              .font(.system(size: metrics.commandSubtitleFont))
              .foregroundStyle(theme.mutedText)
              .lineLimit(1)
          }

          Spacer(minLength: 12)

          Text(command.categoryTitle)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(theme.subtleText)
            .lineLimit(1)

          if let shortcut = command.shortcut {
            MacWorkspaceKeycap(
              shortcut.displayLabel,
              theme: theme,
              cornerRadius: 4,
              horizontalPadding: 6,
              verticalPadding: 2
            )
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, metrics.commandRowPaddingVertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(!command.isEnabled)
      .onHover { hovered in
        isHovered = hovered
        if hovered {
          onFocus()
        }
      }
      .accessibilityLabel(command.title)
      .accessibilityValue(accessibilityValue)
      .accessibilityHint("Runs command")
      .macWorkspaceSelectedAccessibility(isSelected)
    }

    private var rowBackground: Color {
      if isSelected { return theme.selection }
      if isHovered { return theme.hover }
      return .clear
    }

    private var accessibilityValue: String {
      [
        command.subtitle ?? command.categoryTitle,
        command.shortcut?.displayLabel,
        command.isEnabled ? nil : command.disabledReason ?? "Disabled",
      ]
      .compactMap { $0 }
      .joined(separator: ", ")
    }
  }

  /// A macOS command reference surface backed by the shared command registry.
  public struct MacWorkspaceCommandReferenceView<RouteID: Hashable & Sendable>: View {
    private let commands: [WorkspaceCommand<RouteID>]
    private let configuration: WorkspaceCommandReferenceConfiguration

    public init(
      commands: [WorkspaceCommand<RouteID>],
      configuration: WorkspaceCommandReferenceConfiguration = .default
    ) {
      self.commands = commands
      self.configuration = configuration
    }

    public init(
      state: WorkspaceFeature<RouteID>.State,
      configuration: WorkspaceCommandReferenceConfiguration = .default
    ) {
      self.init(
        commands: state.availableCommands,
        configuration: configuration
      )
    }

    public var body: some View {
      List {
        ForEach(sections) { section in
          Section(section.title) {
            ForEach(section.commands) { command in
              MacWorkspaceCommandReferenceRow(command: command)
            }
          }
        }
      }
      .navigationTitle("Commands")
    }

    private var sections: [WorkspaceCommandSection<RouteID>] {
      WorkspaceCommandSections.make(
        for: commands,
        grouping: configuration.grouping,
        includesDisabledCommands: configuration.includesDisabledCommands
      )
    }
  }

  private struct MacWorkspaceCommandReferenceRow<RouteID: Hashable & Sendable>: View {
    let command: WorkspaceCommand<RouteID>

    var body: some View {
      HStack(spacing: 10) {
        Image(systemName: command.systemImage)
          .frame(width: 22)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 2) {
          Text(command.title)
            .font(.callout)
            .lineLimit(1)
          Text(command.categoryTitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer()

        if let shortcut = command.shortcut {
          Text(shortcut.displayLabel)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
        }
      }
      .padding(.vertical, 4)
      .contentShape(Rectangle())
    }
  }

  private struct MacWorkspaceBadge: View {
    @Environment(\.macWorkspaceDensityMetrics) private var metrics
    let theme: MacWorkspaceShellTheme
    let value: String

    init(_ value: String, theme: MacWorkspaceShellTheme) {
      self.theme = theme
      self.value = value
    }

    var body: some View {
      Text(value)
        .font(.system(size: metrics.badgeFont, weight: .medium, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(theme.mutedText)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(theme.fill, in: Capsule())
    }
  }

  private struct MacWorkspaceKeycap: View {
    @Environment(\.macWorkspaceDensityMetrics) private var metrics

    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let theme: MacWorkspaceShellTheme
    let title: String
    let verticalPadding: CGFloat

    init(
      _ title: String,
      theme: MacWorkspaceShellTheme,
      cornerRadius: CGFloat = 3,
      horizontalPadding: CGFloat = 5,
      verticalPadding: CGFloat = 1
    ) {
      self.cornerRadius = cornerRadius
      self.horizontalPadding = horizontalPadding
      self.theme = theme
      self.title = title
      self.verticalPadding = verticalPadding
    }

    var body: some View {
      Text(title)
        .font(.system(size: metrics.keycapFont, weight: .medium))
        .foregroundStyle(theme.subtleText)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(theme.fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
  }

  private struct MacWorkspaceRouteIcon: View {
    @Environment(\.macWorkspaceDensityMetrics) private var metrics

    let isProminent: Bool
    let isSelected: Bool
    let systemImage: String
    let theme: MacWorkspaceShellTheme
    let tint: MacWorkspaceTint

    init(
      systemImage: String,
      isProminent: Bool = false,
      isSelected: Bool = false,
      theme: MacWorkspaceShellTheme,
      tint: MacWorkspaceTint
    ) {
      self.isProminent = isProminent
      self.isSelected = isSelected
      self.systemImage = systemImage
      self.theme = theme
      self.tint = tint
    }

    var body: some View {
      if isProminent {
        Image(systemName: systemImage)
          .font(.system(size: metrics.routeIconProminentFont, weight: .bold))
          .foregroundStyle(Color.white)
          .frame(width: metrics.routeIconProminentSize, height: metrics.routeIconProminentSize)
          .background(tint.accent, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
      } else {
        Image(systemName: systemImage)
          .font(.system(size: metrics.routeIconFont, weight: .regular))
          .foregroundStyle(isSelected ? tint.accent : theme.mutedText)
          .frame(width: metrics.routeIconWidth)
      }
    }
  }

  private struct MacWorkspaceToolbarIconButton: View {
    let action: () -> Void
    let fontSize: CGFloat
    let style: MacWorkspaceHeaderControlStyle
    let systemImage: String
    let theme: MacWorkspaceShellTheme
    let title: String

    init(
      title: String,
      systemImage: String,
      theme: MacWorkspaceShellTheme,
      style: MacWorkspaceHeaderControlStyle = .custom,
      fontSize: CGFloat = 13,
      action: @escaping () -> Void
    ) {
      self.action = action
      self.fontSize = fontSize
      self.style = style
      self.systemImage = systemImage
      self.theme = theme
      self.title = title
    }

    var body: some View {
      Button(action: action) {
        Label(title, systemImage: systemImage)
          .labelStyle(.iconOnly)
          .macWorkspaceHeaderControl(
            theme: theme,
            isIconOnly: true,
            style: style,
            fontSize: fontSize
          )
      }
      .buttonStyle(.plain)
      .help(title)
      .accessibilityLabel(title)
    }
  }

  private enum MacWorkspaceHeaderControlStyle {
    case custom
    case glass
  }

  private struct MacWorkspaceHeaderControlModifier: ViewModifier {
    let fontSize: CGFloat
    let isIconOnly: Bool
    let isPrimary: Bool
    let style: MacWorkspaceHeaderControlStyle
    let theme: MacWorkspaceShellTheme
    @State private var isHovered = false

    func body(content: Content) -> some View {
      content
        .font(.system(size: fontSize, weight: isPrimary ? .semibold : .regular))
        .foregroundStyle(foregroundColor)
        .lineLimit(1)
        .padding(.horizontal, isIconOnly ? 7 : 10)
        .frame(height: 28)
        .background(background)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private var foregroundColor: Color {
      isPrimary ? theme.primaryControlForeground : theme.strongText
    }

    @ViewBuilder
    private var background: some View {
      switch style {
      case .custom:
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .fill(isPrimary ? theme.primaryControlBackground : isHovered ? theme.hover : .clear)
          .overlay {
            if isPrimary && isHovered {
              RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(theme.primaryControlHoverOverlay)
            }
          }
      case .glass:
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        shape
          .fill(isPrimary ? theme.primaryControlBackground : Color(nsColor: .controlBackgroundColor).opacity(0.42))
          .background {
            shape.fill(.regularMaterial)
          }
          .overlay {
            shape.stroke(theme.divider.opacity(isHovered ? 0.9 : 0.45), lineWidth: 1)
          }
      }
    }
  }

  private struct MacWorkspaceDivider: View {
    enum Axis {
      case horizontal
      case vertical
    }

    let axis: Axis
    let theme: MacWorkspaceShellTheme
    let thickness: CGFloat

    init(
      axis: Axis = .vertical,
      thickness: CGFloat = 1,
      theme: MacWorkspaceShellTheme
    ) {
      self.axis = axis
      self.theme = theme
      self.thickness = thickness
    }

    var body: some View {
      switch axis {
      case .horizontal:
        theme.divider.frame(height: thickness)
      case .vertical:
        theme.divider
          .frame(width: thickness)
          .ignoresSafeArea(edges: .vertical)
      }
    }
  }

  private struct MacWorkspaceResizeBehavior: Equatable, Sendable {
    var defaultValue: CGFloat
    var direction: CGFloat
    var range: MacWorkspaceColumnWidthRange

    var defaultClampedValue: CGFloat {
      let fallback = defaultValue.isFinite ? defaultValue : 0
      return clampedFiniteValue(fallback)
    }

    var valueRange: ClosedRange<CGFloat> {
      let bounds = resolvedBounds
      return bounds.minimum...bounds.maximum
    }

    func clampedValue(_ value: CGFloat) -> CGFloat {
      guard value.isFinite
      else { return defaultClampedValue }
      return clampedFiniteValue(value)
    }

    func value(startingAt startingValue: CGFloat, translation: CGFloat) -> CGFloat {
      let startingValue = clampedValue(startingValue)
      guard translation.isFinite, direction.isFinite
      else { return startingValue }
      return clampedValue(startingValue + translation * direction)
    }

    private func clampedFiniteValue(_ value: CGFloat) -> CGFloat {
      let bounds = resolvedBounds
      return min(max(value, bounds.minimum), bounds.maximum)
    }

    private var resolvedBounds: (minimum: CGFloat, maximum: CGFloat) {
      let fallback = defaultValue.isFinite ? defaultValue : 0
      let minimum = range.minimum.isFinite ? range.minimum : fallback
      let maximum = range.maximum.isFinite ? range.maximum : fallback
      return (min(minimum, maximum), max(minimum, maximum))
    }
  }

  private struct MacWorkspaceResizeDivider: View {
    let column: MacWorkspaceColumn
    let currentWidth: CGFloat
    let direction: CGFloat
    let layout: MacWorkspaceShellLayout
    let onReset: () -> Void
    let onWidthChanged: (CGFloat) -> Void
    let theme: MacWorkspaceShellTheme

    init(
      column: MacWorkspaceColumn,
      currentWidth: CGFloat,
      direction: CGFloat = 1,
      layout: MacWorkspaceShellLayout,
      theme: MacWorkspaceShellTheme,
      onWidthChanged: @escaping (CGFloat) -> Void,
      onReset: @escaping () -> Void
    ) {
      self.column = column
      self.currentWidth = currentWidth
      self.direction = direction
      self.layout = layout
      self.onReset = onReset
      self.onWidthChanged = onWidthChanged
      self.theme = theme
    }

    var body: some View {
      MacWorkspaceResizeHandle(
        accessibilityIdentifier: "mac-workspace-resize-\(column.rawValue)-handle",
        accessibilityTitle: column.accessibilityTitle,
        currentValue: currentWidth,
        behavior: MacWorkspaceResizeBehavior(
          defaultValue: layout.defaultWidth(for: column),
          direction: direction,
          range: layout.widthRange(for: column)
        ),
        thickness: layout.dividerWidth,
        theme: theme,
        onValueChanged: onWidthChanged,
        onReset: onReset
      )
    }
  }

  private struct MacWorkspaceResizeHandle: View {
    let accessibilityIdentifier: String?
    let accessibilityTitle: String
    let behavior: MacWorkspaceResizeBehavior
    let currentValue: CGFloat
    let hitSlop: CGFloat
    let onReset: () -> Void
    let onValueChanged: (CGFloat) -> Void
    let theme: MacWorkspaceShellTheme
    let thickness: CGFloat

    @State private var isHovered = false
    @State private var startingValue: CGFloat?

    init(
      accessibilityIdentifier: String? = nil,
      accessibilityTitle: String,
      currentValue: CGFloat,
      behavior: MacWorkspaceResizeBehavior,
      thickness: CGFloat = 1,
      hitSlop: CGFloat = 8,
      theme: MacWorkspaceShellTheme,
      onValueChanged: @escaping (CGFloat) -> Void,
      onReset: @escaping () -> Void
    ) {
      self.accessibilityIdentifier = accessibilityIdentifier
      self.accessibilityTitle = accessibilityTitle
      self.behavior = behavior
      self.currentValue = currentValue
      self.hitSlop = hitSlop
      self.onReset = onReset
      self.onValueChanged = onValueChanged
      self.theme = theme
      self.thickness = thickness
    }

    var body: some View {
      let isDragging = startingValue != nil
      let isActive = isHovered || isDragging
      MacWorkspaceDivider(axis: .vertical, thickness: thickness, theme: theme)
        .overlay {
          Rectangle()
            .fill(isDragging ? theme.primaryControlBackground : theme.strongText.opacity(0.28))
            .frame(width: isDragging ? 2 : 1.5)
            .opacity(isActive ? 1 : 0)
        }
        .overlay {
          Rectangle()
            .fill(Color.clear)
            .frame(width: hitSlop)
            .contentShape(Rectangle())
        }
        .animation(.easeOut(duration: 0.12), value: isActive)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              if startingValue == nil {
                startingValue = currentValue
              }
              guard let startingValue else { return }
              onValueChanged(
                behavior.value(
                  startingAt: startingValue,
                  translation: value.translation.width
                )
              )
            }
            .onEnded { _ in
              startingValue = nil
            }
        )
        .simultaneousGesture(
          TapGesture(count: 2)
            .onEnded {
              startingValue = nil
              onReset()
            }
        )
        .onHover { hovering in
          isHovered = hovering
          updateCursor(isInside: hovering)
        }
        .help("Drag to resize \(accessibilityTitle.lowercased())")
        .accessibilityRepresentation {
          Slider(
            value: Binding(
              get: { Double(behavior.clampedValue(currentValue)) },
              set: { onValueChanged(CGFloat($0)) }
            ),
            in: Double(behavior.valueRange.lowerBound)...Double(behavior.valueRange.upperBound),
            step: 1
          ) {
            Text("Resize \(accessibilityTitle)")
          }
          .accessibilityIdentifier(accessibilityIdentifier ?? "")
        }
    }

    private func updateCursor(isInside: Bool) {
      if isInside {
        NSCursor.resizeLeftRight.push()
      } else {
        NSCursor.pop()
      }
    }
  }

  private struct MacWorkspaceEmptyStateView: View {
    @Environment(\.macWorkspaceDensityMetrics) private var metrics

    let message: String
    let systemImage: String
    let theme: MacWorkspaceShellTheme
    let title: String

    init(
      title: String,
      systemImage: String,
      message: String,
      theme: MacWorkspaceShellTheme
    ) {
      self.message = message
      self.systemImage = systemImage
      self.theme = theme
      self.title = title
    }

    var body: some View {
      VStack(spacing: 10) {
        Image(systemName: systemImage)
          .font(.system(size: metrics.emptyStateIconFont, weight: .semibold))
          .foregroundStyle(theme.mutedText)
          .frame(width: metrics.emptyStateIconContainer, height: metrics.emptyStateIconContainer)
          .background(theme.fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        Text(title)
          .font(.system(size: metrics.emptyStateTitleFont, weight: .semibold))
          .foregroundStyle(theme.strongText)

        Text(message)
          .font(.callout)
          .foregroundStyle(theme.mutedText)
          .multilineTextAlignment(.center)
          .lineLimit(3)
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private struct MacWorkspaceTitlebarConfigurator: NSViewRepresentable {
    var layout: MacWorkspaceShellLayout
    var style: MacWorkspaceShellStyle

    func makeNSView(context: Context) -> NSView {
      ConfiguringView(layout: layout, style: style)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
      guard let configuringView = nsView as? ConfiguringView
      else { return }
      configuringView.shellLayout = layout
      configuringView.shellStyle = style
      configuringView.applyConfiguration()
    }

    private final class ConfiguringView: NSView {
      private var baseTrafficLightFrames: [ObjectIdentifier: CGRect] = [:]
      private weak var observedWindow: NSWindow?
      var shellLayout: MacWorkspaceShellLayout
      var shellStyle: MacWorkspaceShellStyle

      init(layout: MacWorkspaceShellLayout, style: MacWorkspaceShellStyle) {
        self.shellLayout = layout
        self.shellStyle = style
        super.init(frame: .zero)
      }

      @available(*, unavailable)
      required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }

      deinit {
        NSObject.cancelPreviousPerformRequests(
          withTarget: self,
          selector: #selector(deferredAlignTrafficLights),
          object: nil
        )
        NotificationCenter.default.removeObserver(self)
      }

      override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyConfiguration()
      }

      override func layout() {
        super.layout()
        scheduleTrafficLightAlignment()
      }

      func applyConfiguration() {
        guard let window else {
          removeWindowObservers()
          return
        }
        installWindowObserversIfNeeded(for: window)
        window.tabbingMode = .disallowed
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.standardWindowButton(.toolbarButton)?.isHidden = true
        scheduleTrafficLightAlignment()
      }

      private func installWindowObserversIfNeeded(for window: NSWindow) {
        guard observedWindow !== window else { return }
        removeWindowObservers()
        observedWindow = window

        for notificationName in [
          NSWindow.didBecomeKeyNotification,
          NSWindow.didResizeNotification,
          NSWindow.didEndLiveResizeNotification,
          NSWindow.didChangeScreenNotification,
          NSWindow.didEnterFullScreenNotification,
          NSWindow.didExitFullScreenNotification,
        ] {
          NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowNeedsScheduledTrafficLightAlignment(_:)),
            name: notificationName,
            object: window
          )
        }

        NotificationCenter.default.addObserver(
          self,
          selector: #selector(windowDidUpdate(_:)),
          name: NSWindow.didUpdateNotification,
          object: window
        )
      }

      private func removeWindowObservers() {
        NotificationCenter.default.removeObserver(self)
        observedWindow = nil
      }

      @objc
      private func windowNeedsScheduledTrafficLightAlignment(_ notification: Notification) {
        scheduleTrafficLightAlignment()
      }

      @objc
      private func windowDidUpdate(_ notification: Notification) {
        alignTrafficLights()
      }

      private func scheduleTrafficLightAlignment() {
        NSObject.cancelPreviousPerformRequests(
          withTarget: self,
          selector: #selector(deferredAlignTrafficLights),
          object: nil
        )
        alignTrafficLights()
        for delay in [0, 0.05, 0.15, 0.35, 0.75] {
          perform(
            #selector(deferredAlignTrafficLights),
            with: nil,
            afterDelay: delay
          )
        }
      }

      @objc
      private func deferredAlignTrafficLights() {
        alignTrafficLights()
      }

      private func alignTrafficLights() {
        guard let window else { return }
        window.standardWindowButton(.toolbarButton)?.isHidden = true

        if window.styleMask.contains(.fullScreen) {
          return
        }

        guard let closeButton = window.standardWindowButton(.closeButton)
        else { return }

        let closeIdentifier = ObjectIdentifier(closeButton)
        let closeBaseFrame = baseTrafficLightFrames[closeIdentifier] ?? closeButton.frame
        baseTrafficLightFrames[closeIdentifier] = closeBaseFrame

        for buttonType in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
          guard let button = window.standardWindowButton(buttonType),
                let superview = button.superview
          else { continue }

          let identifier = ObjectIdentifier(button)
          let currentFrame = button.frame
          let baseFrame = baseTrafficLightFrames[identifier] ?? currentFrame
          baseTrafficLightFrames[identifier] = baseFrame

          var targetFrame = baseFrame
          let spacingFromClose = baseFrame.origin.x - closeBaseFrame.origin.x
          targetFrame.origin.x = trafficLightLeadingInset + spacingFromClose

          let topInset = trafficLightTopInset(for: targetFrame)
          if superview.isFlipped {
            targetFrame.origin.y = topInset
          } else {
            targetFrame.origin.y = superview.bounds.height - topInset - targetFrame.height
          }

          if framesMatch(currentFrame, targetFrame) {
            continue
          }

          button.frame = targetFrame
        }
      }

      private var trafficLightLeadingInset: CGFloat {
        switch shellStyle {
        case .automatic, .nativeSplitView:
          18
        case .custom:
          shellLayout.titlebarEdgePadding
        }
      }

      private func trafficLightTopInset(for frame: CGRect) -> CGFloat {
        switch shellStyle {
        case .automatic, .nativeSplitView:
          18
        case .custom:
          max(0, (shellLayout.headerHeight - frame.height) / 2)
        }
      }

      private func framesMatch(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) < 0.5
          && abs(lhs.origin.y - rhs.origin.y) < 0.5
          && abs(lhs.size.width - rhs.size.width) < 0.5
          && abs(lhs.size.height - rhs.size.height) < 0.5
      }
    }
  }

  private struct ShellMetrics {
    var contentWidth: CGFloat
    var height: CGFloat
    var sidebarColumnWidth: CGFloat
    var sidebarOuterWidth: CGFloat
    var width: CGFloat
  }

  private struct NativeMetrics {
    static let sidebarCornerRadius: CGFloat = 14
    static let sidebarHorizontalFootprint = sidebarLeadingInset + sidebarTrailingInset
    static let sidebarLeadingInset: CGFloat = 10
    static let sidebarTrailingInset: CGFloat = 8
    static let sidebarVerticalInset: CGFloat = 10

    var contentWidth: CGFloat
    var height: CGFloat
    var sidebarColumnWidth: CGFloat
    var sidebarOuterWidth: CGFloat
    var width: CGFloat
  }

  private extension View {
    func macWorkspaceHeaderControl(
      theme: MacWorkspaceShellTheme,
      isPrimary: Bool = false,
      isIconOnly: Bool = false,
      style: MacWorkspaceHeaderControlStyle = .custom,
      fontSize: CGFloat = 13
    ) -> some View {
      modifier(
        MacWorkspaceHeaderControlModifier(
          fontSize: fontSize,
          isIconOnly: isIconOnly,
          isPrimary: isPrimary,
          style: style,
          theme: theme
        )
      )
    }

    @ViewBuilder
    func macWorkspaceSelectedAccessibility(_ isSelected: Bool) -> some View {
      if isSelected {
        accessibilityAddTraits(.isSelected)
      } else {
        self
      }
    }
  }

#else
  public enum MacWorkspaceShellUnavailable {}
#endif
