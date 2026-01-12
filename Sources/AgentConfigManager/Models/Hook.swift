import Foundation

/// A hook configured in an agent's settings
struct Hook: Identifiable, Hashable {
    let id: String
    let eventType: HookEventType
    let matcher: String?
    let command: String
    let timeout: Int?
    let agentID: AgentID

    var displayName: String {
        // Extract the script name from the command path
        if let lastComponent = command.components(separatedBy: "/").last {
            return lastComponent
                .replacingOccurrences(of: ".mjs", with: "")
                .replacingOccurrences(of: ".js", with: "")
                .replacingOccurrences(of: ".sh", with: "")
                .replacingOccurrences(of: ".py", with: "")
        }
        return command
    }
}

/// Hook event types supported by Claude Code
enum HookEventType: String, CaseIterable, Hashable {
    case preToolUse = "PreToolUse"
    case postToolUse = "PostToolUse"
    case sessionStart = "SessionStart"
    case sessionEnd = "SessionEnd"
    case userPromptSubmit = "UserPromptSubmit"
    case notification = "Notification"
    case preCompact = "PreCompact"
    case stop = "Stop"

    var displayName: String {
        switch self {
        case .preToolUse: return "Pre Tool Use"
        case .postToolUse: return "Post Tool Use"
        case .sessionStart: return "Session Start"
        case .sessionEnd: return "Session End"
        case .userPromptSubmit: return "User Prompt Submit"
        case .notification: return "Notification"
        case .preCompact: return "Pre Compact"
        case .stop: return "Stop"
        }
    }

    var symbolName: String {
        switch self {
        case .preToolUse: return "arrow.right.to.line"
        case .postToolUse: return "arrow.left.to.line"
        case .sessionStart: return "play.circle"
        case .sessionEnd: return "stop.circle"
        case .userPromptSubmit: return "text.bubble"
        case .notification: return "bell"
        case .preCompact: return "archivebox"
        case .stop: return "xmark.octagon"
        }
    }
}
