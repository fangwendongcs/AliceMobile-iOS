import Combine
import SwiftUI
#if canImport(RiveRuntime)
import RiveRuntime
#endif

enum AvatarRendererPreference: String, CaseIterable, Identifiable, Equatable {
    case rive
    case swiftUI

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rive:
            return "Rive"
        case .swiftUI:
            return "SwiftUI"
        }
    }
}

struct AvatarRenderContext: Equatable {
    var persona: CompanionPersona
    var avatarState: AvatarState
    var affect: Affect
    var activeBodyPart: BodyPart?

    var isSpeaking: Bool {
        avatarState == .speaking
    }
}

protocol AvatarRendering {
    func makeAvatarView(
        context: AvatarRenderContext,
        onTap: @escaping (BodyPart) -> Void
    ) -> AnyView
}

struct AvatarStageView: View {
    var preference: AvatarRendererPreference
    var context: AvatarRenderContext
    var onTap: (BodyPart) -> Void

    var body: some View {
        renderer.makeAvatarView(context: context, onTap: onTap)
    }

    private var renderer: AvatarRendering {
        switch preference {
        case .rive:
            return RiveAvatarRenderer()
        case .swiftUI:
            return SwiftUIAvatarRenderer()
        }
    }
}

struct SwiftUIAvatarRenderer: AvatarRendering {
    func makeAvatarView(
        context: AvatarRenderContext,
        onTap: @escaping (BodyPart) -> Void
    ) -> AnyView {
        AnyView(SwiftUIAvatarView(context: context, onTap: onTap))
    }
}

struct RiveAvatarRenderer: AvatarRendering {
    func makeAvatarView(
        context: AvatarRenderContext,
        onTap: @escaping (BodyPart) -> Void
    ) -> AnyView {
        AnyView(RiveAvatarView(context: context, onTap: onTap))
    }
}

struct RiveAvatarView: View {
    var context: AvatarRenderContext
    var onTap: (BodyPart) -> Void

    private var hasBundledRiveAsset: Bool {
        RiveAvatarAsset.status().isAvailable
    }

    var body: some View {
        if hasBundledRiveAsset {
            riveRuntimeView
        } else {
            fallbackView(status: "Rive asset missing")
        }
    }

    @ViewBuilder
    private var riveRuntimeView: some View {
#if canImport(RiveRuntime)
        RiveRuntimeAvatarView(context: context, onTap: onTap)
#else
        fallbackView(status: "RiveRuntime unavailable")
#endif
    }

    private func fallbackView(status: String) -> some View {
        ZStack(alignment: .topTrailing) {
            SwiftUIAvatarView(context: context, onTap: onTap)

            Label(status, systemImage: "sparkles")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AliceTheme.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(AliceTheme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
                .padding(10)
        }
        .accessibilityLabel("Avatar renderer fallback")
    }
}

#if canImport(RiveRuntime)
private struct RiveRuntimeAvatarView: View {
    var context: AvatarRenderContext
    var onTap: (BodyPart) -> Void

