import SwiftUI

/// Multi-step wizard for migrating from opencode-config to ~/.agent-config
struct MigrationWizardView: View {
    @Environment(\.dismiss) private var dismiss

    enum Step: Int, CaseIterable {
        case detect = 0
        case preview = 1
        case confirm = 2
        case complete = 3

        var title: String {
            switch self {
            case .detect: return "Detect"
            case .preview: return "Preview"
            case .confirm: return "Confirm"
            case .complete: return "Complete"
            }
        }
    }

    @State private var currentStep: Step = .detect
    @State private var migrationStatus: MigrationWorker.MigrationStatus?
    @State private var isLoading = true
    @State private var isExecuting = false
    @State private var executionError: String?
    @State private var completedResults: [MigrationWorker.MigrationResult] = []

    private let worker: MigrationWorker
    let onComplete: (() -> Void)?

    init(onComplete: (() -> Void)? = nil) {
        // Initialize worker with paths from AgentConfigPaths (resolved at @MainActor context)
        self.worker = MigrationWorker(
            legacyRootURL: AgentConfigPaths.legacyOpencodeConfigURL,
            legacyAgentsMarkdownURL: AgentConfigPaths.legacyOpencodeAgentsMarkdownURL,
            legacyCommandsURL: AgentConfigPaths.legacyOpencodeCommandsURL,
            legacyKnowledgeURL: AgentConfigPaths.legacyOpencodeKnowledgeURL,
            centralRootURL: AgentConfigPaths.centralRootURL,
            centralAgentsMarkdownURL: AgentConfigPaths.centralAgentsMarkdownURL,
            centralCommandsURL: AgentConfigPaths.centralCommandsURL,
            centralKnowledgeURL: AgentConfigPaths.centralKnowledgeURL,
            homePath: FileManager.default.homeDirectoryForCurrentUser.path
        )
        self.onComplete = onComplete
    }

    private var itemsToMigrate: [MigrationWorker.ItemStatus] {
        migrationStatus?.items.filter(\.canMigrate) ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            wizardHeader()

            Divider()

            ScrollView {
                stepContent()
                    .padding(24)
            }

            Divider()

            navigationButtons()
                .padding()
        }
        .frame(width: 560, height: 480)
        .task {
            await loadStatus()
        }
    }

    @ViewBuilder
    private func wizardHeader() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
                Text("Migration Wizard")
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
            return Color.secondary.opacity(0.5)
        }
    }

    @ViewBuilder
    private func stepContent() -> some View {
        switch currentStep {
        case .detect:
            detectStepView()
        case .preview:
            previewStepView()
        case .confirm:
            confirmStepView()
        case .complete:
            completeStepView()
        }
    }

    @ViewBuilder
    private func detectStepView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Detecting legacy configuration...")
                .font(.headline)

            if isLoading {
                ProgressView("Scanning for opencode-config...")
                    .frame(maxWidth: .infinity)
            } else if let status = migrationStatus {
                VStack(alignment: .leading, spacing: 16) {
                    // Legacy location status
                    HStack(spacing: 12) {
                        Image(systemName: status.legacyConfigExists ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(status.legacyConfigExists ? Color.green : Color.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Legacy Config")
                                .fontWeight(.medium)
                            Text("~/opencode-config")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(status.legacyConfigExists ? "Found" : "Not found")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Central location status
                    HStack(spacing: 12) {
                        Image(systemName: status.centralConfigExists ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(status.centralConfigExists ? Color.green : Color.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Central Config")
                                .fontWeight(.medium)
                            Text("~/.agent-config")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(status.centralConfigExists ? "Exists" : "Will be created")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if !status.needsMigration {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color.blue)
                            Text(status.legacyConfigExists
                                 ? "All items have already been migrated."
                                 : "No legacy configuration found to migrate.")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func previewStepView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The following items will be migrated:")
                .font(.headline)

            if itemsToMigrate.isEmpty {
                ContentUnavailableView(
                    "Nothing to Migrate",
                    systemImage: "checkmark.seal.fill",
                    description: Text("All configuration items are already in place")
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(itemsToMigrate, id: \.item) { itemStatus in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: iconName(for: itemStatus.item))
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(itemStatus.item.displayName)
                                    .fontWeight(.medium)

                                Text("From: \(itemStatus.legacyPath)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("To: \(itemStatus.centralPath)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if itemStatus.legacyFileCount > 1 {
                                    Text("\(itemStatus.legacyFileCount) files")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.blue)
                    Text("Original files will be kept as backup in ~/opencode-config")
                        .font(.callout)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func iconName(for item: MigrationWorker.MigrationItem) -> String {
        switch item {
        case .agentsMarkdown:
            return "doc.text"
        case .commands:
            return "command"
        case .knowledge:
            return "book"
        }
    }

    @ViewBuilder
    private func confirmStepView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if itemsToMigrate.isEmpty {
                ContentUnavailableView(
                    "Nothing to Confirm",
                    systemImage: "checkmark.seal.fill",
                    description: Text("No migration needed")
                )
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(Color.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to migrate")
                            .font(.headline)
                        Text("This will copy \(itemsToMigrate.count) item(s) to ~/.agent-config")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(itemsToMigrate, id: \.item) { itemStatus in
                        HStack(spacing: 8) {
                            Text("•")
                            Image(systemName: iconName(for: itemStatus.item))
                            Text(itemStatus.item.displayName)
                            if itemStatus.legacyFileCount > 1 {
                                Text("(\(itemStatus.legacyFileCount) files)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.callout)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let error = executionError {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.red)
                        Text(error)
                            .foregroundStyle(Color.red)
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
                .foregroundStyle(Color.green)

            Text("Migration Complete")
                .font(.title2)
                .fontWeight(.semibold)

            if !completedResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed actions:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(completedResults, id: \.item) { result in
                        HStack(spacing: 8) {
                            Image(systemName: result.success ? "checkmark" : "xmark")
                                .foregroundStyle(result.success ? Color.green : Color.red)
                            Text(result.message)
                        }
                        .font(.callout)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text("Your configuration is now centralized in ~/.agent-config")
                .foregroundStyle(.secondary)

            Text("Tip: Run the Symlink Wizard next to link all agents to the central config.")
                .font(.callout)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                        currentStep = Step(rawValue: currentStep.rawValue - 1) ?? .detect
                    }
                }
            }

            if currentStep == .complete {
                Button("Done") {
                    onComplete?()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            } else if currentStep == .confirm {
                Button("Migrate") {
                    executeMigration()
                }
                .buttonStyle(.borderedProminent)
                .disabled(itemsToMigrate.isEmpty || isExecuting)
            } else {
                Button("Next") {
                    withAnimation {
                        currentStep = Step(rawValue: currentStep.rawValue + 1) ?? .complete
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
                .disabled(currentStep == .detect && !(migrationStatus?.needsMigration ?? false))
            }
        }
    }

    private func loadStatus() async {
        isLoading = true
        migrationStatus = await worker.checkMigrationStatus()
        isLoading = false
    }

    private func executeMigration() {
        isExecuting = true
        executionError = nil

        Task {
            do {
                let results = try await worker.migrateAll()
                completedResults = results

                let hasFailures = results.contains { !$0.success }
                if hasFailures {
                    executionError = "Some items failed to migrate"
                } else {
                    withAnimation {
                        currentStep = .complete
                    }
                }
            } catch {
                executionError = error.localizedDescription
            }

            isExecuting = false
        }
    }
}

#Preview {
    MigrationWizardView()
}
