#if canImport(SwiftUI)
  import SwiftUI
  import WorkspaceCore

  /// Shared visual tokens used by bundled shells and custom renderers.
  public struct WorkspaceShellMetrics: Equatable, Sendable {
    public var badgeFontSize: CGFloat
    public var controlCornerRadius: CGFloat
    public var keycapFontSize: CGFloat
    public var statusIconContainerSize: CGFloat
    public var statusIconFontSize: CGFloat
    public var statusMessageFontSize: CGFloat
    public var statusTitleFontSize: CGFloat

    public init(
      badgeFontSize: CGFloat = 11,
      controlCornerRadius: CGFloat = 7,
      keycapFontSize: CGFloat = 11,
      statusIconContainerSize: CGFloat = 48,
      statusIconFontSize: CGFloat = 22,
      statusMessageFontSize: CGFloat = 13,
      statusTitleFontSize: CGFloat = 17
    ) {
      self.badgeFontSize = badgeFontSize
      self.controlCornerRadius = controlCornerRadius
      self.keycapFontSize = keycapFontSize
      self.statusIconContainerSize = statusIconContainerSize
      self.statusIconFontSize = statusIconFontSize
      self.statusMessageFontSize = statusMessageFontSize
      self.statusTitleFontSize = statusTitleFontSize
    }

    public static let compact = Self(
      badgeFontSize: 10,
      controlCornerRadius: 6,
      keycapFontSize: 10,
      statusIconContainerSize: 40,
      statusIconFontSize: 18,
      statusMessageFontSize: 12,
      statusTitleFontSize: 15
    )

    public static let comfortable = Self()
  }

  /// A minimal color surface for reusable shell primitives.
  public struct WorkspaceShellPalette {
    public var accent: Color
    public var fill: Color
    public var primaryText: Color
    public var secondaryText: Color
    public var subtleText: Color

    public init(
      accent: Color = .accentColor,
      fill: Color = Color.secondary.opacity(0.12),
      primaryText: Color = .primary,
      secondaryText: Color = .secondary,
      subtleText: Color = Color.secondary.opacity(0.72)
    ) {
      self.accent = accent
      self.fill = fill
      self.primaryText = primaryText
      self.secondaryText = secondaryText
      self.subtleText = subtleText
    }
  }

  public struct WorkspaceShellBadge: View {
    private let metrics: WorkspaceShellMetrics
    private let palette: WorkspaceShellPalette
    private let value: String

    public init(
      _ value: String,
      palette: WorkspaceShellPalette = WorkspaceShellPalette(),
      metrics: WorkspaceShellMetrics = .comfortable
    ) {
      self.metrics = metrics
      self.palette = palette
      self.value = value
    }

    public var body: some View {
      Text(value)
        .font(.system(size: metrics.badgeFontSize, weight: .medium, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(palette.secondaryText)
        .lineLimit(1)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(palette.fill, in: Capsule())
        .accessibilityLabel(value)
    }
  }

  public struct WorkspaceShellKeycap: View {
    private let horizontalPadding: CGFloat
    private let metrics: WorkspaceShellMetrics
    private let palette: WorkspaceShellPalette
    private let title: String
    private let verticalPadding: CGFloat

    public init(
      _ title: String,
      palette: WorkspaceShellPalette = WorkspaceShellPalette(),
      metrics: WorkspaceShellMetrics = .comfortable,
      horizontalPadding: CGFloat = 5,
      verticalPadding: CGFloat = 1
    ) {
      self.horizontalPadding = horizontalPadding
      self.metrics = metrics
      self.palette = palette
      self.title = title
      self.verticalPadding = verticalPadding
    }

    public var body: some View {
      Text(title)
        .font(.system(size: metrics.keycapFontSize, weight: .medium))
        .foregroundStyle(palette.subtleText)
        .lineLimit(1)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
          palette.fill,
          in: RoundedRectangle(cornerRadius: metrics.controlCornerRadius, style: .continuous)
        )
        .accessibilityLabel(title)
    }
  }

  public struct WorkspaceShellSectionLabel: View {
    private let palette: WorkspaceShellPalette
    private let title: String

    public init(
      _ title: String,
      palette: WorkspaceShellPalette = WorkspaceShellPalette()
    ) {
      self.palette = palette
      self.title = title
    }

    public var body: some View {
      Text(title.uppercased())
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(palette.subtleText)
        .lineLimit(1)
        .accessibilityLabel(title)
    }
  }

  public struct WorkspaceShellRouteStatusView: View {
    private let contentState: WorkspaceRouteContentState
    private let metrics: WorkspaceShellMetrics
    private let palette: WorkspaceShellPalette

    public init(
      contentState: WorkspaceRouteContentState,
      palette: WorkspaceShellPalette = WorkspaceShellPalette(),
      metrics: WorkspaceShellMetrics = .comfortable
    ) {
      self.contentState = contentState
      self.metrics = metrics
      self.palette = palette
    }

    public var body: some View {
      VStack(spacing: 10) {
        Image(systemName: contentState.systemImage)
          .font(.system(size: metrics.statusIconFontSize, weight: .semibold))
          .foregroundStyle(iconColor)
          .frame(width: metrics.statusIconContainerSize, height: metrics.statusIconContainerSize)
          .background(palette.fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
          .accessibilityHidden(true)

        if !contentState.title.isEmpty {
          Text(contentState.title)
            .font(.system(size: metrics.statusTitleFontSize, weight: .semibold))
            .foregroundStyle(palette.primaryText)
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }

        if let message = contentState.message, !message.isEmpty {
          Text(message)
            .font(.system(size: metrics.statusMessageFontSize))
            .foregroundStyle(palette.secondaryText)
            .multilineTextAlignment(.center)
            .lineLimit(4)
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(contentState.title.isEmpty ? "Route ready" : contentState.title)
      .accessibilityValue(contentState.message ?? "")
    }

    private var iconColor: Color {
      switch contentState {
      case .ready, .loading:
        palette.accent
      case .empty:
        palette.secondaryText
      case .error:
        .red
      }
    }
  }
#endif
