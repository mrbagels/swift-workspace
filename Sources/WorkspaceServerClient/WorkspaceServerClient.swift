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

  public var activity: AsyncStream<NetworkEvent> {
    httpClient.activity
  }

  public var traces: AsyncStream<RequestTrace> {
    httpClient.traces
  }

  public static func configuration(
    baseURL: URL,
    bearerToken: @escaping @Sendable () async -> String? = { nil }
  ) -> ClientConfiguration {
    var configuration = ClientConfiguration.default(
      baseURL: baseURL,
      jsonPreset: .snakeCaseISO8601
    )
    configuration.middleware = [
      TracePropagationMiddleware(),
      BearerTokenMiddleware(tokenProvider: bearerToken),
      RetryMiddleware(),
    ]
    return configuration
  }

  public static func live(
    baseURL: URL,
    bearerToken: @escaping @Sendable () async -> String? = { nil }
  ) -> Self {
    Self.live(
      baseURL: baseURL,
      bearerToken: bearerToken,
      transport: URLSessionTransport()
    )
  }

  public static func live(
    baseURL: URL,
    bearerToken: @escaping @Sendable () async -> String? = { nil },
    transport: some HTTPTransport
  ) -> Self {
    Self(
      httpClient: .live(
        configuration: Self.configuration(
          baseURL: baseURL,
          bearerToken: bearerToken
        ),
        transport: transport
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
    public var options: RequestOptions {
      WorkspaceServerRequestOptions.make(
        name: "Workspace Server Health",
        operationID: "workspace.health",
        tags: ["health"],
        cachePolicy: .networkOnly,
        deduplicationKey: "workspace.health"
      )
    }
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
    public var options: RequestOptions {
      WorkspaceServerRequestOptions.make(
        name: "Workspace Entitlements",
        operationID: "workspace.entitlements",
        tags: ["entitlements"],
        cachePolicy: .networkOnly,
        deduplicationKey: "workspace.entitlements.\(userID ?? "current")"
      )
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
    public var options: RequestOptions {
      WorkspaceServerRequestOptions.make(
        name: "Workspace Templates",
        operationID: "workspace.templates.list",
        tags: ["templates"],
        cachePolicy: .staleWhileRevalidate,
        deduplicationKey: "workspace.templates"
      )
    }
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
    public var options: RequestOptions {
      WorkspaceServerRequestOptions.make(
        name: "Submit Workspace Job",
        operationID: "workspace.jobs.submit",
        tags: ["jobs"],
        cachePolicy: .networkOnly,
        idempotencyKey: submission.idempotencyKey,
        retryPolicy: .automatic
      )
    }
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
    public var options: RequestOptions {
      WorkspaceServerRequestOptions.make(
        name: "Workspace Job Status",
        operationID: "workspace.jobs.status",
        tags: ["jobs"],
        cachePolicy: .networkOnly,
        deduplicationKey: "workspace.jobs.status.\(id.rawValue)"
      )
    }
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
    public var options: RequestOptions {
      WorkspaceServerRequestOptions.make(
        name: "Upload Workspace Diagnostics",
        operationID: "workspace.diagnostics.upload",
        tags: ["diagnostics"],
        cachePolicy: .networkOnly,
        retryPolicy: .never
      )
    }
    public var responseSerializer: ResponseSerializer<WorkspaceDiagnosticsReceipt> {
      .json(WorkspaceDiagnosticsReceipt.self)
    }
  }
}

private enum WorkspaceServerRequestOptions {
  static let apiVersion = "v1"
  static let tags = ["workspace-server"]

  static func make(
    name: String,
    operationID: String,
    tags: [String],
    cachePolicy: HTTPCachePolicy,
    idempotencyKey: String? = nil,
    deduplicationKey: String? = nil,
    retryPolicy: RequestRetryPolicy? = .automatic
  ) -> RequestOptions {
    RequestOptions(
      apiVersion: Self.apiVersion,
      idempotencyKey: idempotencyKey,
      deduplicationKey: deduplicationKey,
      metadata: RequestMetadata(
        name: name,
        tags: Self.tags + tags,
        operationID: operationID
      ),
      retryPolicy: retryPolicy,
      cachePolicy: cachePolicy
    )
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

public enum WorkspaceServerDiagnosticSource: String, Codable, Equatable, Sendable {
  case cache
  case http
  case trace
}

public struct WorkspaceServerDiagnosticEvent: Codable, Equatable, Identifiable, Sendable {
  public var detail: String
  public var durationMilliseconds: Double?
  public var id: UUID
  public var kind: String
  public var method: String?
  public var occurredAt: Date?
  public var operationID: String?
  public var requestID: UUID?
  public var retryAttempt: Int?
  public var retryDelayMilliseconds: Double?
  public var severity: WorkspaceDiagnosticSeverity
  public var source: WorkspaceServerDiagnosticSource
  public var statusCode: Int?
  public var title: String
  public var traceID: String?
  public var url: URL?

  public init(
    id: UUID = UUID(),
    source: WorkspaceServerDiagnosticSource,
    kind: String,
    severity: WorkspaceDiagnosticSeverity,
    title: String,
    detail: String,
    requestID: UUID? = nil,
    method: String? = nil,
    url: URL? = nil,
    statusCode: Int? = nil,
    durationMilliseconds: Double? = nil,
    retryAttempt: Int? = nil,
    retryDelayMilliseconds: Double? = nil,
    traceID: String? = nil,
    operationID: String? = nil,
    occurredAt: Date? = nil
  ) {
    self.detail = detail
    self.durationMilliseconds = durationMilliseconds
    self.id = id
    self.kind = kind
    self.method = method
    self.occurredAt = occurredAt
    self.operationID = operationID
    self.requestID = requestID
    self.retryAttempt = retryAttempt
    self.retryDelayMilliseconds = retryDelayMilliseconds
    self.severity = severity
    self.source = source
    self.statusCode = statusCode
    self.title = title
    self.traceID = traceID
    self.url = url
  }

  public init(
    id: UUID = UUID(),
    event: NetworkEvent,
    occurredAt: Date? = nil
  ) {
    self.init(
      id: id,
      source: .http,
      kind: event.kind.rawValue,
      severity: event.workspaceDiagnosticSeverity,
      title: event.workspaceDiagnosticTitle,
      detail: event.diagnosticSummary,
      requestID: event.id,
      method: event.method?.rawValue,
      url: event.url,
      statusCode: event.statusCode ?? event.error?.statusCode,
      durationMilliseconds: event.duration?.workspaceMilliseconds,
      retryAttempt: event.retryAttempt,
      retryDelayMilliseconds: event.retryDelay?.workspaceMilliseconds,
      traceID: event.metadata.traceID,
      operationID: event.metadata.operationID,
      occurredAt: occurredAt
    )
  }

  public init(
    id: UUID = UUID(),
    trace: RequestTrace,
    occurredAt: Date? = nil
  ) {
    self.init(
      id: id,
      source: .trace,
      kind: trace.error == nil ? "completed" : "failed",
      severity: trace.error == nil ? .info : .error,
      title: "\(trace.metadata.displayName ?? "Request") trace",
      detail: trace.diagnosticSummary,
      requestID: trace.id,
      method: trace.method.rawValue,
      url: trace.url,
      statusCode: trace.statusCode ?? trace.error?.statusCode,
      durationMilliseconds: trace.duration.workspaceMilliseconds,
      traceID: trace.traceID,
      operationID: trace.metadata.operationID,
      occurredAt: occurredAt
    )
  }

  public static func cacheEvents(
    for trace: RequestTrace,
    occurredAt: Date? = nil
  ) -> [Self] {
    trace.cacheEvents.map { event in
      Self(
        source: .cache,
        kind: event.kind.rawValue,
        severity: .info,
        title: "\(trace.metadata.displayName ?? "Request") cache \(event.kind.rawValue)",
        detail: [
          event.reason.map { "reason \($0.rawValue)" },
          "key \(event.key.description)",
        ]
        .compactMap { $0 }
        .joined(separator: ", "),
        requestID: trace.id,
        method: trace.method.rawValue,
        url: trace.url,
        statusCode: trace.statusCode,
        traceID: trace.traceID,
        operationID: trace.metadata.operationID,
        occurredAt: occurredAt
      )
    }
  }
}

public struct WorkspaceDiagnosticsUpload: Codable, Equatable, Sendable {
  public var appBuild: String?
  public var diagnostics: [WorkspaceDiagnostic]
  public var generatedAt: Date?
  public var installationID: String?
  public var serverEvents: [WorkspaceServerDiagnosticEvent]

  public init(
    diagnostics: [WorkspaceDiagnostic],
    appBuild: String? = nil,
    installationID: String? = nil,
    serverEvents: [WorkspaceServerDiagnosticEvent] = [],
    generatedAt: Date? = nil
  ) {
    self.appBuild = appBuild
    self.diagnostics = diagnostics
    self.generatedAt = generatedAt
    self.installationID = installationID
    self.serverEvents = serverEvents
  }

  private enum CodingKeys: String, CodingKey {
    case appBuild
    case diagnostics
    case generatedAt
    case installationID
    case serverEvents
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.appBuild = try container.decodeIfPresent(String.self, forKey: .appBuild)
    self.diagnostics = try container.decode([WorkspaceDiagnostic].self, forKey: .diagnostics)
    self.generatedAt = try container.decodeIfPresent(Date.self, forKey: .generatedAt)
    self.installationID = try container.decodeIfPresent(String.self, forKey: .installationID)
    self.serverEvents = try container.decodeIfPresent(
      [WorkspaceServerDiagnosticEvent].self,
      forKey: .serverEvents
    ) ?? []
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(appBuild, forKey: .appBuild)
    try container.encode(diagnostics, forKey: .diagnostics)
    try container.encodeIfPresent(generatedAt, forKey: .generatedAt)
    try container.encodeIfPresent(installationID, forKey: .installationID)
    if !serverEvents.isEmpty {
      try container.encode(serverEvents, forKey: .serverEvents)
    }
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

private extension NetworkEvent {
  var workspaceDiagnosticSeverity: WorkspaceDiagnosticSeverity {
    return switch self {
    case .requestFailed:
      .error
    case .requestRetried:
      .warning
    case .requestCompleted,
      .requestStarted:
      .info
    }
  }

  var workspaceDiagnosticTitle: String {
    let name = displayName ?? "Request"
    return switch self {
    case .requestStarted:
      "\(name) started"
    case .requestCompleted:
      "\(name) completed"
    case .requestFailed:
      "\(name) failed"
    case .requestRetried:
      "\(name) retry"
    }
  }
}

private extension Duration {
  var workspaceMilliseconds: Double {
    let components = self.components
    let seconds = Double(components.seconds) * 1_000
    let attoseconds = Double(components.attoseconds) / 1_000_000_000_000_000
    return seconds + attoseconds
  }
}
