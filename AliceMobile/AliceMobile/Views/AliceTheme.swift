import SwiftUI

enum AliceTheme {
    static let background = Color(red: 0.012, green: 0.014, blue: 0.02)
    static let header = Color(red: 0.018, green: 0.021, blue: 0.031)
    static let panel = Color(red: 0.048, green: 0.054, blue: 0.072)
    static let panelRaised = Color(red: 0.07, green: 0.078, blue: 0.105)
    static let surface = Color(red: 0.102, green: 0.112, blue: 0.145)
    static let surfaceSoft = Color.white.opacity(0.055)
    static let border = Color.white.opacity(0.11)
    static let primaryText = Color(red: 0.94, green: 0.93, blue: 0.98)
    static let secondaryText = Color(red: 0.62, green: 0.63, blue: 0.72)
    static let mutedText = Color(red: 0.42, green: 0.43, blue: 0.5)
    static let mint = Color(red: 0.42, green: 0.93, blue: 0.76)
    static let amber = Color(red: 1.0, green: 0.74, blue: 0.36)
    static let rose = Color(red: 1.0, green: 0.49, blue: 0.59)
    static let lavender = Color(red: 0.72, green: 0.58, blue: 1.0)
    static let violet = Color(red: 0.58, green: 0.35, blue: 1.0)
    static let violetGlow = Color(red: 0.74, green: 0.54, blue: 1.0)
    static let blue = Color(red: 0.43, green: 0.72, blue: 1.0)
    static let red = Color(red: 1.0, green: 0.38, blue: 0.35)

    static func personaAccent(_ persona: CompanionPersona) -> Color {
        switch persona.avatarId {
        case "osa_shiro":
            return lavender
        case "osa_wambo":
            return amber
        default:
            return violetGlow
        }
    }

    static func stateColor(_ state: AvatarState) -> Color {
        switch state {
        case .thinking:
            return amber
        case .speaking:
            return violetGlow
        case .reacting, .headAction, .armAction, .legAction:
            return rose
        case .error:
            return red
        case .listening:
            return lavender
        default:
            return violetGlow
        }
    }

    static func healthColor(_ status: BackendHealthStatus) -> Color {
        switch status {
        case .available:
            return mint
        case .checking:
            return amber
        case .unavailable:
            return red
        case .unknown:
            return secondaryText
        }
    }
}

enum AliceMetrics {
    static let radius: CGFloat = 8
    static let spacing: CGFloat = 12
    static let outerPadding: CGFloat = 16
}

extension View {
    func alicePanel() -> some View {
        padding(14)
            .background(AliceTheme.panel, in: RoundedRectangle(cornerRadius: AliceMetrics.radius))
            .overlay(
                RoundedRectangle(cornerRadius: AliceMetrics.radius)
                    .stroke(AliceTheme.border, lineWidth: 1)
            )
    }
}
