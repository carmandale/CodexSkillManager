import SwiftUI

struct AgentInstallStatus: Identifiable {
    let agent: AgentConfig
    let cliInstalled: Bool
    let configExists: Bool
    let hasContent: Bool

    var id: AgentID { agent.id }

    var statusIcon: String {
        if cliInstalled && hasContent { return "checkmark.circle.fill" }
        if cliInstalled && configExists { return "circle" }
        return "minus.circle"
    }

    var statusColor: Color {
        if cliInstalled && hasContent { return .green }
        if cliInstalled && configExists { return .secondary }
        return .secondary.opacity(0.5)
    }

    var statusDescription: String {
        if cliInstalled && hasContent { return "Configured" }
        if cliInstalled && configExists { return "Installed" }
        if cliInstalled { return "CLI only" }
        return "Not installed"
    }
}
