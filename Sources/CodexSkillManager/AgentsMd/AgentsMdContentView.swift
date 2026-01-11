import SwiftUI

struct AgentsMdContentView: View {
    @Environment(AgentsMdStore.self) private var store

    var body: some View {
        @Bindable var store = store

        List(selection: $store.selectedAgentID) {
            Section {
                ForEach(store.symlinks) { symlink in
                    AgentSymlinkRowView(symlink: symlink)
                }
            } header: {
                HStack {
                    Text("Agents")
                    Spacer()
                    Text("\(store.linkedCount)/\(store.totalCount) linked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .task {
            await store.load()
        }
    }
}

private struct AgentSymlinkRowView: View {
    let symlink: AgentSymlink

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(symlink.badgeColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(symlink.displayName)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Image(systemName: symlink.status.symbolName)
                        .foregroundStyle(symlink.status.tintColor)
                    Text(symlink.status.displayName)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Spacer()
        }
        .tag(symlink.id)
    }
}
