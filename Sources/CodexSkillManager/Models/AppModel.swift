import Foundation
import Observation

@Observable
@MainActor
final class AppModel {
    var selectedSection: NavigationSection = .skills
    var selectedAgents: Set<AgentID> = []

    let settings: SettingsStore
    let skillStore: SkillStore
    let remoteSkillStore: RemoteSkillStore
    let extensionStore: ExtensionStore

    init(
        settings: SettingsStore,
        skillStore: SkillStore,
        remoteSkillStore: RemoteSkillStore,
        extensionStore: ExtensionStore
    ) {
        self.settings = settings
        self.skillStore = skillStore
        self.remoteSkillStore = remoteSkillStore
        self.extensionStore = extensionStore
        self.selectedAgents = settings.selectedAgents
    }

    func persistAgentSelection() {
        settings.selectedAgents = selectedAgents
        settings.save()
    }
}
