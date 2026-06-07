import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    Picker("Mode", selection: $viewModel.apiMode) {
                        ForEach(AppAPIMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.apiMode.allowsCustomBaseURL {
                        TextField(AppSettingsStore.lanBaseURLPlaceholder, text: $viewModel.backendBaseURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }

                    SettingsValueRow(title: "Current URL", value: viewModel.currentBackendBaseURLDisplay)
                    SettingsValueRow(title: "Connection", value: viewModel.connectionStateLabel)

                    HStack {
                        Label(viewModel.healthStatus.label, systemImage: healthIcon)
                            .foregroundStyle(AliceTheme.healthColor(viewModel.healthStatus))
                        Spacer()
                        Button("Check") {
                            viewModel.checkBackendHealth()
                        }
                        .disabled(!viewModel.canCheckBackendHealth)
                    }

                    Text(connectionHelpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Avatar") {
                    Picker("Renderer", selection: $viewModel.avatarRendererPreference) {
                        ForEach(AvatarRendererPreference.allCases) { renderer in
                            Text(renderer.label).tag(renderer)
                        }
                    }
                    .pickerStyle(.segmented)

                    SettingsValueRow(title: "Renderer Status", value: rendererStatus)

                    HStack {
                        Label(riveAssetStatus.label, systemImage: riveAssetStatus.isAvailable ? "checkmark.seal" : "sparkles")
                            .foregroundStyle(riveAssetStatus.isAvailable ? AliceTheme.mint : AliceTheme.secondaryText)
                        Spacer()
                        Text(RiveAvatarAsset.resourceName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(riveAssetStatus.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Memory") {
                    Toggle("Memory", isOn: $viewModel.memoryEnabled)
                    Text(viewModel.sessionId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Section("Security") {
                    Text("No provider keys are stored in this app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var healthIcon: String {
        switch viewModel.healthStatus {
        case .available:
            return "checkmark.seal"
        case .checking:
            return "hourglass"
        case .unavailable:
            return "exclamationmark.triangle"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var riveAssetStatus: RiveAvatarAssetStatus {
        RiveAvatarAsset.status()
    }

    private var rendererStatus: String {
        if viewModel.avatarRendererPreference == .rive, !riveAssetStatus.isAvailable {
            return "Rive requested, SwiftUI fallback active"
        }
        return "\(viewModel.avatarRendererPreference.label) active"
    }

    private var connectionHelpText: String {
        switch viewModel.apiMode {
        case .mock:
            return "Mock uses a local contract fixture and does not call the Web backend."
        case .localhost:
            return "Use Localhost for iOS Simulator when the Web backend is running on this Mac."
        case .lan, .remote:
            return "Use LAN IP for device debugging. Enter your Mac's local network URL here; do not commit personal IPs."
        }
    }
}

private struct SettingsValueRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer(minLength: 16)
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
        }
    }
}
