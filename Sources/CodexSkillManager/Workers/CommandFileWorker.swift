import Foundation

actor CommandFileWorker {
    struct ScannedCommandData: Sendable {
        let id: String
        let name: String
        let description: String
        let source: CommandSource
        let fileURL: URL
    }

    func scanCommands(at baseURL: URL, source: CommandSource) throws -> [ScannedCommandData] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: baseURL.path) else {
            return []
        }

        let resolvedURL = baseURL.resolvingSymlinksInPath()

        let items = try fileManager.contentsOfDirectory(
            at: resolvedURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return items.compactMap { url -> ScannedCommandData? in
            guard url.pathExtension.lowercased() == "md" else { return nil }

            let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
            guard values?.isRegularFile == true else { return nil }

            let name = url.deletingPathExtension().lastPathComponent
            let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let description = parseDescription(from: content)

            return ScannedCommandData(
                id: "\(source.rawValue)-\(name)",
                name: name,
                description: description,
                source: source,
                fileURL: url
            )
        }
    }

    func loadContent(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    private func parseDescription(from content: String) -> String {
        // Parse YAML frontmatter for description
        let lines = content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return extractFirstParagraph(from: content)
        }

        var index = 1
        while index < lines.count {
            let line = String(lines[index])
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                break
            }

            if line.hasPrefix("description:") {
                let value = String(line.dropFirst("description:".count))
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                if !value.isEmpty {
                    return value
                }
            }
            index += 1
        }

        return extractFirstParagraph(from: content)
    }

    private func extractFirstParagraph(from content: String) -> String {
        let lines = content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

        // Skip frontmatter
        var startIndex = 0
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---" {
            startIndex = 1
            while startIndex < lines.count {
                if lines[startIndex].trimmingCharacters(in: .whitespaces) == "---" {
                    startIndex += 1
                    break
                }
                startIndex += 1
            }
        }

        // Find first non-empty, non-heading line
        for index in startIndex..<lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespaces)
            if !line.isEmpty && !line.hasPrefix("#") {
                return String(line)
            }
        }

        return "No description available"
    }
}
