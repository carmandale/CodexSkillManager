import Foundation

enum AgentConfigPaths {
    private static let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

    // MARK: - Central Configuration (shared across agents)

    static let centralRootURL = homeDirectory.appending(path: ".agent-config")
    static let centralAgentsMarkdownURL = centralRootURL.appending(path: "AGENTS.md")
    static let centralCommandsURL = centralRootURL.appending(path: "commands")

    // MARK: - Pi Agent

    static let piRootURL = homeDirectory.appending(path: ".pi/agent")
    static let piSkillsURL = piRootURL.appending(path: "skills")
    static let piExtensionsURL = piRootURL.appending(path: "extensions")
    static let piCommandsURL = piRootURL.appending(path: "commands")
    static let piAgentsMarkdownURL = piRootURL.appending(path: "AGENTS.md")

    // MARK: - Claude

    static let claudeRootURL = homeDirectory.appending(path: ".claude")
    static let claudeSkillsURL = claudeRootURL.appending(path: "skills")
    static let claudeCommandsURL = claudeRootURL.appending(path: "commands")
    static let claudeAgentsMarkdownURL = claudeRootURL.appending(path: "AGENTS.md")

    // MARK: - Codex

    static let codexRootURL = homeDirectory.appending(path: ".codex")
    static let codexSkillsURL = codexRootURL.appending(path: "skills/public")
    static let codexAgentsMarkdownURL = codexRootURL.appending(path: "AGENTS.md")

    // MARK: - OpenCode

    static let opencodeRootURL = homeDirectory.appending(path: ".opencode")
    static let opencodeSkillsURL = opencodeRootURL.appending(path: "skills")
    static let opencodeAgentsMarkdownURL = opencodeRootURL.appending(path: "AGENTS.md")

    // MARK: - Copilot

    static let copilotRootURL = homeDirectory.appending(path: ".github-copilot")
    static let copilotSkillsURL = copilotRootURL.appending(path: "skills")
    static let copilotAgentsMarkdownURL = copilotRootURL.appending(path: "AGENTS.md")
}
