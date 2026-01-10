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

    init(
        settings: SettingsStore,
        skillStore: SkillStore,
        remoteSkillStore: RemoteSkillStore
    ) {
        self.settings = settings
        self.skillStore = skillStore
        self.remoteSkillStore = remoteSkillStore
        self.selectedAgents = settings.selectedAgents
    }

    func persistAgentSelection() {
        settings.selectedAgents = selectedAgents
        settings.save()
    }
}
