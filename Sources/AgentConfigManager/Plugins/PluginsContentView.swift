import SwiftUI

struct PluginsContentView: View {
    @Environment(PluginStore.self) private var store

    var body: some View {
        @Bindable var store = store

        List(selection: $store.selectedPluginID) {
            // Claude plugins
            if let claudeConfig = AgentConfig.config(for: .claude) {
                let claudePlugins = store.plugins.filter { $0.agentID == .claude }

                Section {
                    if claudePlugins.isEmpty && !store.isLoading {
                        Text("No plugins installed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(claudePlugins) { plugin in
                            PluginRowView(plugin: plugin)
                                .tag(plugin.id)
                        }
                    }
                } header: {
                    HStack {
                        Circle().fill(claudeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Claude Code")
                        Spacer()
                        Text("\(claudePlugins.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // OpenCode plugins
            if let opencodeConfig = AgentConfig.config(for: .opencode) {
                Section {
                    Text("Plugin directory: ~/.config/opencode/plugin/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    HStack {
                        Circle().fill(opencodeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("OpenCode")
                    }
                }
            }

            // Agents that don't support plugins
            Section {
                ForEach([AgentID.pi, .codex], id: \.self) { agentID in
                    if let config = AgentConfig.config(for: agentID) {
                        HStack {
                            Circle().fill(config.badgeColor)
                                .frame(width: 8, height: 8)
                            Text(config.displayName)
                            Spacer()
                            Text("Not supported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Not Available")
            }
        }
        .listStyle(.sidebar)
        .task {
            await store.load()
        }
    }
}

private struct PluginRowView: View {
    let plugin: Plugin

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(plugin.displayName)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                Text("v\(plugin.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(plugin.marketplaceDisplay)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.secondary.opacity(0.1))
                    .cornerRadius(3)
            }
        }
    }
}
