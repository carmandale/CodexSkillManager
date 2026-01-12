import SwiftUI

struct MainSplitView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        NavigationSplitView {
            SidebarView()
        } content: {
            contentView(for: appModel.selectedSection)
        } detail: {
            detailView(for: appModel.selectedSection)
        }
        .sheet(item: $appModel.selectedAgentForDetail) { agentID in
            if let config = AgentConfig.config(for: agentID) {
                NavigationStack {
                    AgentDetailView(agent: config)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    appModel.selectedAgentForDetail = nil
                                }
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func contentView(for section: NavigationSection) -> some View {
        switch section {
        case .skills:
            SkillsSectionContentView()
        case .extensions:
            ExtensionsContentView()
        case .plugins:
            PluginsContentView()
        case .hooks:
            HooksContentView()
        case .commands:
            CommandsContentView()
        case .agentsmd:
            AgentsMdContentView()
        case .repos:
            ReposContentView()
        }
    }

    @ViewBuilder
    private func detailView(for section: NavigationSection) -> some View {
        switch section {
        case .skills:
            SkillsSectionDetailView()
        case .extensions:
            ExtensionsDetailView()
        case .plugins:
            PluginsDetailView()
        case .hooks:
            HooksDetailView()
        case .commands:
            CommandsDetailView()
        case .agentsmd:
            AgentsMdDetailView()
        case .repos:
            ReposDetailView()
        }
    }
}

