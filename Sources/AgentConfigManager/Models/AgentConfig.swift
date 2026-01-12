import SwiftUI

struct AgentConfig: Identifiable, Hashable, Sendable {
    let id: AgentID
    let displayName: String
    let badgeColor: Color
    let skillsURL: URL?
    let extensionsURL: URL?
    let pluginsURL: URL?
    let hooksURL: URL?
    let commandsURL: URL?
    let agentsMarkdownURL: URL?

    static func config(for id: AgentID) -> AgentConfig? {
        all.first { $0.id == id }
    }

    var skillPlatform: SkillPlatform? {
        switch id {
        case .pi:
            return .pi
        case .claude:
            return .claude
        case .codex:
            return .codex
        case .opencode:
            return .opencode
        case .copilot:
            return .copilot
        }
    }

    var instructionsURL: URL? { agentsMarkdownURL }

    var capabilities: AgentCapabilities {
        switch id {
        case .pi: return .pi
        case .claude: return .claude
        case .codex: return .codex
        case .opencode: return .opencode
        case .copilot: return AgentCapabilities(
            skills: .none,
            extensions: .none,
            plugins: .none,
            hooks: .none,
            commands: .none,
            instructions: .none,
            skillDocFilename: "SKILL.md"
        )
        }
    }

    static let all: [AgentConfig] = [
        AgentConfig(
            id: .pi,
            displayName: "Pi Agent",
            badgeColor: .green,
            skillsURL: AgentConfigPaths.piSkillsURL,
            extensionsURL: AgentConfigPaths.piExtensionsURL,
            pluginsURL: nil,
            hooksURL: nil,  // Pi uses hooks via extensions
            commandsURL: AgentConfigPaths.piCommandsURL,
            agentsMarkdownURL: AgentConfigPaths.piAgentsMarkdownURL
        ),
        AgentConfig(
            id: .claude,
            displayName: "Claude Code",
            badgeColor: Color(red: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0),
            skillsURL: AgentConfigPaths.claudeSkillsURL,
            extensionsURL: nil,
            pluginsURL: AgentConfigPaths.claudePluginsURL,
            hooksURL: AgentConfigPaths.claudeHooksURL,
            commandsURL: AgentConfigPaths.claudeCommandsURL,
            agentsMarkdownURL: AgentConfigPaths.claudeAgentsMarkdownURL
        ),
        AgentConfig(
            id: .codex,
            displayName: "Codex",
            badgeColor: Color(red: 164.0 / 255.0, green: 97.0 / 255.0, blue: 212.0 / 255.0),
            skillsURL: AgentConfigPaths.codexSkillsURL,
            extensionsURL: nil,
            pluginsURL: nil,
            hooksURL: nil,
            commandsURL: nil,
            agentsMarkdownURL: AgentConfigPaths.codexAgentsMarkdownURL
        ),
        AgentConfig(
            id: .opencode,
            displayName: "OpenCode",
            badgeColor: Color(red: 76.0 / 255.0, green: 144.0 / 255.0, blue: 226.0 / 255.0),
            skillsURL: AgentConfigPaths.opencodeSkillsURL,
            extensionsURL: nil,
            pluginsURL: AgentConfigPaths.opencodePluginsURL,
            hooksURL: nil,  // OpenCode uses hooks via plugins
            commandsURL: nil,
            agentsMarkdownURL: AgentConfigPaths.opencodeAgentsMarkdownURL
        ),
        AgentConfig(
            id: .copilot,
            displayName: "GitHub Copilot",
            badgeColor: Color(red: 77.0 / 255.0, green: 212.0 / 255.0, blue: 212.0 / 255.0),
            skillsURL: AgentConfigPaths.copilotSkillsURL,
            extensionsURL: nil,
            pluginsURL: nil,
            hooksURL: nil,
            commandsURL: nil,
            agentsMarkdownURL: AgentConfigPaths.copilotAgentsMarkdownURL
        ),
    ]
}
