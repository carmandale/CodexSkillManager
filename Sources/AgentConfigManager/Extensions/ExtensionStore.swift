import AppKit
import Foundation
import Observation

@MainActor
@Observable final class ExtensionStore {
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

    var extensions: [Extension] = []
    var listState: ListState = .idle
    var detailState: DetailState = .idle
    var selectedExtensionID: Extension.ID?
    var selectedSource: String = ""

    private let fileWorker = ExtensionFileWorker()

    var selectedExtension: Extension? {
        extensions.first { $0.id == selectedExtensionID }
    }

    func load() async {
        listState = .loading
        detailState = .idle

        do {
            let scanned = try await fileWorker.scanExtensions(at: AgentConfigPaths.piExtensionsURL)

            extensions = scanned.map { data in
                Extension(
                    id: data.id,
                    name: data.name,
                    folderURL: data.folderURL,
                    entryPoint: data.entryPoint,
                    providedTools: data.providedTools,
                    providedCommands: data.providedCommands,
                    isEnabled: true
                )
            }.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            listState = .loaded

            if let selectedExtensionID,
               !extensions.contains(where: { $0.id == selectedExtensionID }) {
                self.selectedExtensionID = extensions.first?.id
            } else if selectedExtensionID == nil {
                selectedExtensionID = extensions.first?.id
            }

            await loadSelectedExtension()
        } catch {
            listState = .failed(error.localizedDescription)
        }
    }

    func loadSelectedExtension() async {
        guard let selectedExtension else {
            detailState = .idle
            selectedSource = ""
            return
        }

        guard let entryPoint = selectedExtension.entryPoint else {
            detailState = .loaded
            selectedSource = "// No entry point found"
            return
        }

        let sourceURL = selectedExtension.folderURL.appendingPathComponent(entryPoint)
        detailState = .loading

        do {
            selectedSource = try await fileWorker.loadSource(at: sourceURL)
            detailState = .loaded
        } catch {
            detailState = .failed(error.localizedDescription)
            selectedSource = ""
        }
    }

    func openInFinder() {
        guard let selectedExtension else { return }
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([selectedExtension.folderURL])
        #endif
    }
}
