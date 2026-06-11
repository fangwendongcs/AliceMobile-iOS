import Combine
import Foundation

enum AppAPIMode: String, CaseIterable, Identifiable, Equatable {
    case mock
    case localhost
    case lan
    case remote

    var id: String { rawValue }

    static var allCases: [AppAPIMode] {
        [.mock, .localhost, .lan]
    }

    var label: String {
        switch self {
        case .mock:
            return "Mock"
        case .localhost:
            return "Localhost"
        case .lan:
            return "LAN IP"
        case .remote:
            return "Remote"
        }
    }

    var usesBackend: Bool {
        self != .mock
    }

    var allowsCustomBaseURL: Bool {
        self == .lan || self == .remote
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
            return "Connected"
        case .unavailable:
            return "Disconnected"
        }
    }
}

final class AppSettingsStore: ObservableObject {
    static let simulatorLocalhostBaseURL = "http://127.0.0.1:3000"
    static let lanBaseURLPlaceholder = "http://<mac-lan-ip>:3000"

    @Published var sessionId: String {
        didSet { defaults.set(sessionId, forKey: Keys.sessionId) }
    }

    @Published var selectedAvatarId: String {
        didSet { defaults.set(selectedAvatarId, forKey: Keys.selectedAvatarId) }
    }

    @Published var memoryEnabled: Bool {
        didSet { defaults.set(memoryEnabled, forKey: Keys.memoryEnabled) }
    }

    @Published var voiceOutputEnabled: Bool {
        didSet { defaults.set(voiceOutputEnabled, forKey: Keys.voiceOutputEnabled) }
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

        if defaults.object(forKey: Keys.voiceOutputEnabled) == nil {
            voiceOutputEnabled = true
        } else {
            voiceOutputEnabled = defaults.bool(forKey: Keys.voiceOutputEnabled)
        }

        apiMode = Self.normalizedAPIMode(from: defaults.string(forKey: Keys.apiMode))

        backendBaseURL = defaults.string(forKey: Keys.backendBaseURL) ?? ""

        if storedSessionId == nil {
            defaults.set(sessionId, forKey: Keys.sessionId)
        }
        if storedAvatarId == nil {
            defaults.set(selectedAvatarId, forKey: Keys.selectedAvatarId)
        }
    }

    var remoteBaseURL: URL? {
        Self.effectiveBackendBaseURL(mode: apiMode, lanBaseURL: backendBaseURL)
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

    static func normalizedAPIMode(from rawValue: String?) -> AppAPIMode {
        switch rawValue {
        case AppAPIMode.localhost.rawValue:
            return .localhost
        case AppAPIMode.lan.rawValue:
            return .lan
        case AppAPIMode.remote.rawValue:
            return .localhost
        case AppAPIMode.mock.rawValue:
            return .mock
        default:
            return .mock
        }
    }

    static func effectiveBackendBaseURLString(mode: AppAPIMode, lanBaseURL: String) -> String? {
        switch mode {
        case .mock:
            return nil
        case .localhost:
            return simulatorLocalhostBaseURL
        case .lan, .remote:
            let trimmed = lanBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    static func effectiveBackendBaseURL(mode: AppAPIMode, lanBaseURL: String) -> URL? {
        guard let value = effectiveBackendBaseURLString(mode: mode, lanBaseURL: lanBaseURL) else {
            return nil
        }
        return normalizedURL(from: value)
    }
}

private enum Keys {
    static let sessionId = "alice.mobile.sessionId"
    static let selectedAvatarId = "alice.mobile.selectedAvatarId"
    static let memoryEnabled = "alice.mobile.memoryEnabled"
    static let voiceOutputEnabled = "alice.mobile.voiceOutputEnabled"
    static let apiMode = "alice.mobile.apiMode"
    static let backendBaseURL = "alice.mobile.backendBaseURL"
}
