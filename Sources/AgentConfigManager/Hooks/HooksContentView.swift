import SwiftUI

struct HooksContentView: View {
    @Environment(HookStore.self) private var store

    var body: some View {
        @Bindable var store = store

        List(selection: $store.selectedHookID) {
            // Claude Code hooks (from settings.json)
            if let claudeConfig = AgentConfig.config(for: .claude) {
                let claudeHooks = store.hooks.filter { $0.agentID == .claude }

                if !claudeHooks.isEmpty {
                    ForEach(HookEventType.allCases, id: \.self) { eventType in
                        let hooksForType = claudeHooks.filter { $0.eventType == eventType }
                        if !hooksForType.isEmpty {
                            Section {
                                ForEach(hooksForType) { hook in
                                    HookRowView(hook: hook)
                                        .tag(hook.id)
                                }
                            } header: {
                                HStack {
                                    Circle().fill(claudeConfig.badgeColor)
                                        .frame(width: 8, height: 8)
                                    Image(systemName: eventType.symbolName)
                                    Text(eventType.displayName)
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        Text("No hooks configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        HStack {
                            Circle().fill(claudeConfig.badgeColor)
                                .frame(width: 8, height: 8)
                            Text("Claude Code")
                        }
                    }
                }
            }

            // Pi Agent - hooks via extensions
            if let piConfig = AgentConfig.config(for: .pi) {
                Section {
                    Text("Hooks via extensions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("pi.on('event', handler)")
                        .font(.caption.monospaced())
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
                    Text("Hooks via plugins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("export { 'tool.execute.before': ... }")
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

            // Codex - no hooks (compact display)
            if let codexConfig = AgentConfig.config(for: .codex) {
                Section {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.secondary)
                        Text("Hooks not supported")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
        .task {
            await store.load()
        }
    }
}

private struct HookRowView: View {
    let hook: Hook

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(hook.displayName)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                if let matcher = hook.matcher {
                    Text(matcher)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.secondary.opacity(0.1))
                        .cornerRadius(3)
                }

                if let timeout = hook.timeout {
                    Text("\(timeout)s")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
