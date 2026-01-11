import AppKit
import Foundation
import Observation

@MainActor
@Observable final class RepoStore {
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

    var repos: [Repo] = []
    var listState: ListState = .idle
    var detailState: DetailState = .idle
    var selectedRepoID: Repo.ID?
    var selectedContent: String = ""

    private let fileWorker = RepoScanWorker()
    private unowned let settings: SettingsStore

    var selectedRepo: Repo? {
        repos.first { $0.id == selectedRepoID }
    }

    var bloatedRepos: [Repo] {
        repos.filter { $0.status == .bloated }
    }

    var minimalRepos: [Repo] {
        repos.filter { $0.status == .minimal }
    }

    var noAgentsMdRepos: [Repo] {
        repos.filter { $0.status == .noAgentsMd }
    }

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func load() async {
        listState = .loading
        detailState = .idle

        do {
            let scanned = try await fileWorker.scanRepos(in: settings.watchedDirectories)

            repos = scanned.map { data in
                Repo(
                    id: data.id,
                    name: data.name,
                    folderURL: data.folderURL,
                    agentsMdURL: data.agentsMdURL,
                    status: data.status,
                    fileSizeBytes: data.fileSizeBytes
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            listState = .loaded

            if let selectedRepoID,
               !repos.contains(where: { $0.id == selectedRepoID }) {
                self.selectedRepoID = repos.first?.id
            } else if selectedRepoID == nil {
                selectedRepoID = repos.first?.id
            }

            await loadSelectedRepo()
        } catch {
            listState = .failed(error.localizedDescription)
        }
    }

    func loadSelectedRepo() async {
        guard let selectedRepo, let agentsMdURL = selectedRepo.agentsMdURL else {
            detailState = .idle
            selectedContent = ""
            return
        }

        detailState = .loading

        do {
            selectedContent = try await fileWorker.loadContent(at: agentsMdURL)
            detailState = .loaded
        } catch {
            detailState = .failed(error.localizedDescription)
            selectedContent = ""
        }
    }

    func openInFinder() {
        guard let selectedRepo else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedRepo.folderURL])
    }

    func openAgentsMdInEditor() {
        guard let selectedRepo, let agentsMdURL = selectedRepo.agentsMdURL else { return }
        NSWorkspace.shared.open(agentsMdURL)
    }
}
