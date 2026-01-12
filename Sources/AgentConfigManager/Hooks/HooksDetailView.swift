import SwiftUI

struct HooksDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "Select a Hook",
            systemImage: "arrow.triangle.branch",
            description: Text("Choose a hook from the list to view details")
        )
    }
}
