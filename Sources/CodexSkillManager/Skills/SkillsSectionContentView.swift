import AppKit
import SwiftUI

struct SkillsSectionContentView: View {
    @Environment(SkillStore.self) private var store
    @Environment(RemoteSkillStore.self) private var remoteStore
    @Environment(CustomPathStore.self) private var customPathStore

    @State private var searchText = ""
    @State private var showingImport = false
    @State private var showingAddPath = false
    @State private var searchTask: Task<Void, Never>?

    private var filteredSkills: [Skill] {
        guard !searchText.isEmpty else { return store.skills }
        return store.skills.filter { skill in
            skill.displayName.localizedCaseInsensitiveContains(searchText)
                || skill.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var installedPlatforms: [String: Set<SkillPlatform>] {
        Dictionary(
            grouping: store.skills,
            by: { $0.name }
        ).mapValues { Set($0.compactMap(\.platform)) }
    }

    var body: some View {
        @Bindable var store = store
        @Bindable var remoteStore = remoteStore
        SkillListView(
            localSkills: filteredSkills,
            remoteLatestSkills: remoteStore.latestSkills,
            remoteSearchResults: remoteStore.searchResults,
            remoteSearchState: remoteStore.searchState,
            remoteLatestState: remoteStore.latestState,
            remoteQuery: searchText,
            installedPlatforms: installedPlatforms,
            source: $store.selectedSource,
            localSelection: $store.selectedSkillID,
            remoteSelection: $remoteStore.selectedSkillID
        )
        .searchable(
            text: $searchText,
            placement: .sidebar,
            prompt: store.selectedSource == .local ? "Filter skills" : "Search Clawdhub"
        )
        .toolbar(id: "skills-content-toolbar") {
            toolbarContent()
        }
        .sheet(isPresented: $showingImport) {
            ImportSkillView()
                .environment(store)
        }
        .sheet(isPresented: $showingAddPath) {
            AddCustomPathView()
                .environment(store)
        }
        .modifier(
            SkillsSectionContentLifecycleModifier(
                searchText: $searchText,
                searchTask: $searchTask
            )
        )
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some CustomizableToolbarContent {
        ToolbarItem(id: "add") {
            Menu {
                Button("Import Skill...") {
                    showingImport = true
                }
                Button("Add Custom Path...") {
                    showingAddPath = true
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
            .labelStyle(.iconOnly)
        }
    }
}

private struct SkillsSectionContentLifecycleModifier: ViewModifier {
    @Environment(SkillStore.self) private var store
    @Environment(RemoteSkillStore.self) private var remoteStore

    @Binding var searchText: String
    @Binding var searchTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .task {
                await store.loadSkills()
                await remoteStore.loadLatest()
            }
            .onChange(of: store.selectedSkillID) { _, _ in
                Task { await store.loadSelectedSkill() }
            }
            .onChange(of: remoteStore.selectedSkillID) { _, _ in
                Task { await remoteStore.loadSelectedSkill() }
            }
            .onChange(of: store.selectedSource) { _, newValue in
                if newValue == .local {
                    Task { await store.loadSelectedSkill() }
                    searchTask?.cancel()
                    searchTask = nil
                }
            }
            .onChange(of: searchText) { _, newValue in
                guard store.selectedSource == .clawdhub else { return }
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    await remoteStore.search(query: newValue)
                }
            }
    }
}
