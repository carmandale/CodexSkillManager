import SwiftUI

struct ReposContentView: View {
    @Environment(RepoStore.self) private var store

    @State private var searchText = ""

    private var filteredRepos: [Repo] {
        guard !searchText.isEmpty else { return store.repos }
        return store.repos.filter { repo in
            repo.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedRepos: [RepoStatus: [Repo]] {
        Dictionary(grouping: filteredRepos, by: { $0.status })
    }

    var body: some View {
        @Bindable var store = store

        Group {
            switch store.listState {
            case .idle:
                ContentUnavailableView(
                    "Loading...",
                    systemImage: "folder"
                )
            case .loading:
                ProgressView("Scanning repositories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                if store.repos.isEmpty {
                    ContentUnavailableView(
                        "No Repositories Found",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Configure watched directories in Settings.")
                    )
                } else {
                    List(selection: $store.selectedRepoID) {
                        ForEach(RepoStatus.allCases) { status in
                            if let repos = groupedRepos[status], !repos.isEmpty {
                                Section(header: sectionHeader(for: status, count: repos.count)) {
                                    ForEach(repos) { repo in
                                        RepoRowView(repo: repo)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .searchable(
                        text: $searchText,
                        placement: .sidebar,
                        prompt: "Filter repositories"
                    )
                }
            case .failed(let message):
                ContentUnavailableView(
                    "Failed to Scan",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .task {
            await store.load()
        }
        .onChange(of: store.selectedRepoID) { _, _ in
            Task { await store.loadSelectedRepo() }
        }
    }

    private func sectionHeader(for status: RepoStatus, count: Int) -> some View {
        HStack {
            Image(systemName: status.symbolName)
            Text("\(status.displayName) (\(count))")
        }
    }
}

private struct RepoRowView: View {
    let repo: Repo

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(repo.name)
                    .fontWeight(.medium)

                if repo.hasAgentsMd {
                    Text("AGENTS.md (\(repo.fileSizeFormatted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: repo.status.symbolName)
                .foregroundStyle(statusColor(for: repo.status))
        }
        .tag(repo.id)
    }

    private func statusColor(for status: RepoStatus) -> Color {
        switch status {
        case .bloated: return .orange
        case .minimal: return .green
        case .noAgentsMd: return .secondary
        }
    }
}
