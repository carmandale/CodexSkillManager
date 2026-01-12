import Foundation
import Observation

@Observable
@MainActor
final class AgentStatusStore {
    var statuses: [AgentInstallStatus] = []

    func load() async {
        var results: [AgentInstallStatus] = []

        for config in AgentConfig.all {
            let status = await Self.checkStatus(for: config)
            results.append(status)
        }

        statuses = results
    }

    /// Nonisolated helper to avoid Sendable capture issues
    private static func checkStatus(for config: AgentConfig) async -> AgentInstallStatus {
        let cliInstalled = await checkCLIExists(config.id.cliName)
        let configExists = checkConfigExists(for: config)
        let hasContent = checkHasContent(for: config)

        return AgentInstallStatus(
            agent: config,
            cliInstalled: cliInstalled,
            configExists: configExists,
            hasContent: hasContent
        )
    }

    private static func checkCLIExists(_ name: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func checkConfigExists(for config: AgentConfig) -> Bool {
        let fm = FileManager.default
        // Check if the root directory exists (parent of skills)
        if let skillsURL = config.skillsURL {
            return fm.fileExists(atPath: skillsURL.deletingLastPathComponent().path)
        }
        return false
    }

    private static func checkHasContent(for config: AgentConfig) -> Bool {
        let fm = FileManager.default

        // Check all content URLs
        for url in config.capabilities.contentURLs {
            if let contents = try? fm.contentsOfDirectory(atPath: url.path) {
                let hasNonHidden = contents.contains { !$0.hasPrefix(".") }
                if hasNonHidden { return true }
            }
        }

        return false
    }
}
