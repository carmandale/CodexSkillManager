import SwiftUI

struct SidebarView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(AgentStatusStore.self) private var agentStatus

    var body: some View {
        @Bindable var appModel = appModel

        List(selection: $appModel.selectedSection) {
            Section("Sections") {
                ForEach(NavigationSection.allCases) { section in
                    Label(section.name, systemImage: section.symbolName)
                        .tag(section)
                }
            }

            Section("Installed Agents") {
                ForEach(agentStatus.statuses) { status in
                    Button {
                        appModel.selectedAgentForDetail = status.agent.id
                    } label: {
                        AgentStatusRow(status: status)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .task {
            await agentStatus.load()
        }
    }
}

private struct AgentStatusRow: View {
    let status: AgentInstallStatus

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.agent.badgeColor)
                .frame(width: 8, height: 8)

            Text(status.agent.displayName)

            Spacer()

            Image(systemName: status.statusIcon)
                .foregroundStyle(status.statusColor)
                .font(.caption)
        }
    }
}
