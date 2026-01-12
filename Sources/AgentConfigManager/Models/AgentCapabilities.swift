import Foundation

/// Defines what capabilities an agent supports and how
struct AgentCapabilities: Hashable, Sendable {
    let skills: SupportMode
    let extensions: SupportMode
    let plugins: SupportMode
    let hooks: SupportMode
    let commands: SupportMode
    let instructions: SupportMode

    /// The filename used for skill documentation (e.g., "SKILL.md")
    let skillDocFilename: String

    /// All content URLs for this agent (used to determine "hasContent")
    var contentURLs: [URL] {
        [skills, extensions, plugins, hooks, commands, instructions]
            .compactMap { $0.folderURL }
    }

    // MARK: - Predefined Configurations

    static let pi = AgentCapabilities(
        skills: .folder(AgentConfigPaths.piSkillsURL),
        extensions: .folder(AgentConfigPaths.piExtensionsURL),
        plugins: .none,
        hooks: .viaExtensions,
        commands: .viaExtensions,  // Commands registered via pi.registerCommand()
        instructions: .folder(AgentConfigPaths.piAgentsMarkdownURL),
        skillDocFilename: "SKILL.md"
    )

    static let claude = AgentCapabilities(
        skills: .folder(AgentConfigPaths.claudeSkillsURL),
        extensions: .none,
        plugins: .folder(AgentConfigPaths.claudePluginsURL),
        hooks: .folder(AgentConfigPaths.claudeHooksURL),  // Also configured in settings.json
        commands: .folder(AgentConfigPaths.claudeCommandsURL),
        instructions: .folder(AgentConfigPaths.claudeAgentsMarkdownURL),
        skillDocFilename: "SKILL.md"
    )

    static let codex = AgentCapabilities(
        skills: .folder(AgentConfigPaths.codexSkillsURL),
        extensions: .none,
        plugins: .none,
        hooks: .none,
        commands: .folder(AgentConfigPaths.codexPromptsURL),  // "prompts" = commands for Codex
        instructions: .folder(AgentConfigPaths.codexAgentsMarkdownURL),
        skillDocFilename: "SKILL.md"
    )

    static let opencode = AgentCapabilities(
        skills: .folder(AgentConfigPaths.opencodeSkillsURL),
        extensions: .none,
        plugins: .folder(AgentConfigPaths.opencodePluginsURL),
        hooks: .viaPlugins,
        commands: .folder(AgentConfigPaths.opencodeCommandsURL),
        instructions: .folder(AgentConfigPaths.opencodeAgentsMarkdownURL),
        skillDocFilename: "SKILL.md"
    )
}
