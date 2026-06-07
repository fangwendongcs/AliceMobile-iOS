import SwiftUI

struct CompanionHomeView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var isShowingSettings = false

    var body: some View {
        ZStack {
            AliceTheme.background.ignoresSafeArea()
            ImmersiveBackground()

            VStack(spacing: 0) {
                TopChromeBar(viewModel: viewModel, isShowingSettings: $isShowingSettings)

                ScrollView {
                    VStack(spacing: 12) {
                        PersonaSwitcher(viewModel: viewModel)

                        AvatarStageView(
                            preference: viewModel.avatarRendererPreference,
                            context: viewModel.avatarRenderContext,
                            onTap: viewModel.triggerBodyPart
                        )

                        StatusStrip(viewModel: viewModel)
                        MemorySummary(viewModel: viewModel)
                        ChatTranscript(viewModel: viewModel)
                    }
                    .padding(.horizontal, AliceMetrics.outerPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 18)
                }
                .scrollDismissesKeyboard(.interactively)

                ChatInputBar(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }
}

private struct TopChromeBar: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isShowingSettings: Bool

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                Button("Regenerate") {
                    viewModel.regenerateLastReply()
                }
                Button("Clear Chat", role: .destructive) {
                    viewModel.clearLocalTranscript()
                }
            } label: {
                CircleIcon(systemName: "line.3.horizontal")
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Alice")
                    .font(.system(size: 31, weight: .light, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, AliceTheme.violetGlow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("你 的 AI 陪 伴 者")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AliceTheme.secondaryText)
            }

            Spacer()

            Button {
                isShowingSettings = true
            } label: {
                CircleIcon(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, AliceMetrics.outerPadding)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(AliceTheme.header)
    }
}

private struct CircleIcon: View {
    var systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 38, height: 38)
            .foregroundStyle(AliceTheme.primaryText)
            .background(Color.black.opacity(0.28), in: Circle())
            .overlay(
                Circle()
                    .stroke(AliceTheme.border, lineWidth: 1)
            )
    }
}

private struct PersonaSwitcher: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.personas) { persona in
                Button {
                    viewModel.selectPersona(persona)
                } label: {
                    VStack(spacing: 4) {
                        Text(persona.name)
                            .font(.subheadline.weight(.semibold))
                        Text(persona.tone)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(viewModel.selectedPersona == persona ? Color.black : AliceTheme.primaryText)
                    .background(
                        AliceTheme.personaAccent(persona)
                            .opacity(viewModel.selectedPersona == persona ? 1 : 0.14),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AliceTheme.personaAccent(persona).opacity(0.38), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct StatusStrip: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatusPill(title: "mode", value: viewModel.apiModeLabel, color: viewModel.apiMode == .mock ? AliceTheme.secondaryText : AliceTheme.mint)
            StatusPill(title: "connection", value: viewModel.connectionStateLabel, color: AliceTheme.healthColor(viewModel.healthStatus))
            StatusPill(title: "backend_url", value: viewModel.currentBackendBaseURLDisplay, color: AliceTheme.secondaryText)
            StatusPill(title: "avatar_state", value: viewModel.avatarState.rawValue, color: AliceTheme.stateColor(viewModel.avatarState))
            StatusPill(title: "emotion_tone", value: emotionToneLabel, color: AliceTheme.violetGlow)
            StatusPill(title: "tts", value: viewModel.ttsStatus.status, color: AliceTheme.amber)
        }
    }

    private var emotionToneLabel: String {
        "\(viewModel.currentAffect.emotion.rawValue) / \(viewModel.currentAffect.tone.rawValue)"
    }
}

private struct MemorySummary: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        HStack(spacing: 10) {
            Label("Memory", systemImage: "memorychip")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AliceTheme.primaryText)

            Text(viewModel.memoryEnabled ? viewModel.memoryState.status : "disabled")
                .font(.caption.weight(.semibold))
                .foregroundStyle(viewModel.memoryEnabled ? AliceTheme.mint : AliceTheme.secondaryText)

            Spacer()

