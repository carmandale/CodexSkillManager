import Foundation

/// Documentation links for an agent
struct AgentDocumentation: Hashable, Sendable {
    /// Local file that can be opened in editor (e.g., AGENTS.md, CLAUDE.md)
    let fileURL: URL?

    /// Website documentation URL
    let websiteURL: URL?

    /// Display name for the documentation file
    var fileDisplayName: String {
        fileURL?.lastPathComponent ?? ""
    }

    static let none = AgentDocumentation(fileURL: nil, websiteURL: nil)
}

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

    /// Agent documentation (file and website)
    let documentation: AgentDocumentation

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
        skillDocFilename: "SKILL.md",
        documentation: AgentDocumentation(
            fileURL: AgentConfigPaths.piAgentsMarkdownURL,
            websiteURL: URL(string: "https://github.com/anthropics/pi-agent")
        )
    )

    static let claude = AgentCapabilities(
        skills: .folder(AgentConfigPaths.claudeSkillsURL),
        extensions: .none,
        plugins: .folder(AgentConfigPaths.claudePluginsURL),
        hooks: .folder(AgentConfigPaths.claudeHooksURL),  // Also configured in settings.json
        commands: .folder(AgentConfigPaths.claudeCommandsURL),
        instructions: .folder(AgentConfigPaths.claudeAgentsMarkdownURL),
        skillDocFilename: "SKILL.md",
        documentation: AgentDocumentation(
            fileURL: AgentConfigPaths.claudeAgentsMarkdownURL,
            websiteURL: URL(string: "https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview")
        )
    )

    static let codex = AgentCapabilities(
        skills: .folder(AgentConfigPaths.codexSkillsURL),
        extensions: .none,
        plugins: .none,
        hooks: .none,
        commands: .folder(AgentConfigPaths.codexPromptsURL),  // "prompts" = commands for Codex
        instructions: .folder(AgentConfigPaths.codexAgentsMarkdownURL),
        skillDocFilename: "SKILL.md",
        documentation: AgentDocumentation(
            fileURL: AgentConfigPaths.codexAgentsMarkdownURL,
            websiteURL: URL(string: "https://github.com/openai/codex")
        )
    )

    static let opencode = AgentCapabilities(
        skills: .folder(AgentConfigPaths.opencodeSkillsURL),
        extensions: .none,
        plugins: .folder(AgentConfigPaths.opencodePluginsURL),
        hooks: .viaPlugins,
        commands: .folder(AgentConfigPaths.opencodeCommandsURL),
        instructions: .folder(AgentConfigPaths.opencodeAgentsMarkdownURL),
        skillDocFilename: "SKILL.md",
        documentation: AgentDocumentation(
            fileURL: AgentConfigPaths.opencodeAgentsMarkdownURL,
            websiteURL: URL(string: "https://github.com/sst/opencode")
        )
    )
}
