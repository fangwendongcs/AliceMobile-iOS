import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var personas: [CompanionPersona]
    @Published private(set) var selectedPersona: CompanionPersona
    @Published private(set) var messages: [ChatMessage]
    @Published var draft: String
    @Published private(set) var avatarState: AvatarState
    @Published private(set) var currentAffect: Affect
    @Published private(set) var memoryState: MemoryState
    @Published private(set) var isSending: Bool
    @Published private(set) var errorMessage: String?
    @Published private(set) var interactionNote: String
    @Published private(set) var healthStatus: BackendHealthStatus
    @Published private(set) var activeBodyPart: BodyPart?
    @Published var avatarRendererPreference: AvatarRendererPreference

    @Published var memoryEnabled: Bool {
        didSet {
            settingsStore.memoryEnabled = memoryEnabled
            memoryState = .empty(sessionId: settingsStore.sessionId, avatarId: selectedPersona.avatarId, used: memoryEnabled)
        }
    }

    @Published var apiMode: AppAPIMode {
        didSet {
            settingsStore.apiMode = apiMode
            healthStatus = apiMode == .mock ? .available : .unknown
        }
    }

    @Published var backendBaseURL: String {
        didSet {
            settingsStore.backendBaseURL = backendBaseURL
            if apiMode == .remote {
                healthStatus = .unknown
            }
        }
    }

    var apiModeLabel: String {
        apiMode.label
    }

    var sessionId: String {
        settingsStore.sessionId
    }

    var avatarRenderContext: AvatarRenderContext {
        AvatarRenderContext(
            persona: selectedPersona,
            avatarState: avatarState,
            affect: currentAffect,
            activeBodyPart: activeBodyPart
        )
    }

    private let settingsStore: AppSettingsStore
    private var lastUserMessage: String?

    init(settingsStore: AppSettingsStore? = nil) {
        let resolvedSettingsStore = settingsStore ?? AppSettingsStore()
        let resolvedPersona = CompanionPersona.find(avatarId: resolvedSettingsStore.selectedAvatarId)
        let resolvedAffect = Affect.default(for: resolvedPersona)
        let resolvedMemory = MemoryState.empty(
            sessionId: resolvedSettingsStore.sessionId,
            avatarId: resolvedPersona.avatarId,
            used: resolvedSettingsStore.memoryEnabled
        )

        self.settingsStore = resolvedSettingsStore
        personas = CompanionPersona.all
        selectedPersona = resolvedPersona
        draft = ""
        avatarState = .idle
        currentAffect = resolvedAffect
        memoryState = resolvedMemory
        memoryEnabled = resolvedSettingsStore.memoryEnabled
        apiMode = resolvedSettingsStore.apiMode
        backendBaseURL = resolvedSettingsStore.backendBaseURL
        isSending = false
        errorMessage = nil
        interactionNote = "Avatar ready"
        healthStatus = resolvedSettingsStore.apiMode == .mock ? .available : .unknown
        activeBodyPart = nil
        avatarRendererPreference = .rive
        messages = [
            ChatMessage(
                role: .assistant,
                text: "\(resolvedPersona.name) 已进入 iOS 原生体验模式。你可以切换角色、发送消息，并观察 Avatar 状态。",
                personaName: resolvedPersona.name,
                affect: resolvedAffect
            )
        ]
    }

    func selectPersona(_ persona: CompanionPersona) {
        guard persona != selectedPersona else { return }
        selectedPersona = persona
        settingsStore.selectPersona(persona)
        currentAffect = Affect.default(for: persona)
        avatarState = .idle
        activeBodyPart = nil
        memoryState = .empty(sessionId: sessionId, avatarId: persona.avatarId, used: memoryEnabled)
        interactionNote = "Switched to \(persona.name)"
        messages.append(
            ChatMessage(
                role: .system,
                text: "\(persona.name)：\(persona.summary)",
                personaName: persona.name,
                affect: currentAffect
            )
        )
    }

    func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        draft = ""
        Task {
            await send(text)
        }
    }

    func regenerateLastReply() {
        guard let lastUserMessage, !isSending else { return }
        Task {
            await send(lastUserMessage, markAsRegenerate: true)
        }
    }

    func triggerBodyPart(_ bodyPart: BodyPart) {
        activeBodyPart = bodyPart
        avatarState = AvatarStateReducer.reduce(current: avatarState, event: .userTappedBodyPart(bodyPart))
        currentAffect = Affect(
            emotion: .happy,
            intensity: 0.5,
            tone: selectedPersona.tone.contains("calm") ? .gentle : .playful,
            reason: "\(bodyPart.rawValue)_tap",
            voice: VoiceAffect(
                style: selectedPersona.defaultVoice.style,
                rate: selectedPersona.defaultVoice.rate,
                pitch: selectedPersona.defaultVoice.pitch
            ),
            motion: MotionAffect(slot: bodyPart.motionSlot, intensity: 0.55)
        )
        interactionNote = "\(bodyPart.motionSlot.rawValue)"
        scheduleIdleReturn()
    }

    func clearLocalTranscript() {
        messages = [
            ChatMessage(
                role: .assistant,
                text: "\(selectedPersona.name) 的本地聊天记录已清空。长期记忆以后端为准。",
                personaName: selectedPersona.name,
                affect: currentAffect
            )
        ]
        lastUserMessage = nil
        errorMessage = nil
        avatarState = .idle
        activeBodyPart = nil
    }

    func checkBackendHealth() {
        Task {
            await runHealthCheck()
        }
    }

    private func runHealthCheck() async {
        healthStatus = .checking
        do {
            let ok = try await makeAPIClient().health()
            healthStatus = ok ? .available : .unavailable("Health check failed.")
        } catch {
            healthStatus = .unavailable(error.localizedDescription)
        }
    }

    private func send(_ text: String, markAsRegenerate: Bool = false) async {
        guard !isSending else { return }

        isSending = true
        errorMessage = nil
        activeBodyPart = nil
        avatarState = AvatarStateReducer.reduce(current: avatarState, event: .userSentMessage)
        interactionNote = "Thinking"

        if !markAsRegenerate {
            messages.append(ChatMessage(role: .user, text: text))
        } else {
            messages.append(ChatMessage(role: .system, text: "重新生成上一条输入。"))
        }

        let request = DialogueRequest(
            message: text,
            sessionId: sessionId,
            avatarId: selectedPersona.avatarId,
            options: .mvpDefaults(avatarId: selectedPersona.avatarId, memoryEnabled: memoryEnabled)
        )

        do {
            let response = try await makeAPIClient().sendDialogue(request)
            applyDialogueResponse(response, userText: text)
        } catch {
            if apiMode == .remote {
                await applyRemoteFallback(for: request, userText: text, error: error)
            } else {
                applyDialogueError(error)
            }
        }

        isSending = false
    }

    private func applyRemoteFallback(for request: DialogueRequest, userText: String, error: Error) async {
        healthStatus = .unavailable(error.localizedDescription)
        do {
            let fallback = try await AliceAPIClient(mode: .mock).sendDialogue(request)
            errorMessage = "Remote 不可用，已回退 Mock：\(error.localizedDescription)"
            applyDialogueResponse(fallback, userText: userText)
        } catch {
            applyDialogueError(error)
        }
    }

    private func applyDialogueResponse(_ response: DialogueResponse, userText: String) {
        currentAffect = response.affect
        memoryState = response.memory
        avatarState = AvatarStateReducer.reduce(current: avatarState, event: .dialogueResponse(response.affect))
        interactionNote = response.affect.motion.slot.rawValue
        messages.append(
            ChatMessage(
                role: .assistant,
                text: response.reply,
                personaName: response.meta.persona?.name ?? selectedPersona.name,
                affect: response.affect
            )
        )
        lastUserMessage = userText
        scheduleIdleReturn()
    }

    private func applyDialogueError(_ error: Error) {
        let message = error.localizedDescription
        errorMessage = message
        avatarState = AvatarStateReducer.reduce(current: avatarState, event: .apiError(message))
        currentAffect = Affect(
            emotion: .apologetic,
            intensity: 0.62,
            tone: .gentle,
            reason: "api_error",
            voice: VoiceAffect(style: "soft_gentle", rate: 0.96, pitch: 1.02),
            motion: MotionAffect(slot: .apologize, intensity: 0.5)
        )
        messages.append(
            ChatMessage(
                role: .assistant,
                text: "抱歉，本地对话链路遇到问题：\(message)",
                personaName: selectedPersona.name,
                affect: currentAffect
            )
        )
        scheduleIdleReturn()
    }

    private func makeAPIClient() throws -> AliceAPIClient {
        switch apiMode {
        case .mock:
            return AliceAPIClient(mode: .mock)
        case .remote:
            guard let url = AppSettingsStore.normalizedURL(from: backendBaseURL) else {
                throw AliceAPIError.invalidBackendURL
            }
            return AliceAPIClient(mode: .remote(baseURL: url, authToken: nil))
        }
    }

    private func scheduleIdleReturn() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard let self, !self.isSending else { return }
            self.avatarState = .idle
            self.activeBodyPart = nil
            self.interactionNote = "Avatar ready"
        }
    }
}
