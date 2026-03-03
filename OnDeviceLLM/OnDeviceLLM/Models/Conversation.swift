import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var systemPrompt: String
    var modelId: String
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage]

    init(
        title: String = "New Chat",
        systemPrompt: String = AppDefaults.systemPrompt,
        modelId: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.systemPrompt = systemPrompt
        self.modelId = modelId
        self.messages = []
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
}

@Model
final class ChatMessage {
    var id: UUID
    var role: String // "user", "assistant", "system"
    var content: String
    var timestamp: Date
    var tokensPerSecond: Double?
    var conversation: Conversation?

    init(role: String, content: String, tokensPerSecond: Double? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.tokensPerSecond = tokensPerSecond
    }
}
