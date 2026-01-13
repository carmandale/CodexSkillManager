import Foundation

/// A plugin installed for an agent
struct Plugin: Identifiable, Hashable {
    let id: String
    let name: String
    let marketplace: String
    let version: String
    let installPath: URL
    let installedAt: Date?
    let agentID: AgentID

    var displayName: String {
        name
    }

    var marketplaceDisplay: String {
        marketplace.replacingOccurrences(of: "-marketplace", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}
