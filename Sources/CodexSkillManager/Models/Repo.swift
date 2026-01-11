import Foundation

enum RepoStatus: String, CaseIterable, Identifiable, Hashable, Sendable {
    case bloated
    case minimal
    case noAgentsMd

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bloated: return "Bloated"
        case .minimal: return "Minimal"
        case .noAgentsMd: return "No AGENTS.md"
        }
    }

    var symbolName: String {
        switch self {
        case .bloated: return "exclamationmark.triangle"
        case .minimal: return "checkmark.circle"
        case .noAgentsMd: return "circle"
        }
    }
}

struct Repo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let folderURL: URL
    let agentsMdURL: URL?
    let status: RepoStatus
    let fileSizeBytes: Int64

    var folderPath: String { folderURL.path }

    var hasAgentsMd: Bool { agentsMdURL != nil }

    var fileSizeFormatted: String {
        guard fileSizeBytes > 0 else { return "" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSizeBytes)
    }
}
