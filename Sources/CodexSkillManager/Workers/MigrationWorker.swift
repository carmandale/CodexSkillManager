import Foundation

/// Actor responsible for migrating from legacy opencode-config to ~/.agent-config
actor MigrationWorker {
    private let fileManager = FileManager.default

    // URLs passed in during initialization to avoid @MainActor issues
    private let legacyRootURL: URL
    private let legacyAgentsMarkdownURL: URL
    private let legacyCommandsURL: URL
    private let legacyKnowledgeURL: URL
    private let centralRootURL: URL
    private let centralAgentsMarkdownURL: URL
    private let centralCommandsURL: URL
    private let centralKnowledgeURL: URL
    private let homePath: String

    /// Item types that can be migrated
    enum MigrationItem: String, CaseIterable, Sendable {
        case agentsMarkdown = "AGENTS.md"
        case commands = "commands"
        case knowledge = "knowledge"

        var displayName: String {
            switch self {
            case .agentsMarkdown:
                return "AGENTS.md"
            case .commands:
                return "Commands directory"
            case .knowledge:
                return "Knowledge directory"
            }
        }
    }

    /// Status of a single migration item
    struct ItemStatus: Sendable {
        let item: MigrationItem
        let legacyExists: Bool
        let centralExists: Bool
        let legacyFileCount: Int
        let canMigrate: Bool
        let legacyPath: String
        let centralPath: String

        var statusDescription: String {
            if !legacyExists {
                return "No legacy data"
            } else if centralExists {
                return "Already exists in central"
            } else {
                return "Ready to migrate"
            }
        }
    }

    /// Overall migration status
    struct MigrationStatus: Sendable {
        let legacyConfigExists: Bool
        let centralConfigExists: Bool
        let items: [ItemStatus]

        var needsMigration: Bool {
            legacyConfigExists && items.contains { $0.canMigrate }
        }

        var migrableItemCount: Int {
            items.filter(\.canMigrate).count
        }
    }

    /// Result of migration operation
    struct MigrationResult: Sendable {
        let item: MigrationItem
        let success: Bool
        let message: String
    }

    /// Initialize with pre-resolved URLs
    init(
        legacyRootURL: URL,
        legacyAgentsMarkdownURL: URL,
        legacyCommandsURL: URL,
        legacyKnowledgeURL: URL,
        centralRootURL: URL,
        centralAgentsMarkdownURL: URL,
        centralCommandsURL: URL,
        centralKnowledgeURL: URL,
        homePath: String
    ) {
        self.legacyRootURL = legacyRootURL
        self.legacyAgentsMarkdownURL = legacyAgentsMarkdownURL
        self.legacyCommandsURL = legacyCommandsURL
        self.legacyKnowledgeURL = legacyKnowledgeURL
        self.centralRootURL = centralRootURL
        self.centralAgentsMarkdownURL = centralAgentsMarkdownURL
        self.centralCommandsURL = centralCommandsURL
        self.centralKnowledgeURL = centralKnowledgeURL
        self.homePath = homePath
    }

    private func legacyURL(for item: MigrationItem) -> URL {
        switch item {
        case .agentsMarkdown: return legacyAgentsMarkdownURL
        case .commands: return legacyCommandsURL
        case .knowledge: return legacyKnowledgeURL
        }
    }

    private func centralURL(for item: MigrationItem) -> URL {
        switch item {
        case .agentsMarkdown: return centralAgentsMarkdownURL
        case .commands: return centralCommandsURL
        case .knowledge: return centralKnowledgeURL
        }
    }

    /// Check if migration is needed
    func checkMigrationNeeded() -> Bool {
        let status = checkMigrationStatus()
        return status.needsMigration
    }

    /// Get detailed migration status for all items
    func checkMigrationStatus() -> MigrationStatus {
        let legacyExists = fileManager.fileExists(atPath: legacyRootURL.path)
        let centralExists = fileManager.fileExists(atPath: centralRootURL.path)

        let items = MigrationItem.allCases.map { item -> ItemStatus in
            let legacyItemURL = legacyURL(for: item)
            let centralItemURL = centralURL(for: item)
            let legacyPath = legacyItemURL.path
            let centralPath = centralItemURL.path

            let legacyItemExists = fileManager.fileExists(atPath: legacyPath)
            let centralItemExists = fileManager.fileExists(atPath: centralPath)

            var fileCount = 0
            if legacyItemExists {
                if item == .agentsMarkdown {
                    fileCount = 1
                } else {
                    // Count files in directory
                    if let contents = try? fileManager.contentsOfDirectory(atPath: legacyPath) {
                        fileCount = contents.count
                    }
                }
            }

            let canMigrate = legacyItemExists && !centralItemExists

            return ItemStatus(
                item: item,
                legacyExists: legacyItemExists,
                centralExists: centralItemExists,
                legacyFileCount: fileCount,
                canMigrate: canMigrate,
                legacyPath: displayPath(for: legacyItemURL),
                centralPath: displayPath(for: centralItemURL)
            )
        }

        return MigrationStatus(
            legacyConfigExists: legacyExists,
            centralConfigExists: centralExists,
            items: items
        )
    }

    /// Migrate a single item from legacy to central
    func migrate(item: MigrationItem) async throws -> MigrationResult {
        let legacyItemURL = legacyURL(for: item)
        let centralItemURL = centralURL(for: item)
        let legacyPath = legacyItemURL.path
        let centralPath = centralItemURL.path

        // Ensure legacy exists
        guard fileManager.fileExists(atPath: legacyPath) else {
            return MigrationResult(
                item: item,
                success: false,
                message: "Legacy item does not exist"
            )
        }

        // Ensure central doesn't already exist
        guard !fileManager.fileExists(atPath: centralPath) else {
            return MigrationResult(
                item: item,
                success: false,
                message: "Central location already exists"
            )
        }

        // Ensure parent directory exists
        let centralParent = centralItemURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: centralParent.path) {
            try fileManager.createDirectory(at: centralParent, withIntermediateDirectories: true)
        }

        // Copy to central (not move - keep legacy as backup)
        try fileManager.copyItem(atPath: legacyPath, toPath: centralPath)

        return MigrationResult(
            item: item,
            success: true,
            message: "Successfully migrated \(item.displayName)"
        )
    }

    /// Migrate all eligible items
    func migrateAll() async throws -> [MigrationResult] {
        let status = checkMigrationStatus()
        var results: [MigrationResult] = []

        for itemStatus in status.items where itemStatus.canMigrate {
            do {
                let result = try await migrate(item: itemStatus.item)
                results.append(result)
            } catch {
                results.append(MigrationResult(
                    item: itemStatus.item,
                    success: false,
                    message: error.localizedDescription
                ))
            }
        }

        return results
    }

    /// Get human-readable path (with ~ for home)
    private func displayPath(for url: URL) -> String {
        url.path.replacingOccurrences(of: homePath, with: "~")
    }
}
