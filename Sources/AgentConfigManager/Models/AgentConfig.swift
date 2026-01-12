import SwiftUI

struct AgentConfig: Identifiable, Hashable, Sendable {
    let id: AgentID
    let displayName: String
    let badgeColorRGB: (red: Double, green: Double, blue: Double)
    let capabilities: AgentCapabilities

    var badgeColor: Color {
        Color(red: badgeColorRGB.red, green: badgeColorRGB.green, blue: badgeColorRGB.blue)
    }

    var skillPlatform: SkillPlatform? {
        switch id {
        case .pi: return .pi
        case .claude: return .claude
        case .codex: return .codex
        case .opencode: return .opencode
        }
    }

    // Convenience accessors
    var skillsURL: URL? { capabilities.skills.folderURL }
    var extensionsURL: URL? { capabilities.extensions.folderURL }
    var pluginsURL: URL? { capabilities.plugins.folderURL }
    var hooksURL: URL? { capabilities.hooks.folderURL }
    var commandsURL: URL? { capabilities.commands.folderURL }
    var instructionsURL: URL? { capabilities.instructions.folderURL }

    func supports(_ section: NavigationSection) -> Bool {
        switch section {
        case .skills: return capabilities.skills.isSupported
        case .extensions: return capabilities.extensions.isSupported
        case .plugins: return capabilities.plugins.isSupported
        case .hooks: return capabilities.hooks.isSupported
        case .commands: return capabilities.commands.isSupported
        case .agentsmd: return capabilities.instructions.isSupported
        case .repos: return true  // Not agent-specific
        }
    }

    func supportMode(for section: NavigationSection) -> SupportMode {
        switch section {
        case .skills: return capabilities.skills
        case .extensions: return capabilities.extensions
        case .plugins: return capabilities.plugins
        case .hooks: return capabilities.hooks
        case .commands: return capabilities.commands
        case .agentsmd: return capabilities.instructions
        case .repos: return .none
        }
    }

    // MARK: - Hashable conformance (needed for tuple)

    static func == (lhs: AgentConfig, rhs: AgentConfig) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static let all: [AgentConfig] = [
        AgentConfig(
            id: .pi,
            displayName: "Pi Agent",
            badgeColorRGB: (0.0, 0.8, 0.0),  // Green
            capabilities: .pi
        ),
        AgentConfig(
            id: .claude,
            displayName: "Claude Code",
            badgeColorRGB: (217/255, 119/255, 87/255),  // Orange/coral
            capabilities: .claude
        ),
        AgentConfig(
            id: .codex,
            displayName: "Codex",
            badgeColorRGB: (164/255, 97/255, 212/255),  // Purple
            capabilities: .codex
        ),
        AgentConfig(
            id: .opencode,
            displayName: "OpenCode",
            badgeColorRGB: (76/255, 144/255, 226/255),  // Blue
            capabilities: .opencode
        ),
        // REMOVED: GitHub Copilot
    ]

    static func config(for id: AgentID) -> AgentConfig? {
        all.first { $0.id == id }
    }
}
