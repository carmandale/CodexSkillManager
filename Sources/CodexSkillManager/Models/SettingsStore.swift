import Foundation

@Observable
@MainActor
final class SettingsStore: Sendable {
    private static let watchedDirectoriesKey = "watchedDirectories"
    private static let selectedAgentsKey = "selectedAgents"

    var watchedDirectories: [URL]
    var selectedAgents: Set<AgentID>

    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.watchedDirectories = [homeDir.appending(path: "dev")]
        self.selectedAgents = []
        load()
    }

    func load() {
        let defaults = UserDefaults.standard

        if let paths = defaults.stringArray(forKey: Self.watchedDirectoriesKey) {
            watchedDirectories = paths.map { URL(fileURLWithPath: $0) }
        }

        if let rawValues = defaults.stringArray(forKey: Self.selectedAgentsKey) {
            selectedAgents = Set(rawValues.compactMap { AgentID(rawValue: $0) })
        }
    }

    func save() {
        let defaults = UserDefaults.standard

        let paths = watchedDirectories.map { $0.path }
        defaults.set(paths, forKey: Self.watchedDirectoriesKey)

        let rawValues = selectedAgents.map { $0.rawValue }
        defaults.set(rawValues, forKey: Self.selectedAgentsKey)
    }
}
