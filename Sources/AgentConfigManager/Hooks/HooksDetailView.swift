import SwiftUI

struct HooksDetailView: View {
    @Environment(HookStore.self) private var store

    var body: some View {
        Group {
            if let hook = store.selectedHook {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hook.displayName)
                                .font(.headline)

                            HStack(spacing: 8) {
                                Label(hook.eventType.displayName, systemImage: hook.eventType.symbolName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let matcher = hook.matcher {
                                    Text(matcher)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.secondary.opacity(0.1))
                                        .cornerRadius(4)
                                }

                                if let timeout = hook.timeout {
                                    Text("Timeout: \(timeout)s")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()

                    Divider()

                    // Source code
                    if store.isLoadingSource {
                        ProgressView("Loading source...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if store.selectedSource.isEmpty {
                        ContentUnavailableView(
                            "No Source",
                            systemImage: "doc.text",
                            description: Text("Source file not found")
                        )
                    } else {
                        ScrollView {
                            Text(store.selectedSource)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "Select a Hook",
                    systemImage: "arrow.triangle.branch",
                    description: Text("Choose a hook from the list to view its source")
                )
            }
        }
        .onChange(of: store.selectedHookID) { _, _ in
            Task { await store.loadSelectedHookSource() }
        }
        .task {
            if store.selectedHook != nil {
                await store.loadSelectedHookSource()
            }
        }
    }
}
