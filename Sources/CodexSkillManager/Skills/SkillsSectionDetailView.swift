import AppKit
import SwiftUI

struct SkillsSectionDetailView: View {
    @Environment(SkillStore.self) private var store
    @Environment(RemoteSkillStore.self) private var remoteStore

    @State private var downloadErrorMessage: String?
    @State private var showDownloadError = false
    @State private var isDownloadingRemote = false
    @State private var didDownloadRemote = false
    @State private var installSkill: RemoteSkill?
    @State private var installTargets: Set<SkillPlatform> = [.pi]

    private var canDownloadRemoteSkill: Bool {
        guard let skill = remoteStore.selectedSkill else { return false }
        let installedTargets = store.installedPlatforms(for: skill.slug)
        return installedTargets != Set(SkillPlatform.allCases)
    }

    private var installedPlatformsForSelected: Set<SkillPlatform> {
        guard store.selectedSource == .local, let slug = store.selectedSkill?.name else { return [] }
        return store.installedPlatforms(for: slug)
    }

    private var shouldShowOpenFolderMenu: Bool {
        installedPlatformsForSelected.count > 1
    }

    var body: some View {
        detailView
            .toolbar(id: "skills-detail-toolbar") {
                toolbarContent()
            }
            .sheet(item: $installSkill) { skill in
                RemoteInstallSheet(
                    skill: skill,
                    installedTargets: store.installedPlatforms(for: skill.slug),
                    selection: $installTargets,
                    isInstalling: $isDownloadingRemote,
                    didInstall: $didDownloadRemote,
                    errorMessage: $downloadErrorMessage
                )
                .environment(store)
                .environment(remoteStore)
            }
            .alert("Download failed", isPresented: $showDownloadError) {
                Button("OK", role: .cancel) {
                    downloadErrorMessage = nil
                }
            } message: {
                Text(downloadErrorMessage ?? "Unable to download this skill.")
            }
            .onChange(of: downloadErrorMessage) { _, newValue in
                if newValue != nil {
                    showDownloadError = true
                }
            }
    }

    @ViewBuilder
    private var detailView: some View {
        switch store.selectedSource {
        case .local:
            SkillDetailView()
        case .clawdhub:
            RemoteSkillDetailView()
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some CustomizableToolbarContent {
        if store.selectedSource == .clawdhub {
            ToolbarItem(id: "download") {
                Button {
                    presentRemoteInstallSheet()
                } label: {
                    downloadLabel
                }
                .labelStyle(.iconOnly)
                .disabled(isDownloadingRemote || !canDownloadRemoteSkill)
            }

            ToolbarSpacer(.fixed)
        }

        ToolbarItem(id: "open") {
            openFolderItem
        }
    }

    @ViewBuilder
    private var downloadLabel: some View {
        if isDownloadingRemote {
            ProgressView()
        } else if didDownloadRemote || (remoteStore.selectedSkill.map {
            store.installedPlatforms(for: $0.slug) == Set(SkillPlatform.allCases)
        } ?? false) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            Image(systemName: "arrow.down.circle")
        }
    }

    @ViewBuilder
    private var openFolderItem: some View {
        if shouldShowOpenFolderMenu {
            Menu {
                ForEach(SkillPlatform.allCases) { platform in
                    if installedPlatformsForSelected.contains(platform) {
                        Button("Open \(platform.rawValue) Folder") {
                            openSelectedSkillFolder(platform: platform)
                        }
                    }
                }
            } label: {
                Label("Open Skill Folder", systemImage: "folder")
            }
            .labelStyle(.iconOnly)
            .disabled(store.selectedSource != .local)
        } else {
            Button {
                openSelectedSkillFolder(platform: nil)
            } label: {
                Label("Open Skill Folder", systemImage: "folder")
            }
            .labelStyle(.iconOnly)
            .disabled(store.selectedSource != .local)
        }
    }

    private func openSelectedSkillFolder(platform: SkillPlatform?) {
        guard store.selectedSource == .local else { return }
        let fallbackURL = SkillPlatform.pi.rootURL
        let selected = store.selectedSkill
        let url: URL
        if let platform, let slug = selected?.name {
            if let selected, selected.platform == platform {
                url = selected.folderURL
            } else if let match = store.skills.first(where: {
                $0.name == slug && $0.platform == platform && $0.customPath == selected?.customPath
            }) {
                url = match.folderURL
            } else if let match = store.skills.first(where: { $0.name == slug && $0.platform == platform }) {
                url = match.folderURL
            } else {
                url = platform.rootURL.appendingPathComponent(slug)
            }
        } else {
            url = selected?.folderURL ?? fallbackURL
        }
        NSWorkspace.shared.open(url)
    }

    private func presentRemoteInstallSheet() {
        guard let skill = remoteStore.selectedSkill else { return }
        installTargets = defaultInstallTargets(for: skill.slug)
        installSkill = skill
    }

    private func defaultInstallTargets(for slug: String) -> Set<SkillPlatform> {
        let installed = store.installedPlatforms(for: slug)
        let missing = Set(SkillPlatform.allCases).subtracting(installed)
        return missing.isEmpty ? installed : missing
    }
}
