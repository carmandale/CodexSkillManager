import SwiftUI

/// Multi-step wizard for setting up AGENTS.md symlinks across all agents
struct SymlinkWizardView: View {
    @Environment(AgentsMdStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    enum Step: Int, CaseIterable {
        case status = 0
        case actions = 1
        case confirm = 2
        case complete = 3

        var title: String {
            switch self {
            case .status: return "Current Status"
            case .actions: return "Proposed Actions"
            case .confirm: return "Confirm"
            case .complete: return "Complete"
            }
        }
    }

    @State private var currentStep: Step = .status
    @State private var isExecuting = false
    @State private var executionError: String?
    @State private var completedActions: [String] = []

    private var agentsNeedingAction: [AgentSymlink] {
        store.symlinks.filter { $0.status.canLink }
    }

    private var alreadyLinked: [AgentSymlink] {
        store.symlinks.filter { $0.status == .linked }
    }

    private var parentMissing: [AgentSymlink] {
        store.symlinks.filter { $0.status == .parentMissing }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            wizardHeader()

            Divider()

            // Step content
            ScrollView {
                stepContent()
                    .padding(24)
            }

            Divider()

            // Navigation buttons
            navigationButtons()
                .padding()
        }
        .frame(width: 560, height: 480)
        .task {
            await store.load()
        }
    }

