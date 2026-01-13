import Security
import SwiftUI

#if canImport(Sparkle) && ENABLE_SPARKLE
import Sparkle
#endif

@main
struct AgentConfigManagerApp: App {
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var customPathStore: CustomPathStore
    @State private var store: SkillStore
    @State private var remoteStore = RemoteSkillStore(client: .live())
    @State private var extensionStore = ExtensionStore()
    @State private var commandStore = CommandStore()
    @State private var agentsMdStore = AgentsMdStore()
    @State private var hookStore = HookStore()
    @State private var pluginStore = PluginStore()
    @State private var settings = SettingsStore()
    @State private var repoStore: RepoStore?
    @State private var appModel: AppModel?
    @State private var agentStatusStore = AgentStatusStore()

    init() {
        let pathStore = CustomPathStore()
        _customPathStore = State(initialValue: pathStore)
        _store = State(initialValue: SkillStore(customPathStore: pathStore))
    }

    var body: some Scene {
        WindowGroup("Agent Config Manager") {
            Group {
                if let appModel {
                    MainSplitView()
                        .environment(appModel)
                        .environment(appModel.skillStore)
                        .environment(appModel.remoteSkillStore)
                        .environment(appModel.extensionStore)
                        .environment(appModel.commandStore)
                        .environment(appModel.agentsMdStore)
                        .environment(appModel.repoStore)
                        .environment(appModel.settings)
                        .environment(customPathStore)
                        .environment(agentStatusStore)
                        .environment(hookStore)
                        .environment(pluginStore)
                        .sheet(isPresented: Binding(
                            get: { appModel.showMigrationWizard },
                            set: { appModel.showMigrationWizard = $0 }
                        )) {
                            MigrationWizardView(onComplete: appModel.onMigrationComplete)
                        }
                        .sheet(isPresented: Binding(
                            get: { appModel.showSymlinkWizard },
                            set: { appModel.showSymlinkWizard = $0 }
                        )) {
                            SymlinkWizardView()
                                .environment(appModel.agentsMdStore)
                        }
                        .task {
                            await appModel.checkMigrationOnStartup()
                        }
                } else {
                    ProgressView("Loading...")
                        .onAppear {
                            settings.load()
                            let repo = RepoStore(settings: settings)
                            repoStore = repo
                            appModel = AppModel(
                                settings: settings,
                                skillStore: store,
                                remoteSkillStore: remoteStore,
                                extensionStore: extensionStore,
                                commandStore: commandStore,
                                agentsMdStore: agentsMdStore,
                                repoStore: repo
                            )
                        }
                }
            }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Agent Config Manager") {
                    openWindow(id: "about")
                }
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    appDelegate.checkForUpdates()
                }
                .keyboardShortcut("u", modifiers: [.command, .option])
            }
        }
        Window("About Agent Config Manager", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
#if canImport(Sparkle) && ENABLE_SPARKLE
    private var updaterController: SPUStandardUpdaterController?
#endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app becomes key when launched from `swift run`.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

#if canImport(Sparkle) && ENABLE_SPARKLE
        guard shouldEnableSparkle() else { return }
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
#endif
    }

    func checkForUpdates() {
#if canImport(Sparkle) && ENABLE_SPARKLE
        updaterController?.checkForUpdates(nil)
#endif
    }

#if canImport(Sparkle) && ENABLE_SPARKLE
    private func shouldEnableSparkle() -> Bool {
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.pathExtension == "app" else { return false }
        guard isDeveloperIDSigned(bundleURL: bundleURL) else { return false }
        let info = Bundle.main.infoDictionary
        let feedURL = info?["SUFeedURL"] as? String
        let publicKey = info?["SUPublicEDKey"] as? String
        return (feedURL?.isEmpty == false) && (publicKey?.isEmpty == false)
    }

    private func isDeveloperIDSigned(bundleURL: URL) -> Bool {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(bundleURL as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
              let code = staticCode else { return false }

        var infoCF: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &infoCF) == errSecSuccess,
              let info = infoCF as? [String: Any],
              let certs = info[kSecCodeInfoCertificates as String] as? [SecCertificate],
              let leaf = certs.first else { return false }

        if let summary = SecCertificateCopySubjectSummary(leaf) as String? {
            return summary.hasPrefix("Developer ID Application:")
        }
        return false
    }
#endif
}
