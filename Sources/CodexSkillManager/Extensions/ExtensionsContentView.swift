import SwiftUI

struct ExtensionsContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ExtensionStore.self) private var store

    private var shouldShowExtensions: Bool {
        appModel.selectedAgents.isEmpty || appModel.selectedAgents.contains(.pi)
    }

    var body: some View {
        @Bindable var store = store

        Group {
            if shouldShowExtensions {
                extensionsList
            } else {
                ContentUnavailableView(
                    "Select Pi Agent",
                    systemImage: "puzzlepiece.extension",
                    description: Text("Extensions are only available for Pi Agent.")
                )
            }
        }
        .task {
            await store.load()
        }
        .onChange(of: store.selectedExtensionID) { _, _ in
            Task { await store.loadSelectedExtension() }
        }
    }

    private var extensionsList: some View {
        @Bindable var store = store

        return List(store.extensions, selection: $store.selectedExtensionID) { ext in
            ExtensionRowView(extension: ext)
        }
        .listStyle(.sidebar)
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
