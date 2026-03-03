import Foundation

enum AppDefaults {
    static let systemPrompt = "You are a helpful AI assistant running entirely on this device. Be concise and helpful."
    static let temperature: Float = 0.7
    static let topP: Float = 0.9
    static let topK: Int32 = 40
    static let maxContextLength: Int32 = 4096
    static let repeatPenalty: Float = 1.1
}
