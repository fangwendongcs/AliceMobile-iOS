import Combine
import Foundation

final class SessionStore: ObservableObject {
    @Published var sessionId: String {
        didSet { defaults.set(sessionId, forKey: Keys.sessionId) }
    }

    @Published var selectedAvatarId: String {
        didSet { defaults.set(selectedAvatarId, forKey: Keys.selectedAvatarId) }
    }

    @Published var memoryEnabled: Bool {
        didSet { defaults.set(memoryEnabled, forKey: Keys.memoryEnabled) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedSessionId = defaults.string(forKey: Keys.sessionId)
        sessionId = storedSessionId ?? "ios-\(UUID().uuidString)"

        let storedAvatarId = defaults.string(forKey: Keys.selectedAvatarId)
        selectedAvatarId = storedAvatarId ?? CompanionPersona.fallback.avatarId

        if defaults.object(forKey: Keys.memoryEnabled) == nil {
            memoryEnabled = true
        } else {
            memoryEnabled = defaults.bool(forKey: Keys.memoryEnabled)
        }

        if storedSessionId == nil {
            defaults.set(sessionId, forKey: Keys.sessionId)
        }
        if storedAvatarId == nil {
            defaults.set(selectedAvatarId, forKey: Keys.selectedAvatarId)
        }
    }

    func selectPersona(_ persona: CompanionPersona) {
        selectedAvatarId = persona.avatarId
    }
}

private enum Keys {
    static let sessionId = "alice.mobile.sessionId"
    static let selectedAvatarId = "alice.mobile.selectedAvatarId"
    static let memoryEnabled = "alice.mobile.memoryEnabled"
}
