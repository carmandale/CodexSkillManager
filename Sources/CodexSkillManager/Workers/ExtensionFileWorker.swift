import Foundation

actor ExtensionFileWorker {
    struct ScannedExtensionData: Sendable {
        let id: String
        let name: String
        let folderURL: URL
        let entryPoint: String?
        let providedTools: [String]
        let providedCommands: [String]
    }

    func scanExtensions(at baseURL: URL) throws -> [ScannedExtensionData] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: baseURL.path) else {
            return []
        }

        let resolvedURL = baseURL.resolvingSymlinksInPath()

        let items = try fileManager.contentsOfDirectory(
            at: resolvedURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return items.compactMap { url -> ScannedExtensionData? in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            guard values?.isDirectory == true else { return nil }

            let name = url.lastPathComponent

            // Look for entry point (main.ts or index.ts)
            let mainTS = url.appendingPathComponent("main.ts")
            let indexTS = url.appendingPathComponent("index.ts")

            var entryPoint: String?
            var sourceURL: URL?

            if fileManager.fileExists(atPath: mainTS.path) {
                entryPoint = "main.ts"
                sourceURL = mainTS
            } else if fileManager.fileExists(atPath: indexTS.path) {
                entryPoint = "index.ts"
                sourceURL = indexTS
            }

            // Parse source file for tools and commands if we have an entry point
            var tools: [String] = []
            var commands: [String] = []

            if let sourceURL = sourceURL,
               let source = try? String(contentsOf: sourceURL, encoding: .utf8) {
                tools = parseProvidedTools(from: source)
                commands = parseProvidedCommands(from: source)
            }

            return ScannedExtensionData(
                id: "pi-ext-\(name)",
                name: name,
                folderURL: url,
                entryPoint: entryPoint,
                providedTools: tools,
                providedCommands: commands
            )
        }
    }

    func loadSource(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Parsing

    private func parseProvidedTools(from source: String) -> [String] {
        // Match patterns like: tool("toolName", ...) or registerTool("toolName")
        let patterns = [
            #"tool\s*\(\s*["']([^"']+)["']"#,
            #"registerTool\s*\(\s*["']([^"']+)["']"#,
            #"name:\s*["']([^"']+)["']"#
        ]

        var tools: [String] = []
        for pattern in patterns {
            tools.append(contentsOf: extractMatches(from: source, pattern: pattern))
        }
        return Array(Set(tools)).sorted()
    }

    private func parseProvidedCommands(from source: String) -> [String] {
        // Match patterns like: command("commandName", ...) or registerCommand("/commandName")
        let patterns = [
            #"command\s*\(\s*["']([^"']+)["']"#,
            #"registerCommand\s*\(\s*["'](/[^"']+)["']"#
        ]

        var commands: [String] = []
        for pattern in patterns {
            commands.append(contentsOf: extractMatches(from: source, pattern: pattern))
        }
        return Array(Set(commands)).sorted()
    }

    private func extractMatches(from source: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(source.startIndex..., in: source)
        let matches = regex.matches(in: source, options: [], range: range)

        return matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: source) else {
                return nil
            }
            return String(source[range])
        }
    }
}
