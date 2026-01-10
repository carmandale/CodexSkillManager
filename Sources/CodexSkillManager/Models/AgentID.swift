import Foundation

enum AgentID: String, CaseIterable, Identifiable, Hashable, Sendable {
    case pi
    case claude
    case codex
    case opencode
    case copilot

    var id: String { rawValue }
}
