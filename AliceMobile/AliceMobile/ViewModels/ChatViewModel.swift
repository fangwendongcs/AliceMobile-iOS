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
    @Published var memoryEnabled: Bool {
        didSet {
            sessionStore.memoryEnabled = memoryEnabled
            memoryState = .empty(sessionId: sessionStore.sessionId, avatarId: selectedPersona.avatarId, used: memoryEnabled)
        }
    }

    let apiModeLabel: String
    let sessionId: String

    private let apiClient: AliceAPIClienting
    private let sessionStore: SessionStore
    private var lastUserMessage: String?

    init(
        apiClient: AliceAPIClienting? = nil,
        sessionStore: SessionStore? = nil
    ) {
        let resolvedAPIClient = apiClient ?? AliceAPIClient()
        let resolvedSessionStore = sessionStore ?? SessionStore()
        let resolvedPersona = CompanionPersona.find(avatarId: resolvedSessionStore.selectedAvatarId)
        let resolvedAffect = Affect.default(for: resolvedPersona)
        let resolvedMemory = MemoryState.empty(
            sessionId: resolvedSessionStore.sessionId,
            avatarId: resolvedPersona.avatarId,
            used: resolvedSessionStore.memoryEnabled
        )

        self.apiClient = resolvedAPIClient
        self.sessionStore = resolvedSessionStore
        personas = CompanionPersona.all
        selectedPersona = resolvedPersona
        draft = ""
        avatarState = .idle
        currentAffect = resolvedAffect
        memoryState = resolvedMemory
        memoryEnabled = resolvedSessionStore.memoryEnabled
        isSending = false
        errorMessage = nil
        interactionNote = "Avatar ready"
        apiModeLabel = resolvedAPIClient.modeLabel
        sessionId = resolvedSessionStore.sessionId
        messages = [
            ChatMessage(
                role: .assistant,
                text: "\(resolvedPersona.name) 已进入 iOS 原生 mock 模式。你可以切换角色、发送消息，并观察 emotion / tone / avatar_state。",
                personaName: resolvedPersona.name,
                affect: resolvedAffect
            )
        ]
    }

    func selectPersona(_ persona: CompanionPersona) {
        guard persona != selectedPersona else { return }
        selectedPersona = persona
        sessionStore.selectPersona(persona)
        currentAffect = Affect.default(for: persona)
        avatarState = .idle
        memoryState = .empty(sessionId: sessionId, avatarId: persona.avatarId, used: memoryEnabled)
        interactionNote = "Switched to \(persona.name)"
        messages.append(
            ChatMessage(
                role: .system,
                text: "已切换到 \(persona.name)：\(persona.summary)",
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
        interactionNote = "\(selectedPersona.name) handled \(bodyPart.motionSlot.rawValue)"
        scheduleIdleReturn()
    }

    func clearLocalTranscript() {
        messages = [
            ChatMessage(
                role: .assistant,
                text: "\(selectedPersona.name) 的本地聊天记录已清空。长期记忆以后端为准，当前未删除任何后端数据。",
                personaName: selectedPersona.name,
                affect: currentAffect
            )
        ]
        lastUserMessage = nil
        errorMessage = nil
        avatarState = .idle
    }

    private func send(_ text: String, markAsRegenerate: Bool = false) async {
        guard !isSending else { return }

        isSending = true
        errorMessage = nil
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
            let response = try await apiClient.sendDialogue(request)
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
            lastUserMessage = text
            scheduleIdleReturn()
        } catch {
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

        isSending = false
    }

    private func scheduleIdleReturn() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard let self, !self.isSending else { return }
            self.avatarState = .idle
            self.interactionNote = "Avatar ready"
        }
    }
}
