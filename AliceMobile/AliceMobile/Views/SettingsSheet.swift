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

                    TextField("Backend Base URL", text: $viewModel.backendBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .disabled(viewModel.apiMode == .mock)

                    HStack {
                        Label(viewModel.healthStatus.label, systemImage: healthIcon)
                            .foregroundStyle(AliceTheme.healthColor(viewModel.healthStatus))
                        Spacer()
                        Button("Check") {
                            viewModel.checkBackendHealth()
                        }
                        .disabled(viewModel.apiMode == .mock)
                    }
                }

                Section("Avatar") {
                    Picker("Renderer", selection: $viewModel.avatarRendererPreference) {
                        ForEach(AvatarRendererPreference.allCases) { renderer in
                            Text(renderer.label).tag(renderer)
                        }
                    }
                    .pickerStyle(.segmented)

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
}
