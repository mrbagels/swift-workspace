import Comet
import CometTCA
import ComposableArchitecture
import Foundation
import WorkspaceCore

/// Optional typed client for thin workspace companion services.
public struct WorkspaceServerClient: Sendable {
  public var httpClient: HTTPClient

  public init(httpClient: HTTPClient) {
    self.httpClient = httpClient
  }

  public static func live(
    baseURL: URL,
    bearerToken: @escaping @Sendable () async -> String? = { nil }
  ) -> Self {
    var configuration = ClientConfiguration.default(
      baseURL: baseURL,
      jsonPreset: .snakeCaseISO8601
    )
    configuration.middleware = [
      BearerTokenMiddleware(tokenProvider: bearerToken),
      RetryMiddleware(),
    ]
    return Self(
      httpClient: .live(
        configuration: configuration,
        transport: URLSessionTransport()
      )
    )
  }

  public func health() async throws(NetworkError) -> WorkspaceServerHealth {
    try await httpClient.send(WorkspaceServerRequests.Health())
  }

  public func entitlements(
    userID: String? = nil
  ) async throws(NetworkError) -> WorkspaceEntitlements {
    try await httpClient.send(WorkspaceServerRequests.Entitlements(userID: userID))
  }

  public func templates() async throws(NetworkError) -> [WorkspaceTemplateSummary] {
    try await httpClient.send(WorkspaceServerRequests.Templates()).templates
  }

  public func submitJob(
    _ submission: WorkspaceJobSubmission
  ) async throws(NetworkError) -> WorkspaceJobStatus {
    try await httpClient.send(WorkspaceServerRequests.SubmitJob(submission: submission))
  }

  public func jobStatus(
    id: WorkspaceJobID
  ) async throws(NetworkError) -> WorkspaceJobStatus {
    try await httpClient.send(WorkspaceServerRequests.JobStatus(id: id))
  }

  public func uploadDiagnostics(
    _ upload: WorkspaceDiagnosticsUpload
  ) async throws(NetworkError) -> WorkspaceDiagnosticsReceipt {
    try await httpClient.send(WorkspaceServerRequests.UploadDiagnostics(upload: upload))
  }
}

public extension Effect where Action: Sendable {
  static func workspaceServerRequest<R: APIRequest>(
    _ request: R,
    using client: WorkspaceServerClient,
    map: @escaping @Sendable (Result<R.Response, NetworkError>) -> Action
  ) -> Self {
    .request(request, using: client.httpClient, map: map)
  }
}

public enum WorkspaceServerRequests {
  public struct Health: APIRequest {
    public typealias Response = WorkspaceServerHealth

    public init() {}

    public var path: Path { "health" }
    public var method: HTTPMethod { .get }
    public var responseSerializer: ResponseSerializer<WorkspaceServerHealth> {
      .json(WorkspaceServerHealth.self)
    }
  }

  public struct Entitlements: APIRequest {
    public typealias Response = WorkspaceEntitlements

    public var userID: String?

    public init(userID: String? = nil) {
      self.userID = userID
    }

    public var path: Path { "entitlements" }
    public var method: HTTPMethod { .get }
    public var queryItems: [QueryItem] {
      userID.map { [QueryItem("user_id", $0)] } ?? []
    }
    public var responseSerializer: ResponseSerializer<WorkspaceEntitlements> {
      .json(WorkspaceEntitlements.self)
    }
  }

  public struct Templates: APIRequest {
    public typealias Response = WorkspaceTemplateList

    public init() {}

    public var path: Path { "templates" }
    public var method: HTTPMethod { .get }
    public var responseSerializer: ResponseSerializer<WorkspaceTemplateList> {
      .json(WorkspaceTemplateList.self)
    }
  }

  public struct SubmitJob: APIRequest {
    public typealias Response = WorkspaceJobStatus

    public var submission: WorkspaceJobSubmission

    public init(submission: WorkspaceJobSubmission) {
      self.submission = submission
    }

    public var path: Path { "jobs" }
    public var method: HTTPMethod { .post }
    public var body: HTTPBody { .json(submission) }
    public var responseSerializer: ResponseSerializer<WorkspaceJobStatus> {
      .json(WorkspaceJobStatus.self)
    }
  }

