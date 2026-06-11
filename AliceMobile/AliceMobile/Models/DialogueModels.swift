import Foundation

enum ChatRole: String, Codable, Equatable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Equatable {
    var id: UUID
    var role: ChatRole
    var text: String
    var personaName: String?
    var affect: Affect?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        role: ChatRole,
        text: String,
        personaName: String? = nil,
        affect: Affect? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.personaName = personaName
        self.affect = affect
        self.createdAt = createdAt
    }
}

struct DialogueRequest: Codable, Equatable {
    var message: String
    var sessionId: String
    var avatarId: String
    var provider: String
    var model: String
    var systemPrompt: String
    var options: DialogueOptions

    init(
        message: String,
        sessionId: String,
        avatarId: String,
        provider: String = "stub",
        model: String = "stub",
        systemPrompt: String = "",
        options: DialogueOptions
    ) {
        self.message = message
        self.sessionId = sessionId
        self.avatarId = avatarId
        self.provider = provider
        self.model = model
        self.systemPrompt = systemPrompt
        self.options = options
    }
}

struct DialogueOptions: Codable, Equatable {
    var useMemory: Bool
    var useRag: Bool
    var useWorkflow: Bool
    var avatarId: String

    static func mvpDefaults(avatarId: String, memoryEnabled: Bool) -> DialogueOptions {
        DialogueOptions(
            useMemory: memoryEnabled,
            useRag: false,
            useWorkflow: false,
            avatarId: avatarId
        )
    }
}

struct DialogueResponse: Codable, Equatable {
    var reply: String
    var sources: [DialogueSource]
    var memory: MemoryState
    var rag: RagState
    var workflow: WorkflowState
    var affect: Affect
    var meta: DialogueMeta
    var companionState: CompanionState
    var avatarDirective: AvatarDirective
    var memoryStatus: MemoryStatus
    var ttsStatus: TTSStatus

    init(
        reply: String,
        sources: [DialogueSource] = [],
        memory: MemoryState = .empty(),
        rag: RagState = .disabled,
        workflow: WorkflowState = .disabled,
        affect: Affect = Affect(),
        meta: DialogueMeta = DialogueMeta(),
        companionState: CompanionState? = nil,
        avatarDirective: AvatarDirective? = nil,
        memoryStatus: MemoryStatus? = nil,
        ttsStatus: TTSStatus = .notRequested
    ) {
        let resolvedMemoryStatus = memoryStatus ?? MemoryStatus(memory: memory)
        let resolvedAvatarDirective = avatarDirective ?? AvatarDirective(affect: affect)

        self.reply = reply
        self.sources = sources
        self.memory = memory
        self.rag = rag
        self.workflow = workflow
        self.affect = affect
        self.meta = meta
        self.memoryStatus = resolvedMemoryStatus
        self.avatarDirective = resolvedAvatarDirective
        self.companionState = companionState ?? CompanionState(
            status: meta.mode,
            emotion: affect.emotion,
            tone: affect.tone,
            avatarState: resolvedAvatarDirective.state,
            memoryStatus: resolvedMemoryStatus
        )
        self.ttsStatus = ttsStatus
    }

    enum CodingKeys: String, CodingKey {
        case reply, sources, memory, rag, workflow, affect, meta
        case replyText = "reply_text"
        case companionState = "companion_state"
        case emotion, tone
        case avatarDirective = "avatar_directive"
        case memoryStatus = "memory_status"
        case ttsStatus = "tts_status"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        reply = try container.decodeIfPresent(String.self, forKey: .reply)
            ?? container.decodeIfPresent(String.self, forKey: .replyText)
            ?? ""
        sources = try container.decodeIfPresent([DialogueSource].self, forKey: .sources) ?? []
        memory = try container.decodeIfPresent(MemoryState.self, forKey: .memory) ?? .empty()
        rag = try container.decodeIfPresent(RagState.self, forKey: .rag) ?? .disabled
        workflow = try container.decodeIfPresent(WorkflowState.self, forKey: .workflow) ?? .disabled
        meta = try container.decodeIfPresent(DialogueMeta.self, forKey: .meta) ?? DialogueMeta()

