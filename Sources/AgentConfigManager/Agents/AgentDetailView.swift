import SwiftUI
import AppKit

struct AgentDetailView: View {
    let agent: AgentConfig

    var body: some View {
        Form {
            Section("Paths") {
                if let url = agent.skillsURL {
                    PathRow(label: "Skills", url: url)
                }
                if let url = agent.extensionsURL {
                    PathRow(label: "Extensions", url: url)
                }
                if let url = agent.pluginsURL {
                    PathRow(label: "Plugins", url: url)
                }
                if let url = agent.hooksURL {
                    PathRow(label: "Hooks", url: url)
                }
                if let url = agent.commandsURL {
                    PathRow(label: "Commands", url: url)
                }
                if let url = agent.instructionsURL {
                    PathRow(label: "Instructions", url: url)
                }
            }

            Section("Capabilities") {
                CapabilityRow("Skills", mode: agent.capabilities.skills)
                CapabilityRow("Extensions", mode: agent.capabilities.extensions)
                CapabilityRow("Plugins", mode: agent.capabilities.plugins)
                CapabilityRow("Hooks", mode: agent.capabilities.hooks)
                CapabilityRow("Commands", mode: agent.capabilities.commands)
            }

            Section("Documentation") {
                if let fileURL = agent.capabilities.documentation.fileURL {
                    DocumentationRow(
                        label: agent.capabilities.documentation.fileDisplayName,
                        type: .file(fileURL)
                    )
                }
                if let websiteURL = agent.capabilities.documentation.websiteURL {
                    DocumentationRow(
                        label: "Website",
                        type: .website(websiteURL)
                    )
                }
                LabeledContent("Skill Doc Filename") {
                    Text(agent.capabilities.skillDocFilename)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(agent.displayName)
    }
}

private struct PathRow: View {
    let label: String
    let url: URL

    private var displayPath: String {
        url.path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }

    var body: some View {
        LabeledContent(label) {
            HStack {
                Text(displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Button {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

private struct CapabilityRow: View {
    let name: String
    let mode: SupportMode

    init(_ name: String, mode: SupportMode) {
        self.name = name
        self.mode = mode
    }

    var body: some View {
        LabeledContent(name) {
            HStack(spacing: 4) {
                if mode.isSupported {
                    Text(mode.displayDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: mode.isSupported ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(mode.isSupported ? .green : .secondary)
            }
        }
    }
}

private struct DocumentationRow: View {
    enum DocType {
        case file(URL)
        case website(URL)

        var icon: String {
            switch self {
            case .file: return "doc.text"
            case .website: return "globe"
            }
        }

        var actionIcon: String {
            switch self {
            case .file: return "pencil"
            case .website: return "arrow.up.right.square"
            }
        }

        var actionTooltip: String {
            switch self {
            case .file: return "Open in Editor"
            case .website: return "Open in Browser"
            }
        }

        var url: URL {
            switch self {
            case .file(let url), .website(let url):
                return url
            }
        }
    }

    let label: String
    let type: DocType

    var body: some View {
        LabeledContent {
            HStack {
                Text(displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Button {
                    NSWorkspace.shared.open(type.url)
                } label: {
                    Image(systemName: type.actionIcon)
                }
                .buttonStyle(.borderless)
                .help(type.actionTooltip)
            }
        } label: {
            Label(label, systemImage: type.icon)
        }
    }

    private var displayText: String {
        switch type {
        case .file(let url):
            return url.path.replacingOccurrences(
                of: FileManager.default.homeDirectoryForCurrentUser.path,
                with: "~"
            )
        case .website(let url):
            return url.host ?? url.absoluteString
        }
    }
}
