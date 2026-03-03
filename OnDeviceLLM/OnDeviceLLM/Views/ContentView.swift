import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }

            ModelPickerView()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.cyan)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
