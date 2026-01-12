import SwiftUI

struct CommandsContentView: View {
    @Environment(CommandStore.self) private var store

    @State private var searchText = ""

    private var filteredCommands: [Command] {
        guard !searchText.isEmpty else { return store.commands }
        return store.commands.filter { command in
            command.name.localizedCaseInsensitiveContains(searchText)
                || command.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedCommands: [CommandSource: [Command]] {
        Dictionary(grouping: filteredCommands, by: { $0.source })
    }

    var body: some View {
        List {
            ForEach(CommandSource.allCases) { source in
                if let commands = groupedCommands[source], !commands.isEmpty {
                    Section(source.displayName) {
                        ForEach(commands) { command in
                            CommandRowView(command: command, isSelected: store.selectedCommandID == command.id)
                                .onTapGesture {
                                    store.selectedCommandID = command.id
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(
            text: $searchText,
            placement: .sidebar,
            prompt: "Filter commands"
        )
        .task {
            await store.load()
        }
        .onChange(of: store.selectedCommandID) { _, _ in
            Task { await store.loadSelectedCommand() }
        }
    }
}

private struct CommandRowView: View {
    let command: Command
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("/\(command.name)")
                .fontWeight(.medium)

            Text(command.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .tag(command.id)
        .listRowBackground(
            isSelected ? Color.accentColor.opacity(0.2) : Color.clear
        )
    }
}
