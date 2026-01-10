import SwiftUI

struct PlaceholderDetailView: View {
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
