import SwiftUI

struct PluginsContentView: View {
    var body: some View {
        List {
            // Claude plugins (JSON format)
            if let claudeConfig = AgentConfig.config(for: AgentID.claude) {
                Section {
                    if let pluginsURL = claudeConfig.pluginsURL {
                        Text(pluginsURL.path.replacingOccurrences(
                            of: FileManager.default.homeDirectoryForCurrentUser.path,
                            with: "~"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Text("Plugin format: JSON (.claude-plugin/plugin.json)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } header: {
                    HStack {
                        Circle().fill(claudeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Claude Code")
                    }
                }
            }

            // OpenCode plugins (TypeScript format)
            if let opencodeConfig = AgentConfig.config(for: AgentID.opencode) {
                Section {
                    if let pluginsURL = opencodeConfig.pluginsURL {
                        Text(pluginsURL.path.replacingOccurrences(
                            of: FileManager.default.homeDirectoryForCurrentUser.path,
                            with: "~"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Text("Plugin format: TypeScript/JavaScript")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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
    }
}
