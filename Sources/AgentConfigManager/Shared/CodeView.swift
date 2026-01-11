import SwiftUI

struct CodeView: View {
    let source: String

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(source)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    CodeView(source: """
    import { tool } from "@pi/sdk";

    export const myTool = tool("example", {
        description: "An example tool",
        execute: async () => {
            return "Hello, world!";
        }
    });
    """)
    .frame(width: 500, height: 300)
}
