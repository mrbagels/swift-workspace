import Foundation
import WorkspaceCore

/// Encodes and decodes workspace restoration payloads.
public struct WorkspaceJSONCodec<RouteID: Codable & Hashable & Sendable>: Sendable {
  public var decoder: JSONDecoder
  public var encoder: JSONEncoder

  public init(
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.decoder = decoder
    self.encoder = encoder
  }

  public func decode(
    _ data: Data
  ) throws -> WorkspaceRestoration<RouteID> {
    try decoder.decode(WorkspaceRestoration<RouteID>.self, from: data)
  }

  public func encode(
    _ restorationState: WorkspaceRestoration<RouteID>
  ) throws -> Data {
    try encoder.encode(restorationState)
  }
}

/// UserDefaults-backed storage for small workspace restoration payloads.
public struct WorkspaceUserDefaultsPersistence<RouteID: Codable & Hashable & Sendable> {
  public var codec: WorkspaceJSONCodec<RouteID>
  public var defaults: UserDefaults
  public var key: String

  public init(
    key: String,
    defaults: UserDefaults = .standard,
    codec: WorkspaceJSONCodec<RouteID> = WorkspaceJSONCodec()
  ) {
    self.codec = codec
    self.defaults = defaults
    self.key = key
  }

  public func load() throws -> WorkspaceRestoration<RouteID>? {
    guard let data = defaults.data(forKey: key)
    else { return nil }
    return try codec.decode(data)
  }

  public func remove() {
    defaults.removeObject(forKey: key)
  }

  public func save(
    _ restorationState: WorkspaceRestoration<RouteID>
  ) throws {
    defaults.set(try codec.encode(restorationState), forKey: key)
  }
}
