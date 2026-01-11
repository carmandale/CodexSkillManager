import AppKit
import SwiftUI

struct AgentsMdDetailView: View {
    @Environment(AgentsMdStore.self) private var store
    @Environment(AppModel.self) private var appModel
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 0) {
            header()
                .padding()

            Divider()

            switch store.detailState {
            case .idle:
                Spacer()
            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                editorView()
            case .failed(let message):
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .toolbar(id: "agentsmd-detail-toolbar") {
            toolbarContent()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private func header() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Central AGENTS.md")
                    .font(.title2)
                    .fontWeight(.semibold)

                if store.hasUnsavedChanges {
                    Text("(Modified)")
                        .foregroundStyle(.secondary)
                }
            }

            Text(AgentConfigPaths.centralAgentsMarkdownURL.path)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)

            if let symlink = store.selectedSymlink {
                selectedAgentInfo(symlink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func selectedAgentInfo(_ symlink: AgentSymlink) -> some View {
        HStack(spacing: 12) {
            Divider()
                .frame(height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(symlink.badgeColor)
                        .frame(width: 8, height: 8)
                    Text(symlink.displayName)
                        .fontWeight(.medium)
                }

                HStack(spacing: 4) {
                    Image(systemName: symlink.status.symbolName)
                        .foregroundStyle(symlink.status.tintColor)
                    Text(symlink.status.displayName)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Spacer()

            if symlink.status.canLink {
                Button("Link") {
                    Task {
                        do {
                            try await store.createSymlink(for: symlink.id)
                        } catch {
                            showError(error)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if symlink.status.canUnlink {
                Button("Unlink") {
                    Task {
                        do {
                            try await store.removeSymlink(for: symlink.id)
                        } catch {
                            showError(error)
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 8)
    }

    private func editorView() -> some View {
        @Bindable var store = store

        return TextEditor(text: $store.centralContent)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(8)
            .onChange(of: store.centralContent) { _, _ in
                store.hasUnsavedChanges = true
            }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some CustomizableToolbarContent {
        ToolbarItem(id: "save") {
            Button {
                Task {
                    do {
                        try await store.saveCentralContent()
                    } catch {
                        showError(error)
                    }
                }
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .labelStyle(.iconOnly)
            .keyboardShortcut("s", modifiers: .command)
            .disabled(!store.hasUnsavedChanges)
            .help("Save changes (⌘S)")
        }

        ToolbarItem(id: "refresh") {
            Button {
                Task { await store.load() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .help("Refresh symlink status")
        }

        ToolbarItem(id: "link-all") {
            Button {
                Task {
                    do {
                        try await store.linkAllAgents()
                    } catch {
                        showError(error)
                    }
                }
            } label: {
                Label("Link All", systemImage: "link.badge.plus")
            }
            .labelStyle(.iconOnly)
            .disabled(store.symlinks.allSatisfy { !$0.status.canLink })
            .help("Create symlinks for all agents")
        }

        ToolbarItem(id: "open-folder") {
            Button {
                store.openCentralFolder()
            } label: {
                Label("Open in Finder", systemImage: "folder")
            }
            .labelStyle(.iconOnly)
            .help("Open ~/.agent-config in Finder")
        }

        ToolbarItem(id: "setup-wizard") {
            Button {
                appModel.showSymlinkWizard = true
            } label: {
                Label("Setup Wizard", systemImage: "wand.and.stars")
            }
            .help("Open Symlink Setup Wizard")
        }
    }

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}
