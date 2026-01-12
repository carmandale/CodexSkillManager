import Foundation

enum AgentConfigPaths {
    private static let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
    private static let configDirectory = homeDirectory.appending(path: ".config")

    // MARK: - Central Configuration (shared across agents)

    static let centralRootURL = homeDirectory.appending(path: ".agent-config")
    static let centralAgentsMarkdownURL = centralRootURL.appending(path: "AGENTS.md")
    static let centralCommandsURL = centralRootURL.appending(path: "commands")
    static let centralKnowledgeURL = centralRootURL.appending(path: "knowledge")

    // MARK: - Pi Agent

    static let piRootURL = homeDirectory.appending(path: ".pi/agent")
    static let piSkillsURL = piRootURL.appending(path: "skills")
    static let piExtensionsURL = piRootURL.appending(path: "extensions")
    static let piCommandsURL = piRootURL.appending(path: "commands")
    static let piAgentsMarkdownURL = piRootURL.appending(path: "AGENTS.md")
    static let piSettingsURL = piRootURL.appending(path: "settings.json")

    // MARK: - Claude Code

    static let claudeRootURL = homeDirectory.appending(path: ".claude")
    static let claudeSkillsURL = claudeRootURL.appending(path: "skills")
    static let claudeCommandsURL = claudeRootURL.appending(path: "commands")
    static let claudeHooksURL = claudeRootURL.appending(path: "hooks")
    static let claudePluginsURL = claudeRootURL.appending(path: "plugins")  // Primary source
    static let claudePluginsCacheURL = claudePluginsURL.appending(path: "cache")  // Derived/cached
    static let claudeSettingsURL = claudeRootURL.appending(path: "settings.json")
    static let claudeAgentsMarkdownURL = claudeRootURL.appending(path: "CLAUDE.md")  // FIXED: was AGENTS.md

    // MARK: - Codex CLI

    static let codexRootURL = homeDirectory.appending(path: ".codex")
    static let codexSkillsURL = codexRootURL.appending(path: "skills")  // FIXED: was skills/public
    static let codexPromptsURL = codexRootURL.appending(path: "prompts")  // Commands for Codex
    static let codexRulesURL = codexRootURL.appending(path: "rules")
    static let codexConfigURL = codexRootURL.appending(path: "config.toml")
    static let codexAgentsMarkdownURL = codexRootURL.appending(path: "AGENTS.md")

    // MARK: - OpenCode

    static let opencodeRootURL = configDirectory.appending(path: "opencode")  // FIXED: was ~/.opencode
    static let opencodeSkillsURL = opencodeRootURL.appending(path: "skill")  // FIXED: singular (was "skills")
    static let opencodeCommandsURL = opencodeRootURL.appending(path: "command")  // FIXED: singular
    static let opencodePluginsURL = opencodeRootURL.appending(path: "plugin")  // singular
    static let opencodeAgentsMarkdownURL = opencodeRootURL.appending(path: "AGENTS.md")

    // OpenCode project-local paths (for reference in comments):
    // .opencode/skill/, .opencode/command/, .opencode/plugin/

    // MARK: - Legacy Migration

    static let legacyOpencodeConfigURL = homeDirectory.appending(path: "opencode-config")
    static let legacyOpencodeAgentsMarkdownURL = legacyOpencodeConfigURL.appending(path: "AGENTS.md")
    static let legacyOpencodeCommandsURL = legacyOpencodeConfigURL.appending(path: "commands")
    static let legacyOpencodeKnowledgeURL = legacyOpencodeConfigURL.appending(path: "knowledge")

    // MARK: - Path Resolution Helpers

    /// Returns the first URL that exists on disk, or nil if none exist
    static func firstExisting(_ candidates: [URL]) -> URL? {
        let fm = FileManager.default
        return candidates.first { fm.fileExists(atPath: $0.path) }
    }

    /// OpenCode skill path with fallback (singular preferred, plural fallback)
    static var opencodeSkillsResolved: URL? {
        firstExisting([
            opencodeSkillsURL,
            opencodeRootURL.appending(path: "skills")  // plural fallback
        ])
    }

    /// OpenCode command path with fallback
    static var opencodeCommandsResolved: URL? {
        firstExisting([
            opencodeCommandsURL,
            opencodeRootURL.appending(path: "commands")  // plural fallback
        ])
    }
}
