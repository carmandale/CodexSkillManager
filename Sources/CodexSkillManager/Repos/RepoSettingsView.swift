import SwiftUI
import UniformTypeIdentifiers

struct RepoSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    @Environment(RepoStore.self) private var repoStore

    @State private var showingDirectoryPicker = false

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 16) {
            Text("Watched Directories")
                .font(.headline)

            Text("The app will scan these directories for git repositories with AGENTS.md files.")
                .font(.caption)
                .foregroundStyle(.secondary)

            List {
                ForEach(settings.watchedDirectories, id: \.self) { directory in
                    HStack {
                        Image(systemName: "folder")
                        Text(directory.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                }
                .onDelete(perform: deleteDirectories)
            }
            .frame(minHeight: 150)

            HStack {
                Button("Add Directory...") {
                    showingDirectoryPicker = true
                }

                Spacer()

                Button("Done") {
                    settings.save()
                    dismiss()
                    Task {
                        await repoStore.load()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 250)
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                if !settings.watchedDirectories.contains(url) {
                    settings.watchedDirectories.append(url)
                }
            }
        }
    }

    private func deleteDirectories(at offsets: IndexSet) {
        settings.watchedDirectories.remove(atOffsets: offsets)
    }
}
