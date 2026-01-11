import SwiftUI

struct SkillSplitLifecycleModifier: ViewModifier {
    @Environment(SkillStore.self) private var store
    @Environment(RemoteSkillStore.self) private var remoteStore

    @Binding var source: SkillSource
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
            .onChange(of: source) { _, newValue in
                if newValue == .local {
                    Task { await store.loadSelectedSkill() }
                    searchTask?.cancel()
                    searchTask = nil
                }
            }
            .onChange(of: searchText) { _, newValue in
                guard source == .clawdhub else { return }
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    await remoteStore.search(query: newValue)
                }
            }
    }
}
