import Foundation

/// Describes how an agent supports a particular capability
enum SupportMode: Hashable, Sendable {
    /// Not supported
    case none

    /// Supported via a dedicated folder
    case folder(URL)

    /// Supported via the extension system (Pi Agent)
    case viaExtensions

    /// Supported via the plugin system (OpenCode)
    case viaPlugins

    /// Supported via a settings/config file
    case viaSettings(URL)

    var isSupported: Bool {
        if case .none = self { return false }
        return true
    }

    var folderURL: URL? {
        if case .folder(let url) = self { return url }
        return nil
    }

    var displayDescription: String {
        switch self {
        case .none: return "Not supported"
        case .folder: return "Folder"
        case .viaExtensions: return "Via extensions"
        case .viaPlugins: return "Via plugins"
        case .viaSettings: return "Via settings"
        }
    }
}
