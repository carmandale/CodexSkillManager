import SwiftUI

struct SidebarView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var model = appModel
        List {
            Section("Sections") {
                ForEach(NavigationSection.allCases) { section in
                    Label(section.name, systemImage: section.symbolName)
                        .tag(section)
                        .onTapGesture {
                            model.selectedSection = section
                        }
                        .listRowBackground(
                            model.selectedSection == section
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                }
            }

            Section("Agents") {
                Toggle("All Agents", isOn: allAgentsBinding)
                    .toggleStyle(.checkbox)

                ForEach(AgentConfig.all) { config in
                    Toggle(isOn: agentBinding(for: config.id)) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(config.badgeColor)
                                .frame(width: 8, height: 8)
                            Text(config.displayName)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var allAgentsBinding: Binding<Bool> {
        Binding(
            get: { appModel.selectedAgents.isEmpty },
            set: { isAllSelected in
                if isAllSelected {
                    appModel.selectedAgents = []
                    appModel.persistAgentSelection()
                }
            }
        )
    }

    private func agentBinding(for agentID: AgentID) -> Binding<Bool> {
        Binding(
            get: { appModel.selectedAgents.contains(agentID) },
            set: { isSelected in
                if isSelected {
                    appModel.selectedAgents.insert(agentID)
                } else {
                    appModel.selectedAgents.remove(agentID)
                }
                appModel.persistAgentSelection()
            }
        )
    }
}
