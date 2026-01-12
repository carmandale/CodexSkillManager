import Foundation

enum NavigationSection: String, CaseIterable, Identifiable {
    case skills
    case extensions
    case plugins
    case hooks
    case commands
    case agentsmd
    case repos

    var id: String { rawValue }

    var name: String {
        switch self {
        case .skills: return "Skills"
        case .extensions: return "Extensions"
        case .plugins: return "Plugins"
        case .hooks: return "Hooks"
        case .commands: return "Commands"
        case .agentsmd: return "AGENTS.md"
        case .repos: return "Repos"
        }
    }

    var symbolName: String {
        switch self {
        case .skills: return "book.closed"
        case .extensions: return "puzzlepiece.extension"
        case .plugins: return "powerplug"
        case .hooks: return "arrow.triangle.branch"
        case .commands: return "terminal"
        case .agentsmd: return "doc.text"
        case .repos: return "folder"
        }
    }

    /// Which agents support this section
    var supportedAgentIDs: Set<AgentID> {
        Set(AgentConfig.all.filter { $0.supports(self) }.map(\.id))
    }
}
