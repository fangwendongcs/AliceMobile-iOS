import AVFoundation
import Foundation

@MainActor
protocol VoiceOutputing: AnyObject {
    func speak(_ text: String, voice: VoiceAffect, persona: CompanionPersona) async throws
    func stop()
}

enum VoiceOutputError: LocalizedError, Equatable {
    case emptyText

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "没有可播放的语音文本。"
        }
    }
}

@MainActor
final class AVSpeechVoiceOutput: NSObject, VoiceOutputing, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Error>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, voice: VoiceAffect, persona: CompanionPersona) async throws {
        stop()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw VoiceOutputError.emptyText
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = clampedRate(voice.rate, persona: persona)
        utterance.pitchMultiplier = min(max(Float(voice.pitch), 0.55), 1.8)
        utterance.volume = 1

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            continuation?.resume()
            continuation = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            continuation?.resume(throwing: CancellationError())
            continuation = nil
        }
    }

    private func clampedRate(_ rate: Double, persona: CompanionPersona) -> Float {
        let personaAdjustment: Double
        switch persona.avatarId {
        case "osa_shiro":
            personaAdjustment = 0.92
        case "osa_wambo":
            personaAdjustment = 1.08
        default:
            personaAdjustment = 1.0
        }

        let preferred = AVSpeechUtteranceDefaultSpeechRate * Float(rate * personaAdjustment)
        return min(max(preferred, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
    }
}
