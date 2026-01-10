import Foundation

enum NavigationSection: String, CaseIterable, Identifiable {
    case skills
    case extensions
    case commands
    case agentsmd
    case repos
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .skills:
            return "Skills"
        case .extensions:
            return "Extensions"
        case .commands:
            return "Commands"
        case .agentsmd:
            return "AGENTS.md"
        case .repos:
            return "Repos"
        }
    }
    
    var symbolName: String {
        switch self {
        case .skills:
            return "puzzlepiece.extension"
        case .extensions:
            return "square.stack.3d.up"
        case .commands:
            return "command"
        case .agentsmd:
            return "doc.text"
        case .repos:
            return "folder"
        }
    }
}
