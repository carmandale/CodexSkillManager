import AppKit
import Foundation
import Observation

@MainActor
@Observable final class CommandStore {
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

    var commands: [Command] = []
    var listState: ListState = .idle
    var detailState: DetailState = .idle
    var selectedCommandID: Command.ID?
    var selectedContent: String = ""

    private let fileWorker = CommandFileWorker()

    var selectedCommand: Command? {
        commands.first { $0.id == selectedCommandID }
    }

    func load() async {
        listState = .loading
        detailState = .idle

        do {
            var allCommands: [Command] = []

            for source in CommandSource.allCases {
                let scanned = try await fileWorker.scanCommands(at: source.rootURL, source: source)
                allCommands.append(contentsOf: scanned.map { data in
                    Command(
                        id: data.id,
                        name: data.name,
                        description: data.description,
                        source: data.source,
                        fileURL: data.fileURL
                    )
                })
            }

            commands = allCommands.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            listState = .loaded

            if let selectedCommandID,
               !commands.contains(where: { $0.id == selectedCommandID }) {
                self.selectedCommandID = commands.first?.id
            } else if selectedCommandID == nil {
                selectedCommandID = commands.first?.id
            }

            await loadSelectedCommand()
        } catch {
            listState = .failed(error.localizedDescription)
        }
    }

    func loadSelectedCommand() async {
        guard let selectedCommand else {
            detailState = .idle
            selectedContent = ""
            return
        }

        detailState = .loading

        do {
            let raw = try await fileWorker.loadContent(at: selectedCommand.fileURL)
            selectedContent = stripFrontmatter(from: raw)
            detailState = .loaded
        } catch {
            detailState = .failed(error.localizedDescription)
            selectedContent = ""
        }
    }

    func openInFinder() {
        guard let selectedCommand else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedCommand.fileURL])
    }
}
