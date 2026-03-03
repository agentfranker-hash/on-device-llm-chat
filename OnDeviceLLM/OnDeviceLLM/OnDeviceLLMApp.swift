import SwiftUI
import SwiftData

@main
struct OnDeviceLLMApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Conversation.self, ChatMessage.self])
    }
}
