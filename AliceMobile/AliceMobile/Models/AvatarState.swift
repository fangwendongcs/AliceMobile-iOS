import Foundation

enum AvatarState: String, Codable, CaseIterable, Identifiable, Equatable {
    case boot
    case entering
    case idle
    case listening
    case thinking
    case speaking
    case reacting
    case interrupted
    case error
    case headAction = "head_action"
    case armAction = "arm_action"
    case legAction = "leg_action"

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "interacting":
            self = .reacting
        default:
            self = AvatarState(rawValue: value) ?? .idle
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var displayName: String {
        switch self {
        case .boot:
            return "Boot"
        case .entering:
            return "Entering"
        case .idle:
            return "Idle"
        case .listening:
            return "Listening"
        case .thinking:
            return "Thinking"
        case .speaking:
            return "Speaking"
        case .reacting:
            return "Reacting"
        case .interrupted:
            return "Interrupted"
        case .error:
            return "Error"
        case .headAction:
            return "Head"
        case .armAction:
            return "Arm"
        case .legAction:
            return "Leg"
        }
    }
}

enum MotionSlot: String, Codable, CaseIterable, Equatable {
    case idle
    case intro
    case headTap
    case legTap
    case armTap
    case bodyTap
    case chat
    case speaking
    case listening
    case thinking
    case happy
    case apologize

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = MotionSlot(rawValue: value) ?? .bodyTap
    }
}

enum BodyPart: String, CaseIterable, Identifiable, Equatable {
    case head
    case arm
    case leg
    case body
    case chat

    var id: String { rawValue }

    var label: String {
        switch self {
        case .head:
            return "Head"
        case .arm:
            return "Arm"
        case .leg:
            return "Leg"
        case .body:
            return "Body"
        case .chat:
            return "Chat"
        }
    }

    var motionSlot: MotionSlot {
        switch self {
        case .head:
            return .headTap
        case .arm:
            return .armTap
        case .leg:
            return .legTap
        case .body:
            return .bodyTap
        case .chat:
            return .chat
        }
    }
}

enum AvatarEvent: Equatable {
    case appBooted
    case userStartedVoiceInput
    case userSentMessage
    case dialogueResponse(Affect)
    case audioStarted(Affect?)
    case audioEnded
    case userTappedBodyPart(BodyPart)
    case apiError(String)
}

struct AvatarStateReducer {
    static func reduce(current: AvatarState, event: AvatarEvent) -> AvatarState {
        switch event {
        case .appBooted:
            return .idle
        case .userStartedVoiceInput:
            return .listening
        case .userSentMessage:
            return .thinking
        case .dialogueResponse(let affect):
            return state(for: affect.motion.slot)
        case .audioStarted:
            return .speaking
        case .audioEnded:
            return .idle
        case .userTappedBodyPart(let bodyPart):
            return state(for: bodyPart.motionSlot)
        case .apiError:
            return .error
        }
    }

    static func state(for motionSlot: MotionSlot) -> AvatarState {
        switch motionSlot {
        case .idle:
            return .idle
        case .intro:
            return .entering
        case .headTap:
            return .headAction
        case .legTap:
            return .legAction
        case .armTap:
            return .armAction
        case .bodyTap, .chat, .happy:
            return .reacting
        case .speaking:
            return .speaking
        case .listening:
            return .listening
        case .thinking:
            return .thinking
        case .apologize:
            return .error
        }
    }

    static func state(for directive: AvatarDirective?, affect: Affect) -> AvatarState {
        if let directive {
            return directive.state
        }
        return state(for: affect.motion.slot)
    }
}
