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
                Toggle("All Agents", isOn: allAgentsBinding(model: model))
                    .toggleStyle(.checkbox)

                ForEach(AgentConfig.all) { config in
                    Toggle(isOn: agentBinding(for: config.id, model: model)) {
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

    private func allAgentsBinding(model: AppModel) -> Binding<Bool> {
        Binding(
            get: { model.selectedAgents.isEmpty },
            set: { isAllSelected in
                if isAllSelected {
                    model.selectedAgents = []
                    model.persistAgentSelection()
                }
            }
        )
    }

    private func agentBinding(for agentID: AgentID, model: AppModel) -> Binding<Bool> {
        Binding(
            get: { model.selectedAgents.contains(agentID) },
            set: { isSelected in
                if isSelected {
                    model.selectedAgents.insert(agentID)
                } else {
                    model.selectedAgents.remove(agentID)
                }
                model.persistAgentSelection()
            }
        )
    }
}
