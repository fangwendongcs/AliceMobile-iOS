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
        }
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
        let memory = buildMemory(for: request, persona: persona)
        let affect = decideAffect(message: request.message, persona: persona, memory: memory)

        return DialogueResponse(
            reply: buildReply(for: request.message, persona: persona, memory: memory),
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
            )
        )
    }

    private func buildReply(for message: String, persona: CompanionPersona, memory: MemoryState) -> String {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)

        if asksForgetMemory(text) {
            return "可以，我不会把这句话写入长期记忆。要清除已经保存的内容，后续会走后端 /api/memory。"
        }
        if asksMemoryRecall(text) {
            if let count = memory.longTerm?.count, count > 0 {
                return "我记得你刚刚明确提到了一条偏好。当前是 iOS 本地 mock，真实长期记忆以后端为准。"
            }
            return "我现在还没有可用的长期记忆。你可以明确说“请记住：...”，后续会由后端判断是否适合保存。"
        }
        if containsMemoryIntent(text) {
            return "收到，我会把这类明确记忆意图交给后端处理。当前 mock 只展示记忆入口和状态，不在本地保存长期明文。"
        }
        if text.localizedCaseInsensitiveContains("状态") || text.localizedCaseInsensitiveContains("测试") || text.localizedCaseInsensitiveContains("你好") {
            return "\(persona.name) 现在处于 iOS 原生 mock 模式：聊天、角色、affect 和 avatar_state 链路已经跑通。"
        }
        if text.contains("为什么") || text.contains("怎么") || text.contains("如何") || text.contains("吗") || text.contains("?") || text.contains("？") {
            return "这是个好问题。我会先用本地状态给你一个轻量回应；接入后端后，会通过 /api/dialogue 拿到更完整的回答。"
        }
        return "\(persona.name) 已收到。第一阶段我先陪你跑通原生交互骨架，真实模型、TTS 和记忆都留给后端安全接入。"
    }

    private func buildMemory(for request: DialogueRequest, persona: CompanionPersona) -> MemoryState {
        guard request.options.useMemory else {
            return .empty(sessionId: request.sessionId, avatarId: persona.avatarId, used: false)
        }

        let shouldStore = containsMemoryIntent(request.message)
        let item = MemoryItem(
            id: 1,
            type: "preference",
            scope: "session",
            avatarId: persona.avatarId,
            sessionId: request.sessionId,
            content: "iOS mock captured an explicit memory intent.",
            confidence: 0.72,
            importance: 0.62,
            status: "mock",
            updatedAt: nil
        )

        return MemoryState(
            used: true,
            status: "ready",
            sessionId: request.sessionId,
            avatarId: persona.avatarId,
            turnCount: 1,
            maxTurns: 6,
            longTerm: LongTermMemory(
                used: true,
                status: "ready",
                count: shouldStore ? 1 : 0,
                items: shouldStore ? [item] : []
            ),
            longTermWrite: shouldStore ? LongTermWrite(stored: true, reason: "ios_mock_memory_intent") : nil
        )
    }

    private func decideAffect(message: String, persona: CompanionPersona, memory: MemoryState) -> Affect {
        let text = message.lowercased()

        if text.contains("失败") || text.contains("错误") || text.contains("不可用") {
            return Affect(
                emotion: .apologetic,
                intensity: 0.62,
                tone: .gentle,
                reason: "error_or_fallback",
                voice: VoiceAffect(style: "soft_gentle", rate: 0.96, pitch: 1.02),
                motion: MotionAffect(slot: .apologize, intensity: 0.5)
            )
        }
        if memory.longTermWrite?.stored == true || (memory.longTerm?.count ?? 0) > 0 {
            return Affect(
                emotion: .warm,
                intensity: 0.72,
                tone: .gentle,
                reason: "memory_context",
                voice: VoiceAffect(style: persona.defaultVoice.style, rate: persona.defaultVoice.rate, pitch: persona.defaultVoice.pitch),
                motion: MotionAffect(slot: .speaking, intensity: 0.45)
            )
        }
        if text.contains("谢谢") || text.contains("开心") || text.contains("喜欢") || text.contains("太好了") {
            return Affect(
                emotion: .happy,
                intensity: 0.68,
                tone: .playful,
                reason: "positive_text",
                voice: VoiceAffect(style: "bright_playful", rate: 1.12, pitch: 1.2),
                motion: MotionAffect(slot: .happy, intensity: 0.72)
            )
        }
        if text.contains("你好") || text.contains("hello") || text.contains("状态") || text.contains("测试") {
            return Affect(
                emotion: .warm,
                intensity: 0.48,
                tone: .gentle,
                reason: "smoke_test",
                voice: VoiceAffect(style: "gentle", rate: 1.02, pitch: 1.1),
                motion: MotionAffect(slot: .speaking, intensity: 0.45)
            )
        }
        if text.contains("为什么") || text.contains("怎么") || text.contains("如何") || text.contains("吗") || text.contains("?") || text.contains("？") {
            return Affect(
                emotion: .curious,
                intensity: 0.52,
                tone: .calm,
                reason: "question_text",
                voice: VoiceAffect(style: "thoughtful", rate: 0.98, pitch: 1.08),
                motion: MotionAffect(slot: .thinking, intensity: 0.55)
            )
        }
        if persona.tone.contains("playful") {
            return Affect(
                emotion: .warm,
                intensity: 0.5,
                tone: .encouraging,
                reason: "persona_default",
                voice: VoiceAffect(style: "playful_bright", rate: 1.08, pitch: 1.16),
                motion: MotionAffect(slot: .happy, intensity: 0.56)
            )
        }
        return Affect.default(for: persona)
    }

    private func containsMemoryIntent(_ text: String) -> Bool {
        text.contains("请记住") ||
            text.contains("帮我记住") ||
            text.contains("你要记得") ||
            text.contains("以后你要记得") ||
            text.contains("我的目标是") ||
            text.contains("我喜欢") ||
            text.contains("我不喜欢")
    }

    private func asksMemoryRecall(_ text: String) -> Bool {
        text.contains("你还记得") ||
            text.contains("还记得吗") ||
            text.contains("记得什么") ||
            text.contains("长期记忆")
    }

    private func asksForgetMemory(_ text: String) -> Bool {
        text.contains("忘记这个") ||
            text.contains("忘掉这个") ||
            text.contains("别记这个") ||
            text.contains("不要记这个") ||
            text.contains("删除记忆") ||
            text.contains("清除记忆")
    }
}
