import Foundation
import WorkspaceCore

/// File-backed storage for workspace restoration payloads.
public struct WorkspaceFilePersistence<RouteID: Codable & Hashable & Sendable> {
  public var codec: WorkspaceJSONCodec<RouteID>
  public var fileManager: FileManager
  public var fileURL: URL

  public init(
    fileURL: URL,
    fileManager: FileManager = .default,
    codec: WorkspaceJSONCodec<RouteID> = WorkspaceJSONCodec()
  ) {
    self.codec = codec
    self.fileManager = fileManager
    self.fileURL = fileURL
  }

  public func load() throws -> WorkspaceRestoration<RouteID>? {
    guard fileManager.fileExists(atPath: fileURL.path)
    else { return nil }

    return try codec.decode(Data(contentsOf: fileURL))
  }

  public func remove() throws {
    guard fileManager.fileExists(atPath: fileURL.path)
    else { return }

    try fileManager.removeItem(at: fileURL)
  }

  public func save(
    _ restorationState: WorkspaceRestoration<RouteID>
  ) throws {
    let directoryURL = fileURL.deletingLastPathComponent()
    try fileManager.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true
    )

    try codec.encode(restorationState).write(to: fileURL, options: .atomic)
  }
}
