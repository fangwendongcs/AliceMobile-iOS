import Foundation

protocol AliceAPIClienting {
    var modeLabel: String { get }

    func health() async throws -> Bool
    func sendDialogue(_ request: DialogueRequest) async throws -> DialogueResponse
    func fetchMemory(sessionId: String, avatarId: String) async throws -> MemoryState
}

enum AliceAPIClientMode {
    case mock
    case remote(baseURL: URL, authToken: String?)
}

struct APIEnvelope<T: Decodable>: Decodable {
    var ok: Bool
    var data: T?
    var error: APIErrorEnvelope?
}

struct APIErrorEnvelope: Decodable {
    var code: String?
    var message: String?
}

enum AliceAPIError: LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case backend(code: String?, message: String)
    case missingData
    case invalidBackendURL

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "后端响应格式不可用。"
        case .httpStatus(let status):
            return "后端 HTTP 状态异常：\(status)。"
        case .backend(_, let message):
            return message
        case .missingData:
            return "后端没有返回可用数据。"
        case .invalidBackendURL:
            return "后端地址不可用，请检查 Base URL。"
        }
    }
}

struct AliceAPIResponseDecoder {
    static func decodeDialogue(data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> DialogueResponse {
        if let envelope = try? decoder.decode(APIEnvelope<DialogueResponse>.self, from: data) {
            guard envelope.ok else {
                throw AliceAPIError.backend(
                    code: envelope.error?.code,
                    message: envelope.error?.message ?? "对话接口返回失败。"
                )
            }
            guard let response = envelope.data else {
                throw AliceAPIError.missingData
            }
            return response
        }

        return try decoder.decode(DialogueResponse.self, from: data)
    }
}

final class AliceAPIClient: AliceAPIClienting {
    private let mode: AliceAPIClientMode
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let mockResponder = MockDialogueResponder()

    var modeLabel: String {
        switch mode {
        case .mock:
            return "Mock"
        case .remote:
            return "Remote"
        }
    }

    init(mode: AliceAPIClientMode = .mock, session: URLSession = .shared) {
        self.mode = mode
        self.session = session
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func health() async throws -> Bool {
        switch mode {
        case .mock:
            return true
        case .remote(let baseURL, let authToken):
            var request = URLRequest(url: baseURL.appendingPathComponent("api").appendingPathComponent("health"))
            request.httpMethod = "GET"
            applyAuthHeader(authToken, to: &request)
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AliceAPIError.invalidResponse
            }
            return (200..<300).contains(httpResponse.statusCode)
        }
    }

    func sendDialogue(_ request: DialogueRequest) async throws -> DialogueResponse {
        switch mode {
        case .mock:
            return try await mockResponder.respond(to: request)
        case .remote(let baseURL, let authToken):
            return try await postDialogue(request, baseURL: baseURL, authToken: authToken)
        }
    }

    func fetchMemory(sessionId: String, avatarId: String) async throws -> MemoryState {
        switch mode {
        case .mock:
            return .empty(sessionId: sessionId, avatarId: avatarId, used: true)
        case .remote(let baseURL, let authToken):
            var components = URLComponents(url: baseURL.appendingPathComponent("api").appendingPathComponent("memory"), resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "sessionId", value: sessionId),
                URLQueryItem(name: "avatarId", value: avatarId),
                URLQueryItem(name: "limit", value: "20")
            ]
            guard let url = components?.url else {
                throw AliceAPIError.invalidResponse
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            applyAuthHeader(authToken, to: &request)
            let (data, response) = try await session.data(for: request)
            try validate(response: response)
            let envelope = try decoder.decode(APIEnvelope<MemoryEnvelope>.self, from: data)
            guard envelope.ok else {
                throw AliceAPIError.backend(
                    code: envelope.error?.code,
                    message: envelope.error?.message ?? "记忆接口返回失败。"
                )
            }
            return envelope.data?.memoryState(sessionId: sessionId, avatarId: avatarId) ?? .empty(sessionId: sessionId, avatarId: avatarId)
        }
    }

    private func postDialogue(_ requestBody: DialogueRequest, baseURL: URL, authToken: String?) async throws -> DialogueResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("api").appendingPathComponent("dialogue"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        request.httpBody = try encoder.encode(requestBody)
        applyAuthHeader(authToken, to: &request)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        return try AliceAPIResponseDecoder.decodeDialogue(data: data, decoder: decoder)
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AliceAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AliceAPIError.httpStatus(httpResponse.statusCode)
        }
    }

    private func applyAuthHeader(_ token: String?, to request: inout URLRequest) {
        guard let token, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

private struct MemoryEnvelope: Decodable {
    var sessionId: String?
    var avatarId: String?
    var longTerm: LongTermMemory?

    func memoryState(sessionId fallbackSessionId: String, avatarId fallbackAvatarId: String) -> MemoryState {
        MemoryState(
            used: true,
            status: longTerm?.status ?? "ready",
            sessionId: sessionId ?? fallbackSessionId,
            avatarId: avatarId ?? fallbackAvatarId,
            turnCount: nil,
            maxTurns: 6,
            longTerm: longTerm,
            longTermWrite: nil
        )
    }
}

private final class MockDialogueResponder {
    func respond(to request: DialogueRequest) async throws -> DialogueResponse {
        try await Task.sleep(nanoseconds: 240_000_000)

        let persona = CompanionPersona.find(avatarId: request.avatarId)
        let memory = MemoryState.empty(
            sessionId: request.sessionId,
            avatarId: persona.avatarId,
            used: request.options.useMemory
        )
        let memoryStatus = MemoryStatus(memory: memory)
        let affect = Affect(
            emotion: .warm,
            intensity: 0.42,
            tone: .gentle,
            reason: "mock_contract",
            voice: VoiceAffect(style: "gentle", rate: 1.02, pitch: 1.1),
            motion: MotionAffect(slot: .speaking, intensity: 0.42)
        )
        let avatarDirective = AvatarDirective(
            state: .speaking,
            motionSlot: .speaking,
            intensity: 0.42,
            durationMs: 900,
            returnTo: .idle,
            source: "mock_contract"
        )

        return DialogueResponse(
            reply: "\(persona.name) 已通过 Alice Core mock contract 返回：当前 iOS 只展示 reply、emotion、tone、avatar_state 和 memory 状态。",
            sources: [],
            memory: memory,
            rag: .disabled,
            workflow: .disabled,
            affect: affect,
            meta: DialogueMeta(
                mode: "ios_mock",
                orchestration: "mock_pipeline",
                steps: StepMeta(memory: memory.status, rag: "disabled", workflow: "disabled"),
                persona: PersonaMeta(persona: persona),
                provider: request.provider,
                model: request.model,
                note: "iOS MVP mock mode only. No real backend call was made."
            ),
            companionState: CompanionState(
                status: "mock",
                emotion: affect.emotion,
                tone: affect.tone,
                avatarState: avatarDirective.state,
                memoryStatus: memoryStatus,
                isMock: true
            ),
            avatarDirective: avatarDirective,
            memoryStatus: memoryStatus,
            ttsStatus: .notRequested
        )
    }
}
