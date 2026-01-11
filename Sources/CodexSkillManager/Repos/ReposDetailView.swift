import AppKit
import MarkdownUI
import SwiftUI

struct ReposDetailView: View {
    @Environment(RepoStore.self) private var store

    @State private var showingSettings = false

    var body: some View {
        Group {
            if let repo = store.selectedRepo {
                repoDetail(repo)
            } else {
                ContentUnavailableView(
                    "No Repository Selected",
                    systemImage: "folder",
                    description: Text("Select a repository to view its details.")
                )
            }
        }
        .toolbar(id: "repos-detail-toolbar") {
            toolbarContent()
        }
        .sheet(isPresented: $showingSettings) {
            RepoSettingsView()
        }
    }

    private func repoDetail(_ repo: Repo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(for: repo)
                .padding()

            Divider()

            switch store.detailState {
            case .idle:
                if !repo.hasAgentsMd {
                    ContentUnavailableView(
                        "No AGENTS.md",
                        systemImage: "doc.badge.plus",
                        description: Text("This repository doesn't have an AGENTS.md file.")
                    )
                } else {
                    Spacer()
                }
            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                ScrollView {
                    Markdown(store.selectedContent)
                        .padding()
                }
            case .failed(let message):
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
    }

    private func header(for repo: Repo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(repo.name)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                Label(repo.status.displayName, systemImage: repo.status.symbolName)
                    .foregroundStyle(statusColor(for: repo.status))

                if repo.hasAgentsMd {
                    Label(repo.fileSizeFormatted, systemImage: "doc.text")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)

            Text(repo.folderPath)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func statusColor(for status: RepoStatus) -> Color {
        switch status {
        case .bloated: return .orange
        case .minimal: return .green
        case .noAgentsMd: return .secondary
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some CustomizableToolbarContent {
        ToolbarItem(id: "refresh") {
            Button {
                Task { await store.load() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
        }

        ToolbarItem(id: "open-finder") {
            Button {
                store.openInFinder()
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }
            .labelStyle(.iconOnly)
            .disabled(store.selectedRepo == nil)
        }

        ToolbarItem(id: "open-editor") {
            Button {
                store.openAgentsMdInEditor()
            } label: {
                Label("Open in Editor", systemImage: "pencil")
            }
            .labelStyle(.iconOnly)
            .disabled(store.selectedRepo?.hasAgentsMd != true)
        }

        ToolbarItem(id: "settings") {
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .labelStyle(.iconOnly)
        }
    }
}
