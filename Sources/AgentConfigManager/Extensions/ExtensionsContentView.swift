import SwiftUI

struct ExtensionsContentView: View {
    @Environment(ExtensionStore.self) private var store

    var body: some View {
        @Bindable var store = store

        List(selection: $store.selectedExtensionID) {
            if let piConfig = AgentConfig.config(for: .pi) {
                Section {
                    ForEach(store.extensions) { ext in
                        ExtensionRowView(extension: ext)
                            .tag(ext.id)
                    }
                } header: {
                    HStack {
                        Circle().fill(piConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Pi Agent Extensions")
                        Spacer()
                        Text("\(store.extensions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .task {
            await store.load()
        }
        .onChange(of: store.selectedExtensionID) { _, _ in
            Task { await store.loadSelectedExtension() }
        }
    }
}

private struct ExtensionRowView: View {
    let `extension`: Extension

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(`extension`.name)
                .fontWeight(.medium)

            HStack(spacing: 4) {
                if !`extension`.providedTools.isEmpty {
                    Text("\(`extension`.providedTools.count) tool\(`extension`.providedTools.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !`extension`.providedCommands.isEmpty {
                    Text("\(`extension`.providedCommands.count) command\(`extension`.providedCommands.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tag(`extension`.id)
    }
}
