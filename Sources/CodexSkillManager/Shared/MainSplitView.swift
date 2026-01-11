import SwiftUI

struct MainSplitView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            contentView(for: appModel.selectedSection)
        } detail: {
            detailView(for: appModel.selectedSection)
        }
    }

    @ViewBuilder
    private func contentView(for section: NavigationSection) -> some View {
        switch section {
        case .skills:
            SkillsSectionContentView()
        case .extensions:
            ExtensionsContentView()
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
        case .commands:
            CommandsDetailView()
        case .agentsmd:
            AgentsMdDetailView()
        case .repos:
            ReposDetailView()
        }
    }
}
