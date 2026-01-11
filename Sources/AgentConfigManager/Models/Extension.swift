import Foundation

struct Extension: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let folderURL: URL
    let entryPoint: String?
    let providedTools: [String]
    let providedCommands: [String]
    var isEnabled: Bool

    var folderPath: String { folderURL.path }
}