            Text("\(viewModel.memoryState.longTerm?.count ?? 0) long-term")
                .font(.caption.weight(.medium))
                .foregroundStyle(AliceTheme.secondaryText)

            Toggle("", isOn: $viewModel.memoryEnabled)
                .labelsHidden()
                .tint(AliceTheme.mint)
        }
        .padding(12)
        .background(AliceTheme.panel, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AliceTheme.border, lineWidth: 1)
        )
    }
}

private struct ChatTranscript: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    viewModel.regenerateLastReply()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AliceTheme.primaryText)
                .background(AliceTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                .disabled(viewModel.isSending)

                Button(role: .destructive) {
                    viewModel.clearLocalTranscript()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AliceTheme.secondaryText)
                .background(AliceTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            }

            VStack(spacing: 10) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                }

                if viewModel.isSending {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(AliceTheme.amber)
                        Text("Thinking")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AliceTheme.secondaryText)
                        Spacer()
                    }
                    .padding(10)
                    .background(AliceTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(AliceTheme.red)
                    .padding(10)
                    .background(AliceTheme.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .alicePanel()
    }
}

private struct MessageBubble: View {
    var message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 42)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(labelColor)
                    if let affect = message.affect {
                        Text(affect.emotion.rawValue)
                            .font(.caption2)
                            .foregroundStyle(AliceTheme.secondaryText)
                    }
                }
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(AliceTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(11)
            .background(bubbleColor, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )

            if message.role != .user {
                Spacer(minLength: 42)
            }
        }
    }

    private var label: String {
        switch message.role {
        case .user:
            return "You"
        case .assistant:
            return message.personaName ?? "Alice"
        case .system:
            return "System"
        }
    }

    private var labelColor: Color {
        switch message.role {
        case .user:
            return AliceTheme.mint
        case .assistant:
            return AliceTheme.amber
        case .system:
            return AliceTheme.lavender
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .user:
            return AliceTheme.mint.opacity(0.12)
        case .assistant:
            return AliceTheme.surface
        case .system:
            return AliceTheme.lavender.opacity(0.1)
        }
    }

    private var borderColor: Color {
        switch message.role {
        case .user:
            return AliceTheme.mint.opacity(0.35)
        case .assistant:
            return AliceTheme.border
        case .system:
            return AliceTheme.lavender.opacity(0.3)
        }
    }
}

private struct ChatInputBar: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("和 \(viewModel.selectedPersona.name) 说点什么", text: $viewModel.draft, axis: .vertical)
                .lineLimit(1...4)
                .font(.body)
                .foregroundStyle(AliceTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(AliceTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AliceTheme.border, lineWidth: 1)
                )

            Button {
                viewModel.sendDraft()
            } label: {
                Image(systemName: viewModel.isSending ? "hourglass" : "paperplane.fill")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.black)
                    .background(sendColor, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, AliceMetrics.outerPadding)
        .padding(.vertical, 12)
        .background(AliceTheme.header)
    }

    private var sendColor: Color {
        viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AliceTheme.secondaryText : AliceTheme.mint
    }
}

private struct ImmersiveBackground: View {
    private let streaks: [(CGFloat, CGFloat, CGFloat)] = [
        (0.18, 90, 0.26),
        (0.31, 140, 0.18),
        (0.54, 70, 0.22),
        (0.72, 120, 0.2),
        (0.88, 84, 0.16)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(
                    colors: [
                        AliceTheme.violet.opacity(0.24),
                        AliceTheme.background.opacity(0.1),
                        AliceTheme.background
                    ],
                    center: .top,
                    startRadius: 40,
                    endRadius: proxy.size.height * 0.9
                )
                ForEach(streaks.indices, id: \.self) { index in
                    let item = streaks[index]
                    Capsule()
                        .fill(AliceTheme.violetGlow.opacity(item.2))
                        .frame(width: 1, height: item.1)
                        .position(x: proxy.size.width * item.0, y: proxy.size.height * 0.36)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    CompanionHomeView(viewModel: ChatViewModel())
        .preferredColorScheme(.dark)
}
