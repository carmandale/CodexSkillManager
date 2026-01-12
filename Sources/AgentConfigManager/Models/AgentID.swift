import Foundation

enum AgentID: String, CaseIterable, Identifiable, Hashable, Sendable {
    case pi
    case claude
    case codex
    case opencode
    // REMOVED: case copilot

    var id: String { rawValue }

    var cliName: String {
        switch self {
        case .pi: return "pi"
        case .claude: return "claude"
        case .codex: return "codex"
        case .opencode: return "opencode"
        }
    }
}
