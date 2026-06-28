import Comet
import CometTesting
import Foundation
import WorkspaceServerClient

/// A recording session for the workspace companion server client.
public struct WorkspaceServerRecordingSession: Sendable {
  public var client: WorkspaceServerClient
  public var recorder: RecordingTransport

  public init(
    client: WorkspaceServerClient,
    recorder: RecordingTransport
  ) {
    self.client = client
    self.recorder = recorder
  }

  public func cassette() async -> HTTPCassette {
    await recorder.cassette()
  }

  public func writeCassette(
    to url: URL,
    prettyPrinted: Bool = true
  ) async throws {
    try await recorder.writeCassette(to: url, prettyPrinted: prettyPrinted)
  }
}

/// A strict contract session for the workspace companion server client.
public struct WorkspaceServerContractSession: Sendable {
  public var client: WorkspaceServerClient
  public var transport: ContractTransport

  public init(
    client: WorkspaceServerClient,
    transport: ContractTransport
  ) {
    self.client = client
    self.transport = transport
  }

  public func report(generatedAt: Date = Date()) async -> ContractReport {
    await transport.report(generatedAt: generatedAt)
  }

  public func verifyComplete() async throws(NetworkError) {
    try await transport.verifyComplete()
  }

  public func writeReport(
    to url: URL,
    generatedAt: Date = Date(),
    prettyPrinted: Bool = true
  ) async throws {
    try await report(generatedAt: generatedAt).write(
      to: url,
      prettyPrinted: prettyPrinted
    )
  }
}

/// Helpers for the record, approve, replay, and contract loop around WorkspaceServerClient.
public enum WorkspaceServerContractWorkflow {
  public static let defaultRedaction = RecordingRedaction(
    redactedHeaders: RecordingRedaction.defaultSensitiveHeaders.union([
      "traceparent",
      "tracestate",
    ])
  )

  public static func recordingSession(
    baseURL: URL,
    baseTransport: some HTTPTransport,
    bearerToken: @escaping @Sendable () async -> String? = { nil },
    redaction: RecordingRedaction = WorkspaceServerContractWorkflow.defaultRedaction
  ) -> WorkspaceServerRecordingSession {
    let recorder = RecordingTransport(
      base: baseTransport,
      redaction: redaction
    )
    return WorkspaceServerRecordingSession(
      client: WorkspaceServerClient.live(
        baseURL: baseURL,
        bearerToken: bearerToken,
        transport: recorder
      ),
      recorder: recorder
    )
  }

  public static func replayClient(
    baseURL: URL,
    cassette: HTTPCassette,
    mode: ReplayTransport.Mode = .matchingRequest
  ) -> WorkspaceServerClient {
    WorkspaceServerClient.live(
      baseURL: baseURL,
      transport: ReplayTransport(cassette: cassette, mode: mode)
    )
  }

  public static func replayClient(
    baseURL: URL,
    cassetteURL: URL,
    mode: ReplayTransport.Mode = .matchingRequest
  ) throws -> WorkspaceServerClient {
    WorkspaceServerClient.live(
      baseURL: baseURL,
      transport: try ReplayTransport(contentsOf: cassetteURL, mode: mode)
    )
  }

  public static func contractSession(
    baseURL: URL,
    cassette: HTTPCassette
  ) throws(NetworkError) -> WorkspaceServerContractSession {
    let transport = try ContractTransport(cassette: cassette)
    return WorkspaceServerContractSession(
      client: WorkspaceServerClient.live(baseURL: baseURL, transport: transport),
      transport: transport
    )
  }

  public static func contractSession(
    baseURL: URL,
    cassetteURL: URL
  ) throws -> WorkspaceServerContractSession {
    try contractSession(
      baseURL: baseURL,
      cassette: HTTPCassette(contentsOf: cassetteURL)
    )
  }

  public static func runContract(
    baseURL: URL,
    cassette: HTTPCassette,
    generatedAt: Date = Date(),
    exercise: @Sendable (WorkspaceServerClient) async throws -> Void
  ) async throws -> ContractReport {
    let session = try contractSession(baseURL: baseURL, cassette: cassette)
    try await exercise(session.client)
    let report = await session.report(generatedAt: generatedAt)
    try await session.verifyComplete()
    return report
  }
}
