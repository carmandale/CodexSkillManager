import Foundation

enum CommandSource: String, CaseIterable, Identifiable, Hashable, Sendable {
    case central
    case pi
    case claude

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .central: return "Central"
        case .pi: return "Pi Agent"
        case .claude: return "Claude"
        }
    }

    var rootURL: URL {
        switch self {
        case .central: return AgentConfigPaths.centralCommandsURL
        case .pi: return AgentConfigPaths.piCommandsURL
        case .claude: return AgentConfigPaths.claudeCommandsURL
        }
    }

    /// Maps command source to its corresponding agent ID (nil for central/shared commands)
    var agentID: AgentID? {
        switch self {
        case .central: return nil
        case .pi: return .pi
        case .claude: return .claude
        }
    }
}

struct Command: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let source: CommandSource
    let fileURL: URL

    var filePath: String { fileURL.path }
}
