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
}

struct Command: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let source: CommandSource
    let fileURL: URL

    var filePath: String { fileURL.path }
}
