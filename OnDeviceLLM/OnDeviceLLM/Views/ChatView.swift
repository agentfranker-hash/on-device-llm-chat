import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine = LLMEngine(performanceMonitor: PerformanceMonitor())
    @State private var modelManager = ModelManager.shared
    @State private var performanceMonitor = PerformanceMonitor()
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = []
    @State private var streamingText = ""
    @State private var showStats = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Performance bar
                if showStats {
                    StatsBar(monitor: performanceMonitor, engine: engine)
                }

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                            if !streamingText.isEmpty {
                                ChatBubble(message: ChatMessage(role: "assistant", content: streamingText))
                                    .id("streaming")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: streamingText) {
                        withAnimation {
                            proxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }

                Divider()
                    .background(Color.cyan.opacity(0.3))

                // Input bar
                HStack(spacing: 12) {
                    TextField("Message...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .lineLimit(1...5)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || engine.isGenerating
                                    ? Color.gray
                                    : Color.cyan
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || engine.isGenerating)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3))
            }
            .navigationTitle("NeonChat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    modelStatusBadge
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showStats.toggle()
                        } label: {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(showStats ? .cyan : .gray)
                        }
                        Button {
                            clearChat()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
        }
        .onAppear {
            performanceMonitor.startMonitoring()
            autoLoadModel()
        }
        .onDisappear {
            performanceMonitor.stopMonitoring()
        }
    }

    // MARK: - Model Status Badge

    @ViewBuilder
    private var modelStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(engine.state == .ready ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(engine.currentModelId ?? "No model")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func autoLoadModel() {
        // Auto-load the first downloaded model
        guard engine.state == .idle else { return }
        if let firstDownloaded = LLMModelInfo.availableModels.first(where: { modelManager.isDownloaded($0) }) {
            Task {
                try? await engine.loadModel(
                    at: modelManager.modelPath(for: firstDownloaded),
                    modelId: firstDownloaded.id
                )
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        messages.append(userMessage)
        inputText = ""
        streamingText = ""

        Task {
            let stream = engine.generate(messages: messages, systemPrompt: AppDefaults.systemPrompt)
            for await token in stream {
                streamingText += token
            }
            // Finalize the assistant message
            let assistantMessage = ChatMessage(
                role: "assistant",
                content: streamingText,
                tokensPerSecond: performanceMonitor.tokensPerSecond
            )
            messages.append(assistantMessage)
            streamingText = ""
        }
    }

    private func clearChat() {
        messages.removeAll()
        streamingText = ""
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                            ? Color.cyan.opacity(0.25)
                            : Color.white.opacity(0.08)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isUser ? Color.cyan.opacity(0.4) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )

                if let tps = message.tokensPerSecond, tps > 0 {
                    Text(String(format: "%.1f tok/s", tps))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Stats Bar

struct StatsBar: View {
    let monitor: PerformanceMonitor
    let engine: LLMEngine

    var body: some View {
        HStack(spacing: 16) {
            StatItem(label: "tok/s", value: String(format: "%.1f", monitor.tokensPerSecond))
            StatItem(label: "Memory", value: String(format: "%.0f MB", monitor.availableMemoryMB))
            StatItem(label: "Thermal", value: monitor.thermalStateString)
            if monitor.contextMax > 0 {
                StatItem(label: "Context", value: "\(monitor.contextUsed)/\(monitor.contextMax)")
            }
        }
        .font(.caption2)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.cyan.opacity(0.2)),
            alignment: .bottom
        )
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .foregroundStyle(.cyan)
                .fontDesign(.monospaced)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ChatView()
}
