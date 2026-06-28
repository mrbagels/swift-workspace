import Comet
import CometTesting
import Foundation
import Testing
import WorkspaceCore
@testable import WorkspaceServerClient

@Test
func serverClientRequestsUseTypedCometContracts() async throws {
  let client = WorkspaceServerClient(
    httpClient: .mock(baseURL: URL(string: "https://workspace.example")!) {
      (request: PreparedRequest) async throws(NetworkError) -> RawResponse in
      switch (request.method.rawValue, request.url.path) {
      case ("GET", "/v1/entitlements"):
        #expect(request.url.query == "user_id=user-1")
        #expect(request.metadata.operationID == "workspace.entitlements")
        #expect(request.metadata.tags == ["workspace-server", "entitlements"])
        return try jsonResponse(
          WorkspaceEntitlements(
            plan: "pro",
            features: ["templates": true],
            userID: "user-1"
          )
        )

      case ("GET", "/v1/templates"):
        #expect(request.metadata.operationID == "workspace.templates.list")
        return try jsonResponse(
          WorkspaceTemplateList(
            templates: [
              WorkspaceTemplateSummary(
                id: "daily-review",
                title: "Daily Review",
                tags: ["review"]
              ),
            ]
          )
        )

      case ("POST", "/v1/jobs"):
        #expect(request.body?.isEmpty == false)
        #expect(request.metadata.operationID == "workspace.jobs.submit")
        #expect(
          request.headers.first {
            $0.name.rawName.lowercased() == "idempotency-key"
          }?.value == "key-1"
        )
        return try jsonResponse(
          WorkspaceJobStatus(
            id: "job-1",
            phase: .queued,
            message: "Queued"
          )
        )

      case ("POST", "/v1/diagnostics"):
        #expect(request.body?.isEmpty == false)
        #expect(request.metadata.operationID == "workspace.diagnostics.upload")
        return try jsonResponse(
          WorkspaceDiagnosticsReceipt(
            accepted: true,
            receiptID: "receipt-1"
          )
        )

      default:
        throw NetworkError.invalidRequest(
          "Unexpected request \(request.method.rawValue) \(request.url.path)"
        )
      }
    }
  )

  let entitlements = try await client.entitlements(userID: "user-1")
  #expect(entitlements.plan == "pro")
  #expect(entitlements.features["templates"] == true)

  let templates = try await client.templates()
  #expect(templates.map { $0.id } == ["daily-review"])

  let job = try await client.submitJob(
    WorkspaceJobSubmission(
      kind: "template-render",
      parameters: ["template_id": "daily-review"],
      idempotencyKey: "key-1"
    )
  )
  #expect(job.id == "job-1")
  #expect(job.phase == WorkspaceJobPhase.queued)

  let receipt = try await client.uploadDiagnostics(
    WorkspaceDiagnosticsUpload(
      diagnostics: [
        WorkspaceDiagnostic(
          code: .duplicateShortcut,
          severity: .warning,
          message: "Shortcut conflict",
          path: "commands[0].shortcut"
        ),
      ],
      appBuild: "1",
      installationID: "install-1"
    )
  )
  #expect(receipt.accepted)
}

@Test
func jobStatusRequestEncodesJobIDInPath() async throws {
  let client = WorkspaceServerClient(
    httpClient: .mock(baseURL: URL(string: "https://workspace.example")!) {
      (request: PreparedRequest) async throws(NetworkError) -> RawResponse in
      #expect(request.method.rawValue == "GET")
      #expect(
        URLComponents(
          url: request.url,
          resolvingAgainstBaseURL: false
        )?.percentEncodedPath == "/v1/jobs/job%20with%20space"
      )
      return try jsonResponse(
        WorkspaceJobStatus(
          id: "job with space",
          phase: .succeeded,
          resultURL: URL(string: "https://workspace.example/results/job")
        )
      )
    }
  )

  let status = try await client.jobStatus(id: "job with space")
  #expect(status.phase == WorkspaceJobPhase.succeeded)
}

@Test
func diagnosticsUploadCanCarryCometEventSnapshots() throws {
  let requestID = UUID()
  let url = URL(string: "https://workspace.example/v1/templates")!
  let metadata = RequestMetadata(
    name: "Workspace Templates",
    tags: ["workspace-server", "templates"],
    operationID: "workspace.templates.list"
  )
  let retry = WorkspaceServerDiagnosticEvent(
    event: .requestRetried(
      id: requestID,
      attempt: 2,
      delay: .milliseconds(250),
      metadata: metadata
    )
  )
  let trace = RequestTrace(
    id: requestID,
    metadata: metadata,
    method: .get,
    url: url,
    attempts: [
      RequestTraceAttempt(
        number: 1,
        method: .get,
        url: url,
        requestBytes: 0,
        responseStatusCode: 200,
        responseBytes: 16,
        error: nil,
        duration: .milliseconds(10)
      ),
    ],
    duration: .milliseconds(10),
    result: .success(statusCode: 200, responseBytes: 16),
    traceContext: nil,
    cacheEvents: [
      RequestCacheTraceEvent(
        kind: .hit,
        key: HTTPCacheKey(method: .get, url: url),
        policy: .staleWhileRevalidate,
        reason: .cacheHit
      ),
    ]
  )
  let events = [retry, WorkspaceServerDiagnosticEvent(trace: trace)]
    + WorkspaceServerDiagnosticEvent.cacheEvents(for: trace)
  let upload = WorkspaceDiagnosticsUpload(
    diagnostics: [],
    serverEvents: events
  )

  let data = try JSONEncoder().encode(upload)
  let decoded = try JSONDecoder().decode(WorkspaceDiagnosticsUpload.self, from: data)

  #expect(decoded.serverEvents.count == 3)
  #expect(decoded.serverEvents.map(\.source) == [.http, .trace, .cache])
  #expect(decoded.serverEvents.first?.severity == .warning)
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
