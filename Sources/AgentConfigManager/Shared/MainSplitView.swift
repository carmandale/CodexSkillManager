import SwiftUI

struct MainSplitView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            contentView(for: appModel.selectedSection)
        } detail: {
            // Show agent detail if selected, otherwise show section detail
            if let agentID = appModel.selectedAgentForDetail,
               let config = AgentConfig.config(for: agentID) {
                AgentDetailView(agent: config)
            } else {
                detailView(for: appModel.selectedSection)
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

