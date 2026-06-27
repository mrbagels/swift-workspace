import Foundation

/// Shared route content state that bundled shells can render consistently.
public enum WorkspaceRouteContentState: Codable, Equatable, Sendable {
  case ready
  case loading(title: String, message: String?, systemImage: String)
  case empty(title: String, message: String?, systemImage: String)
  case error(title: String, message: String?, systemImage: String)

  public static func defaultLoading(
    title: String = "Loading",
    message: String? = nil,
    systemImage: String = "arrow.clockwise"
  ) -> Self {
    .loading(title: title, message: message, systemImage: systemImage)
  }

  public static func defaultEmpty(
    title: String = "Nothing Here",
    message: String? = nil,
    systemImage: String = "tray"
  ) -> Self {
    .empty(title: title, message: message, systemImage: systemImage)
  }

  public static func defaultError(
    title: String = "Something Went Wrong",
    message: String? = nil,
    systemImage: String = "exclamationmark.triangle"
  ) -> Self {
    .error(title: title, message: message, systemImage: systemImage)
  }

  public var isReady: Bool {
    self == .ready
  }

  public var title: String {
    switch self {
    case .ready:
      ""
    case .loading(let title, _, _),
         .empty(let title, _, _),
         .error(let title, _, _):
      title
    }
  }

  public var message: String? {
    switch self {
    case .ready:
      nil
    case .loading(_, let message, _),
         .empty(_, let message, _),
         .error(_, let message, _):
      message
    }
  }

  public var systemImage: String {
    switch self {
    case .ready:
      "checkmark"
    case .loading(_, _, let systemImage),
         .empty(_, _, let systemImage),
         .error(_, _, let systemImage):
      systemImage
    }
  }
}