        let decodedAffect = try container.decodeIfPresent(Affect.self, forKey: .affect) ?? Affect()
        let decodedCompanionState = try container.decodeIfPresent(CompanionState.self, forKey: .companionState)
        let decodedAvatarDirective = try container.decodeIfPresent(AvatarDirective.self, forKey: .avatarDirective)
        let topLevelEmotion = try container.decodeIfPresent(Emotion.self, forKey: .emotion)
        let topLevelTone = try container.decodeIfPresent(AffectTone.self, forKey: .tone)
        memoryStatus = try container.decodeIfPresent(MemoryStatus.self, forKey: .memoryStatus) ?? MemoryStatus(memory: memory)
        ttsStatus = try container.decodeIfPresent(TTSStatus.self, forKey: .ttsStatus) ?? .notRequested

        let motionSlot = decodedAvatarDirective?.motionSlot ?? decodedAffect.motion.slot
        let motionIntensity = decodedAvatarDirective?.intensity ?? decodedAffect.motion.intensity
        affect = Affect(
            emotion: topLevelEmotion ?? decodedCompanionState?.emotion ?? decodedAffect.emotion,
            intensity: decodedAvatarDirective?.intensity ?? decodedAffect.intensity,
            tone: topLevelTone ?? decodedCompanionState?.tone ?? decodedAffect.tone,
            reason: decodedAffect.reason,
            voice: decodedAffect.voice,
            motion: MotionAffect(slot: motionSlot, intensity: motionIntensity)
        )

        avatarDirective = decodedAvatarDirective ?? AvatarDirective(affect: affect)
        companionState = decodedCompanionState ?? CompanionState(
            status: meta.mode,
            emotion: affect.emotion,
            tone: affect.tone,
            avatarState: avatarDirective.state,
            memoryStatus: memoryStatus
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reply, forKey: .reply)
        try container.encode(sources, forKey: .sources)
        try container.encode(memory, forKey: .memory)
        try container.encode(rag, forKey: .rag)
        try container.encode(workflow, forKey: .workflow)
        try container.encode(affect, forKey: .affect)
        try container.encode(meta, forKey: .meta)
        try container.encode(companionState, forKey: .companionState)
        try container.encode(avatarDirective, forKey: .avatarDirective)
        try container.encode(memoryStatus, forKey: .memoryStatus)
        try container.encode(ttsStatus, forKey: .ttsStatus)
    }
}

struct DialogueSource: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var url: String?
    var snippet: String?

    init(id: String = UUID().uuidString, title: String, url: String? = nil, snippet: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.snippet = snippet
    }
}

struct MemoryState: Codable, Equatable {
    var used: Bool
    var status: String
    var sessionId: String?
    var avatarId: String?
    var turnCount: Int?
    var maxTurns: Int?
    var longTerm: LongTermMemory?
    var longTermWrite: LongTermWrite?

    init(
        used: Bool,
        status: String,
        sessionId: String? = nil,
        avatarId: String? = nil,
        turnCount: Int? = nil,
        maxTurns: Int? = nil,
        longTerm: LongTermMemory? = nil,
        longTermWrite: LongTermWrite? = nil
    ) {
        self.used = used
        self.status = status
        self.sessionId = sessionId
        self.avatarId = avatarId
        self.turnCount = turnCount
        self.maxTurns = maxTurns
        self.longTerm = longTerm
        self.longTermWrite = longTermWrite
    }

    static func empty(sessionId: String? = nil, avatarId: String? = nil, used: Bool = true) -> MemoryState {
        MemoryState(
            used: used,
            status: used ? "ready" : "disabled",
            sessionId: sessionId,
            avatarId: avatarId,
            turnCount: 0,
            maxTurns: 6,
            longTerm: LongTermMemory(used: used, status: used ? "ready" : "disabled", count: 0, items: []),
            longTermWrite: nil
        )
    }

