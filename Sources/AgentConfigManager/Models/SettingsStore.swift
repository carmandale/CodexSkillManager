import Foundation

@Observable
@MainActor
final class SettingsStore: Sendable {
    private static let watchedDirectoriesKey = "watchedDirectories"

    var watchedDirectories: [URL]

    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.watchedDirectories = [homeDir.appending(path: "dev")]
        load()
    }

    func load() {
        let defaults = UserDefaults.standard

        if let paths = defaults.stringArray(forKey: Self.watchedDirectoriesKey) {
            watchedDirectories = paths.map { URL(fileURLWithPath: $0) }
        }
    }

    func save() {
        let defaults = UserDefaults.standard

        let paths = watchedDirectories.map { $0.path }
        defaults.set(paths, forKey: Self.watchedDirectoriesKey)
    }
}