  public struct JobStatus: APIRequest {
    public typealias Response = WorkspaceJobStatus

    public var id: WorkspaceJobID

    public init(id: WorkspaceJobID) {
      self.id = id
    }

    public var path: Path { Path("jobs") / id.rawValue }
    public var method: HTTPMethod { .get }
    public var responseSerializer: ResponseSerializer<WorkspaceJobStatus> {
      .json(WorkspaceJobStatus.self)
    }
  }

  public struct UploadDiagnostics: APIRequest {
    public typealias Response = WorkspaceDiagnosticsReceipt

    public var upload: WorkspaceDiagnosticsUpload

    public init(upload: WorkspaceDiagnosticsUpload) {
      self.upload = upload
    }

    public var path: Path { "diagnostics" }
    public var method: HTTPMethod { .post }
    public var body: HTTPBody { .json(upload) }
    public var responseSerializer: ResponseSerializer<WorkspaceDiagnosticsReceipt> {
      .json(WorkspaceDiagnosticsReceipt.self)
    }
  }
}

public struct WorkspaceServerHealth: Codable, Equatable, Sendable {
  public var service: String
  public var status: String
  public var version: String?

  public init(service: String = "workspace-server", status: String, version: String? = nil) {
    self.service = service
    self.status = status
    self.version = version
  }
}

public struct WorkspaceEntitlements: Codable, Equatable, Sendable {
  public var features: [String: Bool]
  public var plan: String
  public var userID: String?

  public init(
    plan: String,
    features: [String: Bool] = [:],
    userID: String? = nil
  ) {
    self.features = features
    self.plan = plan
    self.userID = userID
  }
}

public struct WorkspaceTemplateList: Codable, Equatable, Sendable {
  public var templates: [WorkspaceTemplateSummary]

  public init(templates: [WorkspaceTemplateSummary] = []) {
    self.templates = templates
  }
}

public struct WorkspaceTemplateSummary: Codable, Equatable, Identifiable, Sendable {
  public var id: String
  public var title: String
  public var description: String?
  public var tags: [String]

  public init(
    id: String,
    title: String,
    description: String? = nil,
    tags: [String] = []
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.tags = tags
  }
}

public struct WorkspaceJobID:
  Codable,
  CustomStringConvertible,
  Equatable,
  ExpressibleByStringLiteral,
  Hashable,
  RawRepresentable,
  Sendable
{
  public var rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String { rawValue }
}

public struct WorkspaceJobSubmission: Codable, Equatable, Sendable {
  public var kind: String
  public var parameters: [String: String]
  public var idempotencyKey: String?

  public init(
    kind: String,
    parameters: [String: String] = [:],
    idempotencyKey: String? = nil
  ) {
    self.kind = kind
    self.parameters = parameters
    self.idempotencyKey = idempotencyKey
  }
}

public enum WorkspaceJobPhase: String, Codable, Equatable, Sendable {
  case queued
  case running
  case succeeded
  case failed
  case cancelled
}

public struct WorkspaceJobStatus: Codable, Equatable, Identifiable, Sendable {
  public var id: WorkspaceJobID
  public var phase: WorkspaceJobPhase
  public var message: String?
  public var resultURL: URL?

  public init(
    id: WorkspaceJobID,
    phase: WorkspaceJobPhase,
    message: String? = nil,
    resultURL: URL? = nil
  ) {
    self.id = id
    self.phase = phase
    self.message = message
    self.resultURL = resultURL
  }
}

public struct WorkspaceDiagnosticsUpload: Codable, Equatable, Sendable {
  public var appBuild: String?
  public var diagnostics: [WorkspaceDiagnostic]
  public var installationID: String?

  public init(
    diagnostics: [WorkspaceDiagnostic],
    appBuild: String? = nil,
    installationID: String? = nil
  ) {
    self.appBuild = appBuild
    self.diagnostics = diagnostics
    self.installationID = installationID
  }
}

public struct WorkspaceDiagnosticsReceipt: Codable, Equatable, Sendable {
  public var accepted: Bool
  public var receiptID: String

  public init(accepted: Bool, receiptID: String) {
    self.accepted = accepted
    self.receiptID = receiptID
  }
}
