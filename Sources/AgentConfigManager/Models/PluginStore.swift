import Foundation

@Observable
@MainActor
final class PluginStore {
    var plugins: [Plugin] = []
    var selectedPluginID: String?
    var isLoading = false

    var pluginsByAgent: [AgentID: [Plugin]] {
        Dictionary(grouping: plugins, by: \.agentID)
    }

    var selectedPlugin: Plugin? {
        plugins.first { $0.id == selectedPluginID }
    }

    func load() async {
        isLoading = true
        var allPlugins: [Plugin] = []

        // Load Claude plugins from installed_plugins.json
        if let claudePlugins = await loadClaudePlugins() {
            allPlugins.append(contentsOf: claudePlugins)
        }

        // OpenCode plugins would go here if we can find their format

        plugins = allPlugins.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        isLoading = false

        if selectedPluginID == nil, let first = plugins.first {
            selectedPluginID = first.id
        }
    }

    private func loadClaudePlugins() async -> [Plugin]? {
        let installedPluginsURL = AgentConfigPaths.claudePluginsURL.appending(path: "installed_plugins.json")
        guard FileManager.default.fileExists(atPath: installedPluginsURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: installedPluginsURL)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pluginsDict = json["plugins"] as? [String: [[String: Any]]] else {
                return nil
            }

            var plugins: [Plugin] = []
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            for (key, installs) in pluginsDict {
                // Key format: "name@marketplace"
                let parts = key.split(separator: "@", maxSplits: 1)
                let name = String(parts[0])
                let marketplace = parts.count > 1 ? String(parts[1]) : "unknown"

                if let install = installs.first,
                   let version = install["version"] as? String,
                   let installPathString = install["installPath"] as? String {
                    let installPath = URL(fileURLWithPath: installPathString)
                    let installedAt = (install["installedAt"] as? String).flatMap { dateFormatter.date(from: $0) }

                    plugins.append(Plugin(
                        id: key,
                        name: name,
                        marketplace: marketplace,
                        version: version,
                        installPath: installPath,
                        installedAt: installedAt,
                        agentID: .claude
                    ))
                }
            }

            return plugins
        } catch {
            return nil
        }
    }
}
