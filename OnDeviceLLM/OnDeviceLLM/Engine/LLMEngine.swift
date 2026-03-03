import Foundation
import os

/// Core LLM inference engine wrapping llama.cpp via C API.
/// For the POC, this uses a protocol-based approach so we can build and test
/// the UI layer independently of the llama.cpp C integration.
/// The actual C bridge requires the llama.cpp SPM package to be resolved in Xcode.
@Observable
final class LLMEngine {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case generating
        case error(String)
    }

    var state: State = .idle
    var currentModelId: String?
    var isGenerating: Bool { state == .generating }

    private let logger = Logger(subsystem: "com.ondevicellm", category: "LLMEngine")
    private let performanceMonitor: PerformanceMonitor

    // llama.cpp opaque pointers — typed as OpaquePointer for now
    // These will be replaced with proper llama_model*/llama_context* when the C bridge is active
    private var model: OpaquePointer?
    private var context: OpaquePointer?

    // Generation settings
    var temperature: Float = AppDefaults.temperature
    var topP: Float = AppDefaults.topP
    var topK: Int32 = AppDefaults.topK
    var maxContextLength: Int32 = AppDefaults.maxContextLength
    var repeatPenalty: Float = AppDefaults.repeatPenalty

    init(performanceMonitor: PerformanceMonitor) {
        self.performanceMonitor = performanceMonitor
    }

    deinit {
        unloadModel()
    }

    // MARK: - Model Loading

    func loadModel(at path: URL, modelId: String) async throws {
        guard FileManager.default.fileExists(atPath: path.path) else {
            state = .error("Model file not found")
            throw LLMError.modelNotFound
        }

        state = .loading
        logger.info("Loading model from: \(path.lastPathComponent)")

        // TODO: Replace with actual llama.cpp calls when SPM package is integrated in Xcode
        // The C API calls would be:
        //
        // var modelParams = llama_model_default_params()
        // modelParams.n_gpu_layers = 99  // Use Metal for all layers
        // let model = llama_model_load_from_file(path.path, modelParams)
        //
        // var ctxParams = llama_context_default_params()
        // ctxParams.n_ctx = UInt32(maxContextLength)
        // ctxParams.n_batch = 512
        // ctxParams.n_threads = UInt32(max(1, ProcessInfo.processInfo.activeProcessorCount - 2))
        // let context = llama_init_from_model(model, ctxParams)

        // Simulate load time for UI testing
        try await Task.sleep(for: .milliseconds(500))

        currentModelId = modelId
        state = .ready
        logger.info("Model loaded: \(modelId)")
    }

    func unloadModel() {
        // TODO: llama_free(context); llama_model_free(model)
        model = nil
        context = nil
        currentModelId = nil
        state = .idle
        logger.info("Model unloaded")
    }

    // MARK: - Text Generation

    /// Generate a response as an AsyncStream of token strings
    func generate(messages: [ChatMessage], systemPrompt: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                await performGeneration(messages: messages, systemPrompt: systemPrompt, continuation: continuation)
            }
        }
    }

    private func performGeneration(
        messages: [ChatMessage],
        systemPrompt: String,
        continuation: AsyncStream<String>.Continuation
    ) async {
        guard state == .ready else {
            continuation.finish()
            return
        }

        state = .generating
        performanceMonitor.startGeneration()

        // Format conversation using Qwen chat template
        let prompt = formatQwenPrompt(messages: messages, systemPrompt: systemPrompt)
        logger.info("Prompt length: \(prompt.count) chars")

        // TODO: Replace with actual llama.cpp inference loop:
        //
        // 1. Tokenize the prompt:
        //    let tokens = llama_tokenize(model, prompt, ...)
        //
        // 2. Evaluate tokens in batches:
        //    var batch = llama_batch_init(512, 0, 1)
        //    for token in tokens { llama_batch_add(&batch, token, pos, ...) }
        //    llama_decode(context, batch)
        //
        // 3. Sample and stream tokens:
        //    while !done {
        //        let logits = llama_get_logits_ith(context, -1)
        //        // Apply temperature, top-p, top-k sampling
        //        let newToken = sample(logits)
        //        let tokenStr = llama_token_to_piece(model, newToken)
        //        continuation.yield(tokenStr)
        //        performanceMonitor.recordToken()
        //        // Check for EOS
        //        if newToken == llama_token_eos(model) { break }
        //    }

        // Placeholder: simulate streaming response for UI development
        let placeholder = "I'm running on-device! Once the llama.cpp C bridge is connected via Xcode's SPM integration, I'll generate real responses using the Qwen 3.5 model with Metal acceleration. This placeholder lets you verify the streaming UI works correctly."

        for word in placeholder.split(separator: " ") {
            guard !Task.isCancelled else { break }
            continuation.yield(String(word) + " ")
            performanceMonitor.recordToken()
            try? await Task.sleep(for: .milliseconds(50))
        }

        performanceMonitor.stopGeneration()
        state = .ready
        continuation.finish()
    }

    // MARK: - Qwen Chat Template Formatting

    private func formatQwenPrompt(messages: [ChatMessage], systemPrompt: String) -> String {
        var prompt = "<|im_start|>system\n\(systemPrompt)<|im_end|>\n"

        for message in messages {
            let role = message.role
            prompt += "<|im_start|>\(role)\n\(message.content)<|im_end|>\n"
        }

        prompt += "<|im_start|>assistant\n"
        return prompt
    }

    // MARK: - Memory Pressure

    func handleMemoryPressure() {
        logger.warning("Memory pressure detected — unloading model")
        unloadModel()
        state = .error("Model unloaded due to memory pressure. Please reload.")
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case modelNotFound
    case loadFailed(String)
    case contextCreationFailed
    case generationFailed(String)
    case outOfMemory

    var errorDescription: String? {
        switch self {
        case .modelNotFound: return "Model file not found on disk"
        case .loadFailed(let msg): return "Failed to load model: \(msg)"
        case .contextCreationFailed: return "Failed to create inference context"
        case .generationFailed(let msg): return "Generation failed: \(msg)"
        case .outOfMemory: return "Out of memory — try a smaller model"
        }
    }
}
