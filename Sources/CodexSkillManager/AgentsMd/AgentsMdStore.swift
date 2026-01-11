import AppKit
import Foundation
import Observation

@MainActor
@Observable final class AgentsMdStore {
    enum ListState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum DetailState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var symlinks: [AgentSymlink] = []
    var listState: ListState = .idle
    var detailState: DetailState = .idle
    var selectedAgentID: AgentID?
    var centralContent: String = ""
    var centralFileExists: Bool = false
    var hasUnsavedChanges: Bool = false

    private let worker = SymlinkWorker()
    private let centralURL = AgentConfigPaths.centralAgentsMarkdownURL

    var selectedSymlink: AgentSymlink? {
        symlinks.first { $0.id == selectedAgentID }
    }

    var linkedCount: Int {
        symlinks.filter { $0.status == .linked }.count
    }

    var totalCount: Int {
        symlinks.count
    }

    func load() async {
        listState = .loading

        // Gather agent locations from configs
        let locations: [SymlinkWorker.AgentMarkdownLocation] = AgentConfig.all.compactMap { config in
            guard let url = config.agentsMarkdownURL else { return nil }
            return SymlinkWorker.AgentMarkdownLocation(agentID: config.id, url: url)
        }

        // Check symlink statuses
        let results = await worker.checkAllSymlinks(locations: locations, centralURL: centralURL)

        // Map results to view models
        symlinks = results.compactMap { result in
            guard let config = AgentConfig.all.first(where: { $0.id == result.agentID }) else {
                return nil
            }
            return AgentSymlink(from: result, config: config)
        }

        // Sort by display name
        symlinks.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

        listState = .loaded

        // Auto-select first if none selected
        if selectedAgentID == nil || !symlinks.contains(where: { $0.id == selectedAgentID }) {
            selectedAgentID = symlinks.first?.id
        }

        await loadCentralContent()
    }

    func loadCentralContent() async {
        detailState = .loading

        centralFileExists = await worker.centralFileExists(at: centralURL)

        if centralFileExists {
            do {
                centralContent = try await worker.readContent(at: centralURL)
                detailState = .loaded
            } catch {
                detailState = .failed(error.localizedDescription)
                centralContent = ""
            }
        } else {
            centralContent = defaultAgentsMarkdown()
            detailState = .loaded
        }

        hasUnsavedChanges = false
    }

    func saveCentralContent() async throws {
        try await worker.writeContent(centralContent, to: centralURL)
        centralFileExists = true
        hasUnsavedChanges = false
        // Reload symlink statuses since central file existence may have changed
        await load()
    }

    func createSymlink(for agentID: AgentID) async throws {
        guard let config = AgentConfig.all.first(where: { $0.id == agentID }),
              let symlinkURL = config.agentsMarkdownURL else {
            throw NSError(
                domain: "AgentsMdStore",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Agent configuration not found"]
            )
        }

        // Ensure central file exists first
        if !centralFileExists {
            try await saveCentralContent()
        }

        try await worker.createSymlink(at: symlinkURL, pointingTo: centralURL)
        await load()
    }

    func removeSymlink(for agentID: AgentID) async throws {
        guard let config = AgentConfig.all.first(where: { $0.id == agentID }),
              let symlinkURL = config.agentsMarkdownURL else {
            throw NSError(
                domain: "AgentsMdStore",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Agent configuration not found"]
            )
        }

        try await worker.removeSymlink(at: symlinkURL)
        await load()
    }

    func linkAllAgents() async throws {
        // Ensure central file exists first
        if !centralFileExists {
            try await saveCentralContent()
        }

        for symlink in symlinks where symlink.status.canLink {
            guard let config = AgentConfig.all.first(where: { $0.id == symlink.id }),
                  let symlinkURL = config.agentsMarkdownURL else {
                continue
            }
            try await worker.createSymlink(at: symlinkURL, pointingTo: centralURL)
        }

        await load()
    }

    func openCentralFolder() {
        let folderURL = centralURL.deletingLastPathComponent()
        NSWorkspace.shared.selectFile(centralURL.path, inFileViewerRootedAtPath: folderURL.path)
    }

    func openAgentFolder(for agentID: AgentID) {
        guard let config = AgentConfig.all.first(where: { $0.id == agentID }),
              let url = config.agentsMarkdownURL else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func defaultAgentsMarkdown() -> String {
        """
        # AGENTS.md

        Global instructions for AI coding agents.

        ## About This File

        This file is symlinked from multiple AI agent configuration directories:
        - `~/.pi/agent/AGENTS.md` (Pi Agent)
        - `~/.claude/AGENTS.md` (Claude Code)
        - `~/.codex/AGENTS.md` (Codex)
        - `~/.opencode/AGENTS.md` (OpenCode)
        - `~/.github-copilot/AGENTS.md` (GitHub Copilot)

        Edit this central file to configure instructions for all agents.

        ## Instructions

        Add your global agent instructions here.
        """
    }
}
