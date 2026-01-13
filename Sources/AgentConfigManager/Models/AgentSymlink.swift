import SwiftUI

struct AgentSymlink: Identifiable, Hashable, Sendable {
    let id: AgentID
    let displayName: String
    let badgeColor: Color
    let status: Status
    let symlinkURL: URL
    let targetURL: URL?

    enum Status: Sendable, Hashable {
        case linked          // Symlink exists and points to central AGENTS.md
        case stale           // Symlink exists but points elsewhere
        case regularFile     // Regular file exists (not a symlink)
        case unlinked        // No file exists at location
        case parentMissing   // Parent directory doesn't exist

        var displayName: String {
            switch self {
            case .linked:
                return "Linked"
            case .stale:
                return "Outdated Link"
            case .regularFile:
                return "File Exists"
            case .unlinked:
                return "Unlinked"
            case .parentMissing:
                return "Not Installed"
            }
        }

        var statusDescription: String {
            switch self {
            case .linked:
                return "Symlink correctly points to central AGENTS.md"
            case .stale:
                return "Symlink exists but points to a different file. Update to link to central AGENTS.md."
            case .regularFile:
                return "A regular file exists instead of a symlink. It can be replaced with a symlink."
            case .unlinked:
                return "No AGENTS.md exists. Create a symlink to share central configuration."
            case .parentMissing:
                return "Agent's config directory doesn't exist. Install the agent first."
            }
        }

        var symbolName: String {
            switch self {
            case .linked:
                return "link"
            case .stale:
                return "exclamationmark.triangle"
            case .regularFile:
                return "doc"
            case .unlinked:
                return "link.badge.plus"
            case .parentMissing:
                return "folder.badge.questionmark"
            }
        }

        var tintColor: Color {
            switch self {
            case .linked:
                return .green
            case .stale:
                return .orange
            case .regularFile:
                return .yellow
            case .unlinked:
                return .secondary
            case .parentMissing:
                return .secondary
            }
        }

        var canLink: Bool {
            switch self {
            case .unlinked, .stale, .regularFile:
                return true
            case .linked, .parentMissing:
                return false
            }
        }

        var canUnlink: Bool {
            self == .linked
        }
    }

    /// Create from worker result and agent config
    init(from result: SymlinkWorker.SymlinkCheckResult, config: AgentConfig) {
        self.id = result.agentID
        self.displayName = config.displayName
        self.badgeColor = config.badgeColor
        self.symlinkURL = result.symlinkURL
        self.targetURL = result.targetURL
        self.status = Status(from: result.status)
    }
}

extension AgentSymlink.Status {
    init(from workerStatus: SymlinkWorker.SymlinkStatus) {
        switch workerStatus {
        case .linked:
            self = .linked
        case .stale:
            self = .stale
        case .regularFile:
            self = .regularFile
        case .unlinked:
            self = .unlinked
        case .parentMissing:
            self = .parentMissing
        }
    }
}
