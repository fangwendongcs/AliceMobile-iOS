import Foundation

enum Emotion: String, Codable, CaseIterable, Identifiable, Equatable {
    case neutral
    case warm
    case happy
    case curious
    case thinking
    case apologetic
    case concerned

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = Emotion(rawValue: value) ?? .neutral
    }
}

enum AffectTone: String, Codable, CaseIterable, Identifiable, Equatable {
    case gentle
    case playful
    case calm
    case encouraging

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = AffectTone(rawValue: value) ?? .gentle
    }
}

struct VoiceAffect: Codable, Equatable {
    var style: String
    var rate: Double
    var pitch: Double

    static let gentle = VoiceAffect(style: "gentle", rate: 1.02, pitch: 1.1)
}

struct MotionAffect: Codable, Equatable {
    var slot: MotionSlot
    var intensity: Double

    static let idle = MotionAffect(slot: .idle, intensity: 0)
}

struct Affect: Codable, Equatable {
    var emotion: Emotion
    var intensity: Double
    var tone: AffectTone
    var reason: String
    var voice: VoiceAffect
    var motion: MotionAffect

    init(
        emotion: Emotion = .neutral,
        intensity: Double = 0.35,
        tone: AffectTone = .gentle,
        reason: String = "ios_default",
        voice: VoiceAffect = .gentle,
        motion: MotionAffect = .idle
    ) {
        self.emotion = emotion
        self.intensity = min(max(intensity, 0), 1)
        self.tone = tone
        self.reason = reason
        self.voice = voice
        self.motion = motion
    }

    static func `default`(for persona: CompanionPersona) -> Affect {
        Affect(
            emotion: .warm,
            intensity: 0.42,
            tone: persona.tone.contains("calm") ? .gentle : .encouraging,
            reason: "persona_default",
            voice: VoiceAffect(
                style: persona.defaultVoice.style,
                rate: persona.defaultVoice.rate,
                pitch: persona.defaultVoice.pitch
            ),
            motion: MotionAffect(slot: .idle, intensity: 0.3)
        )
    }
}
