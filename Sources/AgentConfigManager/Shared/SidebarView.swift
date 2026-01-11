import SwiftUI

struct SidebarView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        List {
            Section("Sections") {
                ForEach(NavigationSection.allCases) { section in
                    Label(section.name, systemImage: section.symbolName)
                        .tag(section)
                        .onTapGesture {
                            appModel.selectedSection = section
                        }
                        .listRowBackground(
                            appModel.selectedSection == section
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                }
            }

            Section("Agents") {
                AgentToggleRow(
                    label: "All Agents",
                    isOn: appModel.selectedAgents.isEmpty,
                    onToggle: {
                        appModel.selectedAgents = []
                        appModel.persistAgentSelection()
                    }
                )

                ForEach(AgentConfig.all) { config in
                    AgentToggleRow(
                        label: config.displayName,
                        badgeColor: config.badgeColor,
                        isOn: appModel.selectedAgents.contains(config.id),
                        onToggle: {
                            if appModel.selectedAgents.contains(config.id) {
                                appModel.selectedAgents.remove(config.id)
                            } else {
                                appModel.selectedAgents.insert(config.id)
                            }
                            appModel.persistAgentSelection()
                        }
                    )
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct AgentToggleRow: View {
    let label: String
    var badgeColor: Color? = nil
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                if let badgeColor {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 8, height: 8)
                }
                Text(label)
                Spacer()
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
