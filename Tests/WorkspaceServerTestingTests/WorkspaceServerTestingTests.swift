import Comet
import CometTesting
import Foundation
import Testing
import WorkspaceServerClient
import WorkspaceServerTesting

@Test
func recordingReplayAndContractWorkflowUsesWorkspaceServerClient() async throws {
  let baseURL = URL(string: "https://workspace.example")!
  let session = WorkspaceServerContractWorkflow.recordingSession(
    baseURL: baseURL,
    baseTransport: MockTransport { request throws(NetworkError) in
      #expect(request.method.rawValue == "GET")
      #expect(request.url.path == "/v1/health")
      return try jsonResponse(
        WorkspaceServerHealth(status: "ok", version: "0.4.1")
      )
    }
  )

  let recordedHealth = try await session.client.health()
  #expect(recordedHealth.status == "ok")

  let cassette = await session.cassette()
  #expect(cassette.exchanges.count == 1)

  let replayClient = WorkspaceServerContractWorkflow.replayClient(
    baseURL: baseURL,
    cassette: cassette
  )
  let replayedHealth = try await replayClient.health()
  #expect(replayedHealth.version == "0.4.1")

  let contractSession = try WorkspaceServerContractWorkflow.contractSession(
    baseURL: baseURL,
    cassette: cassette
  )
  _ = try await contractSession.client.health()
  let report = await contractSession.report(
    generatedAt: Date(timeIntervalSince1970: 0)
  )

  #expect(report.passed)
  #expect(report.matches.map(\.expectationID) == ["cassette-1"])
  try await contractSession.verifyComplete()
}

private func jsonResponse<T: Encodable & Sendable>(
  _ value: T,
  statusCode: Int = 200
) throws(NetworkError) -> RawResponse {
  do {
    return RawResponse(
      data: try JSONEncoder().encode(value),
      statusCode: statusCode
    )
  } catch {
    throw NetworkError.from(error)
  }
}
