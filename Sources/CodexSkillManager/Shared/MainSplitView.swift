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
            PlaceholderContentView(title: section.name)
        case .agentsmd:
            PlaceholderContentView(title: section.name)
        case .repos:
            PlaceholderContentView(title: section.name)
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
            PlaceholderDetailView(title: section.name)
        case .agentsmd:
            PlaceholderDetailView(title: section.name)
        case .repos:
            PlaceholderDetailView(title: section.name)
        }
    }
}
