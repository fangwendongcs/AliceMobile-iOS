import SwiftUI

struct CompanionHomeView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        ZStack {
            AliceTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderBar(viewModel: viewModel)

                ScrollView {
                    VStack(spacing: 14) {
                        PersonaSwitcher(viewModel: viewModel)
                        AvatarStatusPanel(viewModel: viewModel)
                        StateOverview(viewModel: viewModel)
                        MemoryPanel(viewModel: viewModel)
                        ChatTranscript(viewModel: viewModel)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 18)
                }
                .scrollDismissesKeyboard(.interactively)

                ChatInputBar(viewModel: viewModel)
            }
        }
    }
}

private struct HeaderBar: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Alice Mobile")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(viewModel.selectedPersona.summary)
                    .font(.footnote)
                    .foregroundStyle(AliceTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Label(viewModel.apiModeLabel, systemImage: "shield.checkered")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AliceTheme.mint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(AliceTheme.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                Text(viewModel.selectedPersona.name)
                    .font(.caption)
                    .foregroundStyle(AliceTheme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(AliceTheme.header)
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
                    VStack(spacing: 5) {
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
                        personaTint(persona)
                            .opacity(viewModel.selectedPersona == persona ? 1 : 0.14),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(personaTint(persona).opacity(0.45), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func personaTint(_ persona: CompanionPersona) -> Color {
        switch persona.avatarId {
        case "osa_shiro":
            return AliceTheme.lavender
        case "osa_wambo":
            return AliceTheme.amber
        default:
            return AliceTheme.mint
        }
    }
}

private struct AvatarStatusPanel: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(stateColor.opacity(0.18))
                        .frame(width: 116, height: 116)
                    Circle()
                        .stroke(stateColor.opacity(0.9), lineWidth: 2)
                        .frame(width: stateRingSize, height: stateRingSize)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.avatarState)
                    Image(systemName: avatarSymbol)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(stateColor)
                        .scaleEffect(viewModel.avatarState == .speaking ? 1.08 : 1)
                        .animation(.easeInOut(duration: 0.3).repeatCount(viewModel.avatarState == .speaking ? 3 : 1, autoreverses: true), value: viewModel.avatarState)
                }
                .frame(width: 126, height: 126)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(viewModel.selectedPersona.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(viewModel.avatarState.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(stateColor)
                    }

                    Text(viewModel.selectedPersona.boundaries)
                        .font(.caption)
                        .foregroundStyle(AliceTheme.secondaryText)
                        .lineLimit(3)

                    Label(viewModel.interactionNote, systemImage: "hand.tap")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AliceTheme.primaryText)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 8) {
                ForEach(BodyPart.allCases) { bodyPart in
                    Button {
                        viewModel.triggerBodyPart(bodyPart)
                    } label: {
                        Text(bodyPart.label)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AliceTheme.primaryText)
                    .background(AliceTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AliceTheme.border, lineWidth: 1)
                    )
                }
            }
        }
        .padding(14)
        .background(AliceTheme.panel, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AliceTheme.border, lineWidth: 1)
        )
    }

    private var avatarSymbol: String {
        switch viewModel.avatarState {
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

    private var stateColor: Color {
        switch viewModel.avatarState {
        case .thinking:
            return AliceTheme.amber
        case .speaking:
            return AliceTheme.mint
        case .reacting, .headAction, .armAction, .legAction:
            return AliceTheme.rose
        case .error:
            return AliceTheme.red
        case .listening:
            return AliceTheme.lavender
        default:
            return AliceTheme.blue
        }
    }

    private var stateRingSize: CGFloat {
        switch viewModel.avatarState {
        case .speaking:
            return 112
        case .thinking:
            return 104
        case .reacting, .headAction, .armAction, .legAction:
            return 120
        default:
            return 98
        }
    }
}

private struct StateOverview: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StateTile(title: "emotion", value: viewModel.currentAffect.emotion.rawValue, systemImage: "heart.text.square", color: AliceTheme.rose)
            StateTile(title: "tone", value: viewModel.currentAffect.tone.rawValue, systemImage: "slider.horizontal.3", color: AliceTheme.mint)
            StateTile(title: "avatar_state", value: viewModel.avatarState.rawValue, systemImage: "sparkles", color: AliceTheme.blue)
            StateTile(title: "voice", value: voiceLabel, systemImage: "waveform.circle", color: AliceTheme.amber)
        }
    }

    private var voiceLabel: String {
        let voice = viewModel.currentAffect.voice
        return "\(voice.style) \(String(format: "%.2f", voice.rate))x"
    }
}

private struct StateTile: View {
    var title: String
    var value: String
    var systemImage: String
    var color: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 7))

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

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(AliceTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AliceTheme.border, lineWidth: 1)
        )
    }
}

private struct MemoryPanel: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Memory", systemImage: "memorychip")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Toggle("", isOn: $viewModel.memoryEnabled)
                    .labelsHidden()
                    .tint(AliceTheme.mint)
            }

            HStack(spacing: 10) {
                StateTile(title: "status", value: viewModel.memoryState.status, systemImage: "checkmark.seal", color: AliceTheme.mint)
                StateTile(title: "long_term", value: "\(viewModel.memoryState.longTerm?.count ?? 0)", systemImage: "tray.full", color: AliceTheme.lavender)
            }

            Text("Session \(viewModel.sessionId)")
                .font(.caption2)
                .foregroundStyle(AliceTheme.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(14)
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
        .padding(14)
        .background(AliceTheme.panel, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AliceTheme.border, lineWidth: 1)
        )
    }
}

private struct MessageBubble: View {
    var message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
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
                Spacer(minLength: 40)
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
                    .background(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AliceTheme.secondaryText : AliceTheme.mint, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AliceTheme.header)
    }
}

private enum AliceTheme {
    static let background = Color(red: 0.055, green: 0.06, blue: 0.075)
    static let header = Color(red: 0.075, green: 0.08, blue: 0.095)
    static let panel = Color(red: 0.095, green: 0.105, blue: 0.125)
    static let surface = Color(red: 0.13, green: 0.145, blue: 0.165)
    static let border = Color.white.opacity(0.08)
    static let primaryText = Color(red: 0.92, green: 0.95, blue: 0.95)
    static let secondaryText = Color(red: 0.62, green: 0.66, blue: 0.69)
    static let mint = Color(red: 0.42, green: 0.93, blue: 0.76)
    static let amber = Color(red: 1.0, green: 0.73, blue: 0.35)
    static let rose = Color(red: 1.0, green: 0.48, blue: 0.58)
    static let lavender = Color(red: 0.72, green: 0.66, blue: 1.0)
    static let blue = Color(red: 0.43, green: 0.72, blue: 1.0)
    static let red = Color(red: 1.0, green: 0.36, blue: 0.34)
}

#Preview {
    CompanionHomeView(viewModel: ChatViewModel())
        .preferredColorScheme(.dark)
}
