import Foundation

@Observable
@MainActor
final class HookStore {
    var hooks: [Hook] = []
    var selectedHookID: String?
    var selectedSource: String = ""
    var isLoading = false
    var isLoadingSource = false
    var errorMessage: String?

    /// Hooks grouped by event type
    var hooksByEventType: [HookEventType: [Hook]] {
        Dictionary(grouping: hooks, by: \.eventType)
    }

    /// Hooks grouped by agent
    var hooksByAgent: [AgentID: [Hook]] {
        Dictionary(grouping: hooks, by: \.agentID)
    }

    var selectedHook: Hook? {
        hooks.first { $0.id == selectedHookID }
    }

    func loadSelectedHookSource() async {
        guard let hook = selectedHook else {
            selectedSource = ""
            return
        }

        isLoadingSource = true

        // Extract source path from command
        // Commands like: node "/path/to/script.mjs"
        // or: python "/path/to/script.py"
        let sourceURL = extractSourcePath(from: hook.command)

        if let url = sourceURL, FileManager.default.fileExists(atPath: url.path) {
            do {
                selectedSource = try String(contentsOf: url, encoding: .utf8)
            } catch {
                selectedSource = "// Error loading source: \(error.localizedDescription)"
            }
        } else {
            selectedSource = "// Source file not found\n// Command: \(hook.command)"
        }

        isLoadingSource = false
    }

    private func extractSourcePath(from command: String) -> URL? {
        // Try to find quoted path in command
        let pattern = "\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: command, range: NSRange(command.startIndex..., in: command)),
              let range = Range(match.range(at: 1), in: command) else {
            return nil
        }

        let path = String(command[range])
        return URL(fileURLWithPath: path)
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        var allHooks: [Hook] = []

        // Load Claude hooks from settings.json
        if let claudeHooks = await loadClaudeHooks() {
            allHooks.append(contentsOf: claudeHooks)
        }

        // Load Pi hooks (from extensions - different format)
        // Pi hooks are part of extensions, so we note that here
        // but don't load them separately

        hooks = allHooks
        isLoading = false

        if selectedHookID == nil, let first = hooks.first {
            selectedHookID = first.id
        }
    }

    private func loadClaudeHooks() async -> [Hook]? {
        let settingsURL = AgentConfigPaths.claudeSettingsURL
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: settingsURL)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let hooksConfig = json["hooks"] as? [String: Any] else {
                return nil
            }

            var hooks: [Hook] = []

            for eventType in HookEventType.allCases {
                guard let eventHooks = hooksConfig[eventType.rawValue] as? [[String: Any]] else {
                    continue
                }

                for (index, hookGroup) in eventHooks.enumerated() {
                    let matcher = hookGroup["matcher"] as? String

                    if let hooksList = hookGroup["hooks"] as? [[String: Any]] {
                        for (hookIndex, hookConfig) in hooksList.enumerated() {
                            if let command = hookConfig["command"] as? String {
                                let timeout = hookConfig["timeout"] as? Int
                                let id = "\(eventType.rawValue)-\(index)-\(hookIndex)"

                                hooks.append(Hook(
                                    id: id,
                                    eventType: eventType,
                                    matcher: matcher,
                                    command: command,
                                    timeout: timeout,
                                    agentID: .claude
                                ))
                            }
                        }
                    }
                }
            }

            return hooks
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
