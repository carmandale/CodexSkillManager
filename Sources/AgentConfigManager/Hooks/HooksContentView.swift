import SwiftUI

struct HooksContentView: View {
    var body: some View {
        List {
            // Claude - folder-backed hooks
            if let claudeConfig = AgentConfig.config(for: .claude) {
                Section {
                    if let hooksURL = claudeConfig.hooksURL {
                        Text(hooksURL.path.replacingOccurrences(
                            of: FileManager.default.homeDirectoryForCurrentUser.path,
                            with: "~"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Text("Configured in settings.json")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("Hook types: PreToolUse, PostToolUse, SessionStart, SessionEnd, etc.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } header: {
                    HStack {
                        Circle().fill(claudeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Claude Code")
                        Spacer()
                        Text("Folder")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Pi Agent - hooks via extensions
            if let piConfig = AgentConfig.config(for: .pi) {
                Section {
                    Text("Hooks are lifecycle events in extensions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Use: pi.on('event', handler)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                    Text("Events: session_start, tool_call, tool_result, turn_start, etc.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } header: {
                    HStack {
                        Circle().fill(piConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Pi Agent")
                        Spacer()
                        Text("Via Extensions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // OpenCode - hooks via plugins
            if let opencodeConfig = AgentConfig.config(for: .opencode) {
                Section {
                    Text("Hooks are exported from plugin modules")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Export: { 'tool.execute.before': async (...) => { } }")
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                } header: {
                    HStack {
                        Circle().fill(opencodeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("OpenCode")
                        Spacer()
                        Text("Via Plugins")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Codex - no hooks
            if let codexConfig = AgentConfig.config(for: .codex) {
                Section {
                    ContentUnavailableView(
                        "Not Supported",
                        systemImage: "xmark.circle",
                        description: Text("Codex does not support hooks (feature requested)")
                    )
                } header: {
                    HStack {
                        Circle().fill(codexConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Codex")
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
