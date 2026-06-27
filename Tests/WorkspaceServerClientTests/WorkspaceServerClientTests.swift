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
        return try jsonResponse(
          WorkspaceEntitlements(
            plan: "pro",
            features: ["templates": true],
            userID: "user-1"
          )
        )

      case ("GET", "/v1/templates"):
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
        return try jsonResponse(
          WorkspaceJobStatus(
            id: "job-1",
            phase: .queued,
            message: "Queued"
          )
        )

      case ("POST", "/v1/diagnostics"):
        #expect(request.body?.isEmpty == false)
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
