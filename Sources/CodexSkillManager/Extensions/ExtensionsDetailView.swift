import AppKit
import SwiftUI

struct ExtensionsDetailView: View {
    @Environment(ExtensionStore.self) private var store

    var body: some View {
        Group {
            if let ext = store.selectedExtension {
                extensionDetail(ext)
            } else {
                ContentUnavailableView(
                    "No Extension Selected",
                    systemImage: "puzzlepiece.extension",
                    description: Text("Select an extension to view its details.")
                )
            }
        }
        .toolbar(id: "extensions-detail-toolbar") {
            toolbarContent()
        }
    }

    private func extensionDetail(_ ext: Extension) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(for: ext)
                .padding()

            Divider()

            switch store.detailState {
            case .idle:
                Spacer()
            case .loading:
                ProgressView("Loading source...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                CodeView(source: store.selectedSource)
            case .failed(let message):
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
    }

    private func header(for ext: Extension) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ext.name)
                .font(.title2)
                .fontWeight(.semibold)

            if let entryPoint = ext.entryPoint {
                Text("Entry point: \(entryPoint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if !ext.providedTools.isEmpty {
                    Label("\(ext.providedTools.count) tool\(ext.providedTools.count == 1 ? "" : "s")", systemImage: "wrench")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !ext.providedCommands.isEmpty {
                    Label("\(ext.providedCommands.count) command\(ext.providedCommands.count == 1 ? "" : "s")", systemImage: "terminal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !ext.providedTools.isEmpty {
                toolsSection(ext.providedTools)
            }

            if !ext.providedCommands.isEmpty {
                commandsSection(ext.providedCommands)
            }
        }
    }

    private func toolsSection(_ tools: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tools")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 4) {
                ForEach(tools, id: \.self) { tool in
                    Text(tool)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .cornerRadius(4)
                }
            }
        }
    }

    private func commandsSection(_ commands: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Commands")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 4) {
                ForEach(commands, id: \.self) { command in
                    Text(command)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .cornerRadius(4)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some CustomizableToolbarContent {
        ToolbarItem(id: "refresh") {
            Button {
                Task { await store.load() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
        }

        ToolbarItem(id: "open-finder") {
            Button {
                store.openInFinder()
            } label: {
                Label("Open in Finder", systemImage: "folder")
            }
            .labelStyle(.iconOnly)
            .disabled(store.selectedExtension == nil)
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, containerWidth: bounds.width).offsets

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + offsets[index].x, y: bounds.minY + offsets[index].y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (offsets, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}
