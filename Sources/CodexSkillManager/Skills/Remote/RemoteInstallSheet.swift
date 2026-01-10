import SwiftUI

struct RemoteInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SkillStore.self) private var store
    @Environment(RemoteSkillStore.self) private var remoteStore

    let skill: RemoteSkill
    let installedTargets: Set<SkillPlatform>
    @Binding var selection: Set<SkillPlatform>
    @Binding var isInstalling: Bool
    @Binding var didInstall: Bool
    @Binding var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Install Skill")
                    .font(.title.bold())
                Text("Choose where to install \(skill.displayName).")
                    .foregroundStyle(.secondary)
            }

            InstallTargetSelectionView(
                installedTargets: installedTargets,
                selection: $selection
            )

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Install") {
                    Task { await installSkill() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selection.isEmpty || isInstalling)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 340)
    }

    private func installSkill() async {
        guard !selection.isEmpty else { return }
        isInstalling = true
        didInstall = false
        do {
            try await store.installRemoteSkill(
                skill,
                client: remoteStore.client,
                destinations: selection
            )
            didInstall = true
            dismiss()
            try? await Task.sleep(for: .seconds(1.2))
        } catch {
            errorMessage = error.localizedDescription
        }
        isInstalling = false
        if didInstall {
            didInstall = false
        }
    }
}
