import Combine
import Foundation

enum AppAPIMode: String, CaseIterable, Identifiable, Equatable {
    case mock
    case remote

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mock:
            return "Mock"
        case .remote:
            return "Remote"
        }
    }
}

enum BackendHealthStatus: Equatable {
    case unknown
    case checking
    case available
    case unavailable(String)

    var label: String {
        switch self {
        case .unknown:
            return "Not checked"
        case .checking:
            return "Checking"
        case .available:
            return "Ready"
        case .unavailable:
            return "Unavailable"
        }
    }
}

final class AppSettingsStore: ObservableObject {
    @Published var sessionId: String {
        didSet { defaults.set(sessionId, forKey: Keys.sessionId) }
    }

    @Published var selectedAvatarId: String {
        didSet { defaults.set(selectedAvatarId, forKey: Keys.selectedAvatarId) }
    }

    @Published var memoryEnabled: Bool {
        didSet { defaults.set(memoryEnabled, forKey: Keys.memoryEnabled) }
    }

    @Published var apiMode: AppAPIMode {
        didSet { defaults.set(apiMode.rawValue, forKey: Keys.apiMode) }
    }

    @Published var backendBaseURL: String {
        didSet { defaults.set(backendBaseURL, forKey: Keys.backendBaseURL) }
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

        let storedMode = defaults.string(forKey: Keys.apiMode)
        apiMode = AppAPIMode(rawValue: storedMode ?? "") ?? .mock

        backendBaseURL = defaults.string(forKey: Keys.backendBaseURL) ?? "http://127.0.0.1:3000"

        if storedSessionId == nil {
            defaults.set(sessionId, forKey: Keys.sessionId)
        }
        if storedAvatarId == nil {
            defaults.set(selectedAvatarId, forKey: Keys.selectedAvatarId)
        }
    }

    var remoteBaseURL: URL? {
        Self.normalizedURL(from: backendBaseURL)
    }

    func selectPersona(_ persona: CompanionPersona) {
        selectedAvatarId = persona.avatarId
    }

    static func normalizedURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        guard scheme == "http" || scheme == "https" else {
            return nil
        }
        return url
    }
}

private enum Keys {
    static let sessionId = "alice.mobile.sessionId"
    static let selectedAvatarId = "alice.mobile.selectedAvatarId"
    static let memoryEnabled = "alice.mobile.memoryEnabled"
    static let apiMode = "alice.mobile.apiMode"
    static let backendBaseURL = "alice.mobile.backendBaseURL"
}
