import Foundation
import Observation

@Observable
@MainActor
final class AppModel {
    var selectedSection: NavigationSection = .skills
    var selectedAgents: Set<AgentID> = []

    // Wizard presentation states
    var showMigrationWizard = false
    var showSymlinkWizard = false

    let settings: SettingsStore
    let skillStore: SkillStore
    let remoteSkillStore: RemoteSkillStore
    let extensionStore: ExtensionStore
    let commandStore: CommandStore
    let agentsMdStore: AgentsMdStore
    let repoStore: RepoStore

    // Migration worker for checking migration needs
    let migrationWorker: MigrationWorker

    init(
        settings: SettingsStore,
        skillStore: SkillStore,
        remoteSkillStore: RemoteSkillStore,
        extensionStore: ExtensionStore,
        commandStore: CommandStore,
        agentsMdStore: AgentsMdStore,
        repoStore: RepoStore
    ) {
        self.settings = settings
        self.skillStore = skillStore
        self.remoteSkillStore = remoteSkillStore
        self.extensionStore = extensionStore
        self.commandStore = commandStore
        self.agentsMdStore = agentsMdStore
        self.repoStore = repoStore
        self.selectedAgents = settings.selectedAgents

        // Initialize migration worker with paths resolved at @MainActor context
        self.migrationWorker = MigrationWorker(
            legacyRootURL: AgentConfigPaths.legacyOpencodeConfigURL,
            legacyAgentsMarkdownURL: AgentConfigPaths.legacyOpencodeAgentsMarkdownURL,
            legacyCommandsURL: AgentConfigPaths.legacyOpencodeCommandsURL,
            legacyKnowledgeURL: AgentConfigPaths.legacyOpencodeKnowledgeURL,
            centralRootURL: AgentConfigPaths.centralRootURL,
            centralAgentsMarkdownURL: AgentConfigPaths.centralAgentsMarkdownURL,
            centralCommandsURL: AgentConfigPaths.centralCommandsURL,
            centralKnowledgeURL: AgentConfigPaths.centralKnowledgeURL,
            homePath: FileManager.default.homeDirectoryForCurrentUser.path
        )
    }

    func persistAgentSelection() {
        settings.selectedAgents = selectedAgents
        settings.save()
    }

    /// Check if migration is needed and show wizard if so
    func checkMigrationOnStartup() async {
        let needsMigration = await migrationWorker.checkMigrationNeeded()
        if needsMigration {
            showMigrationWizard = true
        }
    }

    /// Called when migration wizard completes - prompt for symlink setup
    func onMigrationComplete() {
        showMigrationWizard = false
        // Offer symlink wizard after migration
        showSymlinkWizard = true
    }
}
