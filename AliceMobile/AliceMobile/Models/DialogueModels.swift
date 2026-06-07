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

    init(
        reply: String,
        sources: [DialogueSource] = [],
        memory: MemoryState = .empty(),
        rag: RagState = .disabled,
        workflow: WorkflowState = .disabled,
        affect: Affect = Affect(),
        meta: DialogueMeta = DialogueMeta()
    ) {
        self.reply = reply
        self.sources = sources
        self.memory = memory
        self.rag = rag
        self.workflow = workflow
        self.affect = affect
        self.meta = meta
    }

    enum CodingKeys: String, CodingKey {
        case reply, sources, memory, rag, workflow, affect, meta
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reply = try container.decodeIfPresent(String.self, forKey: .reply) ?? ""
        sources = try container.decodeIfPresent([DialogueSource].self, forKey: .sources) ?? []
        memory = try container.decodeIfPresent(MemoryState.self, forKey: .memory) ?? .empty()
        rag = try container.decodeIfPresent(RagState.self, forKey: .rag) ?? .disabled
        workflow = try container.decodeIfPresent(WorkflowState.self, forKey: .workflow) ?? .disabled
        affect = try container.decodeIfPresent(Affect.self, forKey: .affect) ?? Affect()
        meta = try container.decodeIfPresent(DialogueMeta.self, forKey: .meta) ?? DialogueMeta()
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
}

struct LongTermMemory: Codable, Equatable {
    var used: Bool
    var status: String
    var count: Int
    var items: [MemoryItem]
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

    static let disabled = RagState(used: false, status: "disabled", passages: [])
}

struct WorkflowState: Codable, Equatable {
    var used: Bool
    var status: String
    var result: String?

    static let disabled = WorkflowState(used: false, status: "disabled", result: nil)
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