    @StateObject private var controller = RiveAvatarRuntimeController()

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                controller.view()
                    .frame(height: 430)
                    .background(
                        LinearGradient(
                            colors: [
                                SwiftUI.Color.black.opacity(0.28),
                                AliceTheme.personaAccent(context.persona).opacity(0.12),
                                SwiftUI.Color.black.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                Label("Rive", systemImage: "sparkles")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AliceTheme.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(AliceTheme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
                    .padding(10)
            }
            .overlay(alignment: .bottom) {
                BodyPartTapBar(activeBodyPart: context.activeBodyPart) { bodyPart in
                    controller.triggerTap(bodyPart)
                    onTap(bodyPart)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            VStack(spacing: 6) {
                Text(context.avatarState == .listening ? "正在感知你的声音" : "我在，慢慢说。")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AliceTheme.primaryText)
                Text("\(context.affect.emotion.rawValue) · \(context.affect.tone.rawValue) · \(String(format: "%.2f", context.affect.intensity))")
                    .font(.caption)
                    .foregroundStyle(AliceTheme.secondaryText)
            }
        }
        .alicePanel()
        .onAppear {
            controller.configure()
            controller.apply(context)
        }
        .onChange(of: context) { _, newContext in
            controller.apply(newContext)
        }
        .accessibilityLabel("Rive avatar renderer")
    }
}

@MainActor
private final class RiveAvatarRuntimeController: Combine.ObservableObject {
    private let viewModel = RiveViewModel(
        fileName: RiveAvatarAsset.fileName,
        stateMachineName: nil,
        fit: .contain,
        alignment: .center,
        autoPlay: true,
        loadCdn: false
    )

    func view() -> AnyView {
        viewModel.view()
    }

    func configure() {
        viewModel.setPreferredFramesPerSecond(preferredFramesPerSecond: 30)
    }

    func apply(_ context: AvatarRenderContext) {
        let payload = RiveAvatarStateMachineBridge.payload(for: context)
        viewModel.setInput(RiveAvatarInput.avatarState, value: payload.avatarState)
        viewModel.setInput(RiveAvatarInput.emotion, value: payload.emotion)
        viewModel.setInput(RiveAvatarInput.tone, value: payload.tone)
        viewModel.setInput(RiveAvatarInput.intensity, value: payload.intensity)
        viewModel.setInput(RiveAvatarInput.isSpeaking, value: payload.isSpeaking)
    }

    func triggerTap(_ bodyPart: BodyPart) {
        viewModel.triggerInput(RiveAvatarInput.tapTrigger(for: bodyPart))
    }
}
#endif

struct SwiftUIAvatarView: View {
    var context: AvatarRenderContext
    var onTap: (BodyPart) -> Void

    private var accent: SwiftUI.Color {
        AliceTheme.personaAccent(context.persona)
    }

    private var stateColor: SwiftUI.Color {
        AliceTheme.stateColor(context.avatarState)
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                SwiftUI.Color.black.opacity(0.28),
                                accent.opacity(0.13),
                                SwiftUI.Color.black.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                AvatarLightStreaks(color: stateColor)

                AliceCompanionSilhouette(
                    persona: context.persona,
                    state: context.avatarState,
                    color: stateColor
                )
                .padding(.top, 8)

                VStack {
                    Spacer()
                    VoiceWaveformView(color: stateColor, isActive: context.isSpeaking || context.avatarState == .listening)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 54)
                }
            }
            .frame(height: 430)
            .overlay(alignment: .bottom) {
                BodyPartTapBar(activeBodyPart: context.activeBodyPart, onTap: onTap)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }

            VStack(spacing: 6) {
                Text(context.avatarState == .listening ? "正在感知你的声音" : "我在，慢慢说。")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AliceTheme.primaryText)
                Text("\(context.affect.emotion.rawValue) · \(context.affect.tone.rawValue) · \(String(format: "%.2f", context.affect.intensity))")
                    .font(.caption)
                    .foregroundStyle(AliceTheme.secondaryText)
            }
        }
        .alicePanel()
    }

    private var avatarSymbol: String {
        switch context.avatarState {
        case .thinking:
            return "brain.head.profile"
        case .speaking:
            return "waveform"
        case .listening:
            return "ear"
        case .error:
            return "exclamationmark.triangle"
        case .headAction:
            return "person.crop.circle"
        case .armAction:
            return "hand.raised"
        case .legAction:
            return "figure.walk"
        default:
            return "person.crop.circle"
        }
    }
}

private struct AvatarLightStreaks: View {
    var color: SwiftUI.Color

