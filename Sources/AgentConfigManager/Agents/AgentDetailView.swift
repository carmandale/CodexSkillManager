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

            Section("Skill Documentation") {
                LabeledContent("Filename") {
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