    @ViewBuilder
    private func wizardHeader() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "link.badge.plus")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
                Text("Symlink Setup Wizard")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            // Progress indicator
            HStack(spacing: 8) {
                ForEach(Step.allCases, id: \.self) { step in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(stepColor(for: step))
                            .frame(width: 8, height: 8)
                        Text(step.title)
                            .font(.caption)
                            .foregroundStyle(step == currentStep ? .primary : .secondary)
                    }
                    if step != .complete {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
    }

    private func stepColor(for step: Step) -> Color {
        if step.rawValue < currentStep.rawValue {
            return .green
        } else if step == currentStep {
            return Color.accentColor
        } else {
            return .secondary.opacity(0.5)
        }
    }

    @ViewBuilder
    private func stepContent() -> some View {
        switch currentStep {
        case .status:
            statusStepView()
        case .actions:
            actionsStepView()
        case .confirm:
            confirmStepView()
        case .complete:
            completeStepView()
        }
    }

    @ViewBuilder
    private func statusStepView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Current symlink status for each AI agent:")
                .font(.headline)

            if store.symlinks.isEmpty {
                ContentUnavailableView(
                    "Loading...",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("Checking agent configurations")
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(store.symlinks) { symlink in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(symlink.badgeColor)
                                .frame(width: 10, height: 10)

                            Text(symlink.displayName)
                                .frame(width: 100, alignment: .leading)

                            HStack(spacing: 4) {
                                Image(systemName: symlink.status.symbolName)
                                    .foregroundStyle(symlink.status.tintColor)
                                Text(symlink.status.displayName)
                            }
                            .frame(width: 120, alignment: .leading)
                            .help(symlink.status.statusDescription)

                            Spacer()

                            Text(symlink.symlinkURL.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 8)

                    HStack(spacing: 20) {
                        Label("\(alreadyLinked.count) linked", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Label("\(agentsNeedingAction.count) need action", systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(agentsNeedingAction.isEmpty ? Color.secondary : Color.orange)
                        Label("\(parentMissing.count) not installed", systemImage: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary)
                    }
                    .font(.callout)
                }
            }
        }
    }

    @ViewBuilder
    private func actionsStepView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The following actions will be performed:")
                .font(.headline)

            if agentsNeedingAction.isEmpty {
                ContentUnavailableView(
                    "No Actions Needed",
                    systemImage: "checkmark.seal.fill",
                    description: Text("All agents are already linked to the central AGENTS.md")
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(agentsNeedingAction) { symlink in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: actionIcon(for: symlink.status))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(actionText(for: symlink))
                                    .fontWeight(.medium)

                                Group {
                                    Text("From: ")
                                        .foregroundStyle(.secondary) +
                                    Text(symlink.symlinkURL.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                                }
                                .font(.caption)

                                Group {
                                    Text("To: ")
                                        .foregroundStyle(.secondary) +
                                    Text(AgentConfigPaths.centralAgentsMarkdownURL.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                                }
                                .font(.caption)

                                if symlink.status == .regularFile {
                                    Label("Existing file will be backed up", systemImage: "doc.badge.clock")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    private func actionIcon(for status: AgentSymlink.Status) -> String {
        switch status {
        case .unlinked:
            return "link.badge.plus"
        case .stale:
            return "arrow.triangle.2.circlepath"
        case .regularFile:
            return "doc.badge.arrow.up"
        default:
            return "link"
        }
    }

    private func actionText(for symlink: AgentSymlink) -> String {
        switch symlink.status {
        case .unlinked:
            return "Create symlink for \(symlink.displayName)"
        case .stale:
            return "Update symlink for \(symlink.displayName)"
        case .regularFile:
            return "Replace file with symlink for \(symlink.displayName)"
        default:
            return "Link \(symlink.displayName)"
        }
    }

    @ViewBuilder
    private func confirmStepView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if agentsNeedingAction.isEmpty {
                ContentUnavailableView(
                    "Nothing to Confirm",
                    systemImage: "checkmark.seal.fill",
                    description: Text("All agents are already properly linked")
                )
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to create symlinks")
                            .font(.headline)
                        Text("This will modify \(agentsNeedingAction.count) agent configuration(s).")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(agentsNeedingAction) { symlink in
                        HStack(spacing: 8) {
                            Text("•")
                            Circle()
                                .fill(symlink.badgeColor)
                                .frame(width: 8, height: 8)
                            Text(symlink.displayName)
                            Text("(\(symlink.status.displayName))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.callout)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if executionError != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(executionError!)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    @ViewBuilder
    private func completeStepView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Symlinks Created Successfully")
                .font(.title2)
                .fontWeight(.semibold)

            if !completedActions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed actions:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(completedActions, id: \.self) { action in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                            Text(action)
                        }
                        .font(.callout)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text("All configured agents now share the central AGENTS.md file.")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func navigationButtons() -> some View {
        HStack {
            if currentStep != .complete {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }

            Spacer()

            if currentStep.rawValue > 0 && currentStep != .complete {
                Button("Back") {
                    withAnimation {
                        currentStep = Step(rawValue: currentStep.rawValue - 1) ?? .status
                    }
                }
            }

            if currentStep == .complete {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            } else if currentStep == .confirm {
                Button("Create Symlinks") {
                    executeActions()
                }
                .buttonStyle(.borderedProminent)
                .disabled(agentsNeedingAction.isEmpty || isExecuting)
            } else {
                Button("Next") {
                    withAnimation {
                        currentStep = Step(rawValue: currentStep.rawValue + 1) ?? .complete
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
    }

    private func executeActions() {
        isExecuting = true
        executionError = nil

        Task {
            do {
                // Backup and create symlinks
                for symlink in agentsNeedingAction {
                    // If it's a regular file, back it up first
                    if symlink.status == .regularFile {
                        let backupURL = symlink.symlinkURL.appendingPathExtension("backup")
                        try FileManager.default.moveItem(at: symlink.symlinkURL, to: backupURL)
                        completedActions.append("Backed up \(symlink.displayName) to .backup")
                    }

                    try await store.createSymlink(for: symlink.id)
                    completedActions.append("Created symlink for \(symlink.displayName)")
                }

                await store.load()

                withAnimation {
                    currentStep = .complete
                }
            } catch {
                executionError = error.localizedDescription
            }

            isExecuting = false
        }
    }
}

#Preview {
    SymlinkWizardView()
        .environment(AgentsMdStore())
}