    enum CodingKeys: String, CodingKey {
        case used, status, sessionId, avatarId, turnCount, maxTurns, longTerm, longTermWrite
        case sessionID = "session_id"
        case avatarID = "avatar_id"
        case turnCountSnake = "turn_count"
        case maxTurnsSnake = "max_turns"
        case longTermSnake = "long_term"
        case longTermWriteSnake = "long_term_write"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        used = try container.decodeIfPresent(Bool.self, forKey: .used) ?? true
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? (used ? "ready" : "disabled")
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
            ?? container.decodeIfPresent(String.self, forKey: .sessionID)
        avatarId = try container.decodeIfPresent(String.self, forKey: .avatarId)
            ?? container.decodeIfPresent(String.self, forKey: .avatarID)
        turnCount = try container.decodeIfPresent(Int.self, forKey: .turnCount)
            ?? container.decodeIfPresent(Int.self, forKey: .turnCountSnake)
        maxTurns = try container.decodeIfPresent(Int.self, forKey: .maxTurns)
            ?? container.decodeIfPresent(Int.self, forKey: .maxTurnsSnake)
        longTerm = try container.decodeIfPresent(LongTermMemory.self, forKey: .longTerm)
            ?? container.decodeIfPresent(LongTermMemory.self, forKey: .longTermSnake)
        longTermWrite = try container.decodeIfPresent(LongTermWrite.self, forKey: .longTermWrite)
            ?? container.decodeIfPresent(LongTermWrite.self, forKey: .longTermWriteSnake)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(used, forKey: .used)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(avatarId, forKey: .avatarId)
        try container.encodeIfPresent(turnCount, forKey: .turnCount)
        try container.encodeIfPresent(maxTurns, forKey: .maxTurns)
        try container.encodeIfPresent(longTerm, forKey: .longTerm)
        try container.encodeIfPresent(longTermWrite, forKey: .longTermWrite)
    }
}

struct LongTermMemory: Codable, Equatable {
    var used: Bool
    var status: String
    var count: Int
    var items: [MemoryItem]

    init(used: Bool, status: String, count: Int, items: [MemoryItem]) {
        self.used = used
        self.status = status
        self.count = count
        self.items = items
    }

    enum CodingKeys: String, CodingKey {
        case used, status, count, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        used = try container.decodeIfPresent(Bool.self, forKey: .used) ?? true
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? (used ? "ready" : "disabled")
        items = try container.decodeIfPresent([MemoryItem].self, forKey: .items) ?? []
        count = try container.decodeIfPresent(Int.self, forKey: .count) ?? items.count
    }
}

struct LongTermWrite: Codable, Equatable {
    var stored: Bool
    var reason: String?
}

struct MemoryItem: Codable, Identifiable, Equatable {
    var id: Int
    var type: String
    var scope: String
    var avatarId: String
    var sessionId: String?
    var content: String
    var confidence: Double
    var importance: Double
    var status: String
    var updatedAt: String?
}

struct RagState: Codable, Equatable {
    var used: Bool
    var status: String
    var passages: [String]

    init(used: Bool, status: String, passages: [String]) {
        self.used = used
        self.status = status
        self.passages = passages
    }

    static let disabled = RagState(used: false, status: "disabled", passages: [])

    enum CodingKeys: String, CodingKey {
        case used, status, passages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        used = try container.decodeIfPresent(Bool.self, forKey: .used) ?? false
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? (used ? "ready" : "disabled")
        passages = try container.decodeIfPresent([String].self, forKey: .passages) ?? []
    }
}

struct WorkflowState: Codable, Equatable {
    var used: Bool
    var status: String
    var result: String?

    init(used: Bool, status: String, result: String?) {
        self.used = used
        self.status = status
        self.result = result
    }

    static let disabled = WorkflowState(used: false, status: "disabled", result: nil)

    enum CodingKeys: String, CodingKey {
        case used, status, result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        used = try container.decodeIfPresent(Bool.self, forKey: .used) ?? false
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? (used ? "ready" : "disabled")
        result = try container.decodeIfPresent(String.self, forKey: .result)
    }
}

typealias EmotionState = Emotion

struct CompanionState: Codable, Equatable {
    var status: String
    var emotion: Emotion?
    var tone: AffectTone?
    var avatarState: AvatarState?
    var memoryStatus: MemoryStatus?
    var isMock: Bool?

    init(
        status: String = "ready",
        emotion: Emotion? = nil,
        tone: AffectTone? = nil,
        avatarState: AvatarState? = nil,
        memoryStatus: MemoryStatus? = nil,
        isMock: Bool? = nil
    ) {
        self.status = status
        self.emotion = emotion
        self.tone = tone
        self.avatarState = avatarState
        self.memoryStatus = memoryStatus
        self.isMock = isMock
    }

    enum CodingKeys: String, CodingKey {
        case status, state, mode, emotion, tone, avatarState, memoryStatus, isMock
        case avatarStateSnake = "avatar_state"
        case memoryStatusSnake = "memory_status"
        case isMockSnake = "is_mock"
    }

