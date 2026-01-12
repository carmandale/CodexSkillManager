import SwiftUI

struct PluginsDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "Select a Plugin",
            systemImage: "powerplug",
            description: Text("Choose a plugin from the list to view details")
        )
    }
}
