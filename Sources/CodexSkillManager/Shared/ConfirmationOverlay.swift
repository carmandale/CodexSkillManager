import SwiftUI

/// Reusable overlay for confirming destructive or automatic actions
struct ConfirmationOverlay<Content: View>: View {
    let title: String
    let message: String
    let actions: [String]
    let confirmTitle: String
    let isDestructive: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder let additionalContent: () -> Content

    init(
        title: String,
        message: String,
        actions: [String] = [],
        confirmTitle: String = "Confirm",
        isDestructive: Bool = false,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void,
        @ViewBuilder additionalContent: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self.confirmTitle = confirmTitle
        self.isDestructive = isDestructive
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        self.additionalContent = additionalContent
    }

    var body: some View {
        ZStack {
            // Darkened background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Centered dialog box
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(title)
                    .font(.headline)

                // Message
                Text(message)
                    .foregroundStyle(.secondary)

                // Action items as bullet list
                if !actions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(actions, id: \.self) { action in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(action)
                                    .textSelection(.enabled)
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                additionalContent()

                Divider()

                // Buttons
                HStack {
                    Spacer()

                    Button("Cancel", action: onCancel)
                        .keyboardShortcut(.escape, modifiers: [])

                    Button(confirmTitle, action: onConfirm)
                        .keyboardShortcut(.return, modifiers: [])
                        .buttonStyle(.borderedProminent)
                        .tint(isDestructive ? .red : .accentColor)
                }
            }
            .padding(24)
            .frame(maxWidth: 480)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 20)
        }
    }
}

/// Simple confirmation overlay without additional content
extension ConfirmationOverlay where Content == EmptyView {
    init(
        title: String,
        message: String,
        actions: [String] = [],
        confirmTitle: String = "Confirm",
        isDestructive: Bool = false,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self.confirmTitle = confirmTitle
        self.isDestructive = isDestructive
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        self.additionalContent = { EmptyView() }
    }
}

#Preview {
    ConfirmationOverlay(
        title: "Setup Symlinks",
        message: "The following symlinks will be created:",
        actions: [
            "~/.claude/AGENTS.md → ~/.agent-config/AGENTS.md",
            "~/.codex/AGENTS.md → ~/.agent-config/AGENTS.md"
        ],
        confirmTitle: "Create Symlinks",
        onCancel: {},
        onConfirm: {}
    )
}
