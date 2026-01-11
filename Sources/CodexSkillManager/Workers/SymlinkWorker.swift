import Foundation

actor SymlinkWorker {
    enum SymlinkStatus: Sendable, Equatable {
        case linked          // Symlink exists and points to central AGENTS.md
        case stale           // Symlink exists but points elsewhere
        case regularFile     // Regular file exists (not a symlink)
        case unlinked        // No file exists at location
        case parentMissing   // Parent directory doesn't exist
    }

    struct SymlinkCheckResult: Sendable {
        let agentID: AgentID
        let status: SymlinkStatus
        let symlinkURL: URL
        let targetURL: URL?
    }

    private let fileManager = FileManager.default

    struct AgentMarkdownLocation: Sendable {
        let agentID: AgentID
        let url: URL
    }

    /// Check symlink status for given agent locations
    func checkAllSymlinks(
        locations: [AgentMarkdownLocation],
        centralURL: URL
    ) -> [SymlinkCheckResult] {
        var results: [SymlinkCheckResult] = []

        for location in locations {
            let result = checkSymlink(
                agentID: location.agentID,
                at: location.url,
                expectedTarget: centralURL
            )
            results.append(result)
        }

        return results
    }

    /// Check symlink status for a single agent
    func checkSymlink(
        agentID: AgentID,
        at symlinkURL: URL,
        expectedTarget: URL
    ) -> SymlinkCheckResult {
        let symlinkPath = symlinkURL.path

        // Check if parent directory exists
        let parentDir = symlinkURL.deletingLastPathComponent()
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: parentDir.path, isDirectory: &isDir),
              isDir.boolValue else {
            return SymlinkCheckResult(
                agentID: agentID,
                status: .parentMissing,
                symlinkURL: symlinkURL,
                targetURL: nil
            )
        }

        // Check if file exists at symlink location
        guard fileManager.fileExists(atPath: symlinkPath) else {
            return SymlinkCheckResult(
                agentID: agentID,
                status: .unlinked,
                symlinkURL: symlinkURL,
                targetURL: nil
            )
        }

        // Check if it's a symlink
        guard let attrs = try? fileManager.attributesOfItem(atPath: symlinkPath),
              let fileType = attrs[.type] as? FileAttributeType,
              fileType == .typeSymbolicLink else {
            return SymlinkCheckResult(
                agentID: agentID,
                status: .regularFile,
                symlinkURL: symlinkURL,
                targetURL: nil
            )
        }

        // Read symlink destination
        guard let destination = try? fileManager.destinationOfSymbolicLink(atPath: symlinkPath) else {
            return SymlinkCheckResult(
                agentID: agentID,
                status: .stale,
                symlinkURL: symlinkURL,
                targetURL: nil
            )
        }

        // Resolve to absolute path
        let resolvedTarget: URL
        if destination.hasPrefix("/") {
            resolvedTarget = URL(fileURLWithPath: destination)
        } else {
            resolvedTarget = parentDir.appendingPathComponent(destination).standardized
        }

        // Check if it points to the expected central file
        if resolvedTarget.standardized.path == expectedTarget.standardized.path {
            return SymlinkCheckResult(
                agentID: agentID,
                status: .linked,
                symlinkURL: symlinkURL,
                targetURL: resolvedTarget
            )
        } else {
            return SymlinkCheckResult(
                agentID: agentID,
                status: .stale,
                symlinkURL: symlinkURL,
                targetURL: resolvedTarget
            )
        }
    }

    /// Create a symlink from agent's AGENTS.md location to central AGENTS.md
    func createSymlink(at symlinkURL: URL, pointingTo targetURL: URL) throws {
        let symlinkPath = symlinkURL.path
        let targetPath = targetURL.path

        // Ensure parent directory exists
        let parentDir = symlinkURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        // Remove existing file/symlink if present
        if fileManager.fileExists(atPath: symlinkPath) {
            try fileManager.removeItem(atPath: symlinkPath)
        }

        // Create symlink
        try fileManager.createSymbolicLink(atPath: symlinkPath, withDestinationPath: targetPath)
    }

    /// Remove a symlink (only if it is a symlink, not a regular file)
    func removeSymlink(at symlinkURL: URL) throws {
        let symlinkPath = symlinkURL.path

        guard fileManager.fileExists(atPath: symlinkPath) else {
            return // Nothing to remove
        }

        // Verify it's a symlink before removing
        guard let attrs = try? fileManager.attributesOfItem(atPath: symlinkPath),
              let fileType = attrs[.type] as? FileAttributeType,
              fileType == .typeSymbolicLink else {
            throw NSError(
                domain: "SymlinkWorker",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot remove: not a symlink"]
            )
        }

        try fileManager.removeItem(atPath: symlinkPath)
    }

    /// Read content from the central AGENTS.md file
    func readContent(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    /// Write content to the central AGENTS.md file
    func writeContent(_ content: String, to url: URL) throws {
        // Ensure parent directory exists
        let parentDir = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Check if the central AGENTS.md file exists
    func centralFileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
}