    init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let status = try? singleValue.decode(String.self) {
            self.status = status
            emotion = nil
            tone = nil
            avatarState = nil
            memoryStatus = nil
            isMock = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status)
            ?? container.decodeIfPresent(String.self, forKey: .state)
            ?? container.decodeIfPresent(String.self, forKey: .mode)
            ?? "ready"
        emotion = try container.decodeIfPresent(Emotion.self, forKey: .emotion)
        tone = try container.decodeIfPresent(AffectTone.self, forKey: .tone)
        avatarState = try container.decodeIfPresent(AvatarState.self, forKey: .avatarState)
            ?? container.decodeIfPresent(AvatarState.self, forKey: .avatarStateSnake)
        memoryStatus = try container.decodeIfPresent(MemoryStatus.self, forKey: .memoryStatus)
            ?? container.decodeIfPresent(MemoryStatus.self, forKey: .memoryStatusSnake)
        isMock = try container.decodeIfPresent(Bool.self, forKey: .isMock)
            ?? container.decodeIfPresent(Bool.self, forKey: .isMockSnake)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(emotion, forKey: .emotion)
        try container.encodeIfPresent(tone, forKey: .tone)
        try container.encodeIfPresent(avatarState, forKey: .avatarStateSnake)
        try container.encodeIfPresent(memoryStatus, forKey: .memoryStatusSnake)
        try container.encodeIfPresent(isMock, forKey: .isMockSnake)
    }
}

struct AvatarDirective: Codable, Equatable {
    var state: AvatarState
    var motionSlot: MotionSlot
    var intensity: Double
    var durationMs: Int?
    var returnTo: AvatarState?
    var source: String

    init(
        state: AvatarState? = nil,
        motionSlot: MotionSlot = .idle,
        intensity: Double = 0,
        durationMs: Int? = nil,
        returnTo: AvatarState? = .idle,
        source: String = "contract"
    ) {
        self.motionSlot = motionSlot
        self.state = state ?? AvatarStateReducer.state(for: motionSlot)
        self.intensity = min(max(intensity, 0), 1)
        self.durationMs = durationMs
        self.returnTo = returnTo
        self.source = source
    }

    init(affect: Affect, source: String = "derived_from_affect") {
        self.init(
            state: AvatarStateReducer.state(for: affect.motion.slot),
            motionSlot: affect.motion.slot,
            intensity: affect.motion.intensity,
            durationMs: nil,
            returnTo: .idle,
            source: source
        )
    }

    enum CodingKeys: String, CodingKey {
        case state, avatarState, motionSlot, slot, intensity, durationMs, returnTo, source
        case avatarStateSnake = "avatar_state"
        case motionSlotSnake = "motion_slot"
        case durationMsSnake = "duration_ms"
        case returnToSnake = "return_to"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let motionSlot = try container.decodeIfPresent(MotionSlot.self, forKey: .motionSlot)
            ?? container.decodeIfPresent(MotionSlot.self, forKey: .motionSlotSnake)
            ?? container.decodeIfPresent(MotionSlot.self, forKey: .slot)
            ?? .idle
        let state = try container.decodeIfPresent(AvatarState.self, forKey: .state)
            ?? container.decodeIfPresent(AvatarState.self, forKey: .avatarState)
            ?? container.decodeIfPresent(AvatarState.self, forKey: .avatarStateSnake)
        let intensity = try container.decodeIfPresent(Double.self, forKey: .intensity) ?? 0

        self.init(
            state: state,
            motionSlot: motionSlot,
            intensity: intensity,
            durationMs: try container.decodeIfPresent(Int.self, forKey: .durationMs)
                ?? container.decodeIfPresent(Int.self, forKey: .durationMsSnake),
            returnTo: try container.decodeIfPresent(AvatarState.self, forKey: .returnTo)
                ?? container.decodeIfPresent(AvatarState.self, forKey: .returnToSnake),
            source: try container.decodeIfPresent(String.self, forKey: .source) ?? "contract"
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .avatarStateSnake)
        try container.encode(motionSlot, forKey: .motionSlotSnake)
        try container.encode(intensity, forKey: .intensity)
        try container.encodeIfPresent(durationMs, forKey: .durationMsSnake)
        try container.encodeIfPresent(returnTo, forKey: .returnToSnake)
        try container.encode(source, forKey: .source)
    }
}

struct MemoryStatus: Codable, Equatable {
    var used: Bool
    var status: String
    var longTermCount: Int
    var turnCount: Int?
    var maxTurns: Int?

