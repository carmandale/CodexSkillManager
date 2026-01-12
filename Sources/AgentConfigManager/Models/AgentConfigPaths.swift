import Foundation

enum AgentConfigPaths {
    private static let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

    // MARK: - Central Configuration (shared across agents)

    static let centralRootURL = homeDirectory.appending(path: ".agent-config")
    static let centralAgentsMarkdownURL = centralRootURL.appending(path: "AGENTS.md")
    static let centralCommandsURL = centralRootURL.appending(path: "commands")
    static let centralKnowledgeURL = centralRootURL.appending(path: "knowledge")

    // MARK: - Legacy OpenCode Config (migration source)

    static let legacyOpencodeConfigURL = homeDirectory.appending(path: "opencode-config")
    static let legacyOpencodeAgentsMarkdownURL = legacyOpencodeConfigURL.appending(path: "AGENTS.md")
    static let legacyOpencodeCommandsURL = legacyOpencodeConfigURL.appending(path: "commands")
    static let legacyOpencodeKnowledgeURL = legacyOpencodeConfigURL.appending(path: "knowledge")

    // MARK: - Pi Agent

    static let piRootURL = homeDirectory.appending(path: ".pi/agent")
    static let piSkillsURL = piRootURL.appending(path: "skills")
    static let piExtensionsURL = piRootURL.appending(path: "extensions")
    static let piCommandsURL = piRootURL.appending(path: "commands")
    static let piAgentsMarkdownURL = piRootURL.appending(path: "AGENTS.md")

    // MARK: - Claude

    static let claudeRootURL = homeDirectory.appending(path: ".claude")
    static let claudeSkillsURL = claudeRootURL.appending(path: "skills")
    static let claudePluginsURL = claudeRootURL.appending(path: "plugins")
    static let claudeHooksURL = claudeRootURL.appending(path: "hooks")
    static let claudeCommandsURL = claudeRootURL.appending(path: "commands")
    static let claudeAgentsMarkdownURL = claudeRootURL.appending(path: "AGENTS.md")

    // MARK: - Codex

    static let codexRootURL = homeDirectory.appending(path: ".codex")
    static let codexSkillsURL = codexRootURL.appending(path: "skills/public")
    static let codexPromptsURL = codexRootURL.appending(path: "prompts")
    static let codexAgentsMarkdownURL = codexRootURL.appending(path: "AGENTS.md")

    // MARK: - OpenCode

    static let opencodeRootURL = homeDirectory.appending(path: ".opencode")
    static let opencodeSkillsURL = opencodeRootURL.appending(path: "skills")
    static let opencodePluginsURL = opencodeRootURL.appending(path: "plugins")
    static let opencodeCommandsURL = opencodeRootURL.appending(path: "commands")
    static let opencodeAgentsMarkdownURL = opencodeRootURL.appending(path: "AGENTS.md")

    // MARK: - Copilot

    static let copilotRootURL = homeDirectory.appending(path: ".github-copilot")
    static let copilotSkillsURL = copilotRootURL.appending(path: "skills")
    static let copilotAgentsMarkdownURL = copilotRootURL.appending(path: "AGENTS.md")
}
