import Foundation

enum RiveAvatarAsset {
    static let fileName = "alice_avatar"
    static let fileExtension = "riv"
    static let expectedStateMachineName = "AliceAvatar"

    static var resourceName: String {
        "\(fileName).\(fileExtension)"
    }

    static func resourceURL(in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: fileName, withExtension: fileExtension)
    }

    static func status(in bundle: Bundle = .main) -> RiveAvatarAssetStatus {
        guard let url = resourceURL(in: bundle) else {
            return .missing(resourceName: resourceName)
        }
        return .available(resourceName: resourceName, url: url)
    }
}

enum RiveAvatarAssetStatus: Equatable {
    case available(resourceName: String, url: URL)
    case missing(resourceName: String)

    var isAvailable: Bool {
        switch self {
        case .available:
            return true
        case .missing:
            return false
        }
    }

    var label: String {
        switch self {
        case .available:
            return "Rive asset ready"
        case .missing:
            return "Using SwiftUI fallback"
        }
    }

    var detail: String {
        switch self {
        case .available(let resourceName, let url):
            return "\(resourceName) found in bundle: \(url.lastPathComponent)"
        case .missing(let resourceName):
            return "Add \(resourceName) to AliceMobile/AliceMobile to enable the Rive renderer."
        }
    }
}

enum RiveAvatarInput {
    static let avatarState = "avatar_state"
    static let emotion = "emotion"
    static let tone = "tone"
    static let intensity = "intensity"
    static let isSpeaking = "is_speaking"

    static func tapTrigger(for bodyPart: BodyPart) -> String {
        switch bodyPart {
        case .head:
            return "tap_head"
        case .arm:
            return "tap_arm"
        case .leg:
            return "tap_leg"
        case .body:
            return "tap_body"
        case .chat:
            return "tap_chat"
        }
    }
}

struct RiveAvatarStateMachinePayload: Equatable {
    var avatarState: Double
    var emotion: Double
    var tone: Double
    var intensity: Double
    var isSpeaking: Bool
}

enum RiveAvatarStateMachineBridge {
    static func payload(for context: AvatarRenderContext) -> RiveAvatarStateMachinePayload {
        RiveAvatarStateMachinePayload(
            avatarState: code(for: context.avatarState),
            emotion: code(for: context.affect.emotion),
            tone: code(for: context.affect.tone),
            intensity: context.affect.intensity,
            isSpeaking: context.isSpeaking
        )
    }

    static func code(for state: AvatarState) -> Double {
        switch state {
        case .boot:
            return 0
        case .entering:
            return 1
        case .idle:
            return 2
        case .listening:
            return 3
        case .thinking:
            return 4
        case .speaking:
            return 5
        case .reacting:
            return 6
        case .interrupted:
            return 7
        case .error:
            return 8
        case .headAction:
            return 9
        case .armAction:
            return 10
        case .legAction:
            return 11
        }
    }

    static func code(for emotion: Emotion) -> Double {
        switch emotion {
        case .neutral:
            return 0
        case .warm:
            return 1
        case .happy:
            return 2
        case .curious:
            return 3
        case .thinking:
            return 4
        case .apologetic:
            return 5
        case .concerned:
            return 6
        }
    }

    static func code(for tone: AffectTone) -> Double {
        switch tone {
        case .gentle:
            return 0
        case .playful:
            return 1
        case .calm:
            return 2
        case .encouraging:
            return 3
        }
    }
}