    init(
        used: Bool = true,
        status: String = "ready",
        longTermCount: Int = 0,
        turnCount: Int? = nil,
        maxTurns: Int? = nil
    ) {
        self.used = used
        self.status = status
        self.longTermCount = longTermCount
        self.turnCount = turnCount
        self.maxTurns = maxTurns
    }

    init(memory: MemoryState) {
        self.init(
            used: memory.used,
            status: memory.status,
            longTermCount: memory.longTerm?.count ?? 0,
            turnCount: memory.turnCount,
            maxTurns: memory.maxTurns
        )
    }

    enum CodingKeys: String, CodingKey {
        case used, status, longTermCount, turnCount, maxTurns
        case longTermCountSnake = "long_term_count"
        case turnCountSnake = "turn_count"
        case maxTurnsSnake = "max_turns"
    }

    init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let status = try? singleValue.decode(String.self) {
            used = true
            self.status = status
            longTermCount = 0
            turnCount = nil
            maxTurns = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        used = try container.decodeIfPresent(Bool.self, forKey: .used) ?? true
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? (used ? "ready" : "disabled")
        longTermCount = try container.decodeIfPresent(Int.self, forKey: .longTermCount)
            ?? container.decodeIfPresent(Int.self, forKey: .longTermCountSnake)
            ?? 0
        turnCount = try container.decodeIfPresent(Int.self, forKey: .turnCount)
            ?? container.decodeIfPresent(Int.self, forKey: .turnCountSnake)
        maxTurns = try container.decodeIfPresent(Int.self, forKey: .maxTurns)
            ?? container.decodeIfPresent(Int.self, forKey: .maxTurnsSnake)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(used, forKey: .used)
        try container.encode(status, forKey: .status)
        try container.encode(longTermCount, forKey: .longTermCountSnake)
        try container.encodeIfPresent(turnCount, forKey: .turnCountSnake)
        try container.encodeIfPresent(maxTurns, forKey: .maxTurnsSnake)
    }
}

struct TTSStatus: Codable, Equatable {
    var used: Bool
    var status: String
    var provider: String?
    var voice: String?

    static let notRequested = TTSStatus(used: false, status: "not_requested", provider: nil, voice: nil)
    static let disabled = TTSStatus(used: false, status: "disabled", provider: "ios_avspeech", voice: nil)

    static func localSpeech(status: String, voice: String?) -> TTSStatus {
        TTSStatus(used: true, status: status, provider: "ios_avspeech", voice: voice)
    }

    init(used: Bool, status: String, provider: String? = nil, voice: String? = nil) {
        self.used = used
        self.status = status
        self.provider = provider
        self.voice = voice
    }

    enum CodingKeys: String, CodingKey {
        case used, status, provider, voice
    }

    init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let status = try? singleValue.decode(String.self) {
            used = status != "not_requested" && status != "disabled"
            self.status = status
            provider = nil
            voice = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        used = try container.decodeIfPresent(Bool.self, forKey: .used) ?? false
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? (used ? "ready" : "not_requested")
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        voice = try container.decodeIfPresent(String.self, forKey: .voice)
    }
}

struct DialogueMeta: Codable, Equatable {
    var mode: String
    var orchestration: String
    var steps: StepMeta?
    var persona: PersonaMeta?
    var provider: String
    var model: String
    var note: String?

    init(
        mode: String = "ios_mock",
        orchestration: String = "mock_pipeline",
        steps: StepMeta? = nil,
        persona: PersonaMeta? = nil,
        provider: String = "stub",
        model: String = "stub",
        note: String? = nil
    ) {
        self.mode = mode
        self.orchestration = orchestration
        self.steps = steps
        self.persona = persona
        self.provider = provider
        self.model = model
        self.note = note
    }
}

struct StepMeta: Codable, Equatable {
    var memory: String
    var rag: String
    var workflow: String
}

struct PersonaMeta: Codable, Equatable {
    var avatarId: String
    var personaId: String
    var name: String
    var tone: String
    var voiceStyle: String
    var motionStyle: String
    var memoryStrategy: String

    init(persona: CompanionPersona) {
        avatarId = persona.avatarId
        personaId = persona.personaId
        name = persona.name
        tone = persona.tone
        voiceStyle = persona.defaultVoice.style
        motionStyle = persona.defaultMotion.style
        memoryStrategy = persona.memoryStrategy
    }
}
