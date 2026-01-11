import Foundation

actor RepoScanWorker {
    struct ScannedRepoData: Sendable {
        let id: String
        let name: String
        let folderURL: URL
        let agentsMdURL: URL?
        let status: RepoStatus
        let fileSizeBytes: Int64
    }

    /// Threshold in bytes above which an AGENTS.md is considered "bloated"
    /// (likely contains global content that should be centralized)
    private let bloatedThreshold: Int64 = 1024 // 1KB

    func scanRepos(in directories: [URL]) throws -> [ScannedRepoData] {
        let fileManager = FileManager.default
        var repos: [ScannedRepoData] = []

        for directory in directories {
            let resolved = directory.resolvingSymlinksInPath()
            guard fileManager.fileExists(atPath: resolved.path) else { continue }

            let enumerator = fileManager.enumerator(
                at: resolved,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            while let itemURL = enumerator?.nextObject() as? URL {
                // Check if this is a git repo
                let gitDir = itemURL.appendingPathComponent(".git")
                var isDirectory: ObjCBool = false

                guard fileManager.fileExists(atPath: gitDir.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

                // Skip nested repos (don't descend into .git directories)
                enumerator?.skipDescendants()

                // Found a git repo - check for AGENTS.md
                let agentsMdURL = itemURL.appendingPathComponent("AGENTS.md")
                let hasAgentsMd = fileManager.fileExists(atPath: agentsMdURL.path)

                let (status, fileSize) = determineStatus(
                    agentsMdURL: hasAgentsMd ? agentsMdURL : nil,
                    fileManager: fileManager
                )

                let repo = ScannedRepoData(
                    id: itemURL.path,
                    name: itemURL.lastPathComponent,
                    folderURL: itemURL,
                    agentsMdURL: hasAgentsMd ? agentsMdURL : nil,
                    status: status,
                    fileSizeBytes: fileSize
                )
                repos.append(repo)
            }
        }

        return repos
    }

    func loadContent(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    private func determineStatus(
        agentsMdURL: URL?,
        fileManager: FileManager
    ) -> (RepoStatus, Int64) {
        guard let url = agentsMdURL else {
            return (.noAgentsMd, 0)
        }

        do {
            let attrs = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = (attrs[.size] as? Int64) ?? 0

            if fileSize > bloatedThreshold {
                return (.bloated, fileSize)
            } else {
                return (.minimal, fileSize)
            }
        } catch {
            return (.noAgentsMd, 0)
        }
    }
}
