import AppKit
import MarkdownUI
import SwiftUI

struct CommandsDetailView: View {
    @Environment(CommandStore.self) private var store

    var body: some View {
        Group {
            if let command = store.selectedCommand {
                commandDetail(command)
            } else {
                ContentUnavailableView(
                    "No Command Selected",
                    systemImage: "terminal",
                    description: Text("Select a command to view its details.")
                )
            }
        }
        .toolbar(id: "commands-detail-toolbar") {
            toolbarContent()
        }
    }

    private func commandDetail(_ command: Command) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(for: command)
                .padding()

            Divider()

            switch store.detailState {
            case .idle:
                Spacer()
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

    private func header(for command: Command) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("/\(command.name)")
                .font(.title2)
                .fontWeight(.semibold)

            Text(command.description)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label(command.source.displayName, systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
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
                Label("Open in Finder", systemImage: "folder")
            }
            .labelStyle(.iconOnly)
            .disabled(store.selectedCommand == nil)
        }
    }
}