    private let streaks: [(CGFloat, CGFloat, CGFloat)] = [
        (0.12, 84, 0.28),
        (0.22, 130, 0.2),
        (0.74, 96, 0.18),
        (0.86, 150, 0.24)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(streaks.indices, id: \.self) { index in
                let item = streaks[index]
                Capsule()
                    .fill(color.opacity(item.2))
                    .frame(width: 1, height: item.1)
                    .position(x: proxy.size.width * item.0, y: proxy.size.height * 0.44)
            }
        }
    }
}

private struct AliceCompanionSilhouette: View {
    var persona: CompanionPersona
    var state: AvatarState
    var color: SwiftUI.Color

    var body: some View {
        ZStack {
            Ellipse()
                .fill(SwiftUI.Color.black.opacity(0.48))
                .frame(width: 180, height: 270)
                .offset(y: 12)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [SwiftUI.Color(red: 0.08, green: 0.09, blue: 0.16), SwiftUI.Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 154, height: 240)
                .offset(y: 18)

            Circle()
                .fill(SwiftUI.Color(red: 0.94, green: 0.80, blue: 0.72))
                .frame(width: 72, height: 72)
                .offset(y: -78)

            HStack(spacing: 24) {
                Circle().fill(SwiftUI.Color(red: 0.12, green: 0.1, blue: 0.16)).frame(width: 7, height: 7)
                Circle().fill(SwiftUI.Color(red: 0.12, green: 0.1, blue: 0.16)).frame(width: 7, height: 7)
            }
            .offset(y: -82)

            RoundedRectangle(cornerRadius: 22)
                .fill(SwiftUI.Color(red: 0.055, green: 0.07, blue: 0.12))
                .frame(width: 112, height: 150)
                .offset(y: 18)

            RoundedRectangle(cornerRadius: 5)
                .fill(SwiftUI.Color(red: 0.82, green: 0.84, blue: 0.84))
                .frame(width: 46, height: 82)
                .offset(y: 8)

            Capsule()
                .fill(color.opacity(0.72))
                .frame(width: 44, height: 8)
                .offset(y: -18)

            RoundedRectangle(cornerRadius: 4)
                .fill(SwiftUI.Color(red: 0.10, green: 0.11, blue: 0.16))
                .frame(width: 116, height: 70)
                .offset(y: 114)

            Text(persona.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AliceTheme.primaryText.opacity(0.72))
                .offset(y: 168)
        }
        .frame(width: 220, height: 360)
        .scaleEffect(state == .reacting ? 1.025 : 1)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: state)
    }
}

private struct VoiceWaveformView: View {
    var color: SwiftUI.Color
    var isActive: Bool

    private let bars: [CGFloat] = [0.2, 0.32, 0.18, 0.46, 0.26, 0.64, 0.34, 0.9, 0.42, 0.7, 0.3, 0.5, 0.22, 0.36, 0.18]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(bars.indices, id: \.self) { index in
                Capsule()
                    .fill(color.opacity(index == bars.count / 2 ? 1 : 0.68))
                    .frame(width: 3, height: 42 * bars[index] * (isActive ? 1.18 : 0.72))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(SwiftUI.Color.black.opacity(0.26), in: Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: color.opacity(isActive ? 0.55 : 0.24), radius: isActive ? 18 : 8)
        .animation(.easeInOut(duration: 0.35), value: isActive)
    }
}

private struct BodyPartTapBar: View {
    var activeBodyPart: BodyPart?
    var onTap: (BodyPart) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BodyPart.allCases) { bodyPart in
                Button {
                    onTap(bodyPart)
                } label: {
                    Text(bodyPart.label)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                .foregroundStyle(activeBodyPart == bodyPart ? SwiftUI.Color.black : AliceTheme.primaryText)
                .background(activeBodyPart == bodyPart ? AliceTheme.mint : AliceTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct StatusPill: View {
    var title: String
    var value: String
    var color: SwiftUI.Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AliceTheme.secondaryText)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AliceTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.26), lineWidth: 1)
        )
    }
}
