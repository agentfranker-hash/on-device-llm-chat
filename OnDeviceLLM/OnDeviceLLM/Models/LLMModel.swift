import Foundation

struct LLMModelInfo: Identifiable, Codable {
    let id: String
    let name: String
    let displayName: String
    let parameters: String
    let quantization: String
    let sizeBytes: Int64
    let ramRequired: String
    let expectedToksPerSec: String
    let huggingFaceRepo: String
    let huggingFaceFile: String

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/\(huggingFaceRepo)/resolve/main/\(huggingFaceFile)")!
    }
}

extension LLMModelInfo {
    static let availableModels: [LLMModelInfo] = [
        LLMModelInfo(
            id: "qwen3.5-0.8b-q8",
            name: "Qwen3.5-0.8B",
            displayName: "Qwen 3.5 0.8B (Q8_0)",
            parameters: "0.8B",
            quantization: "Q8_0",
            sizeBytes: 900_000_000,
            ramRequired: "~1.5 GB",
            expectedToksPerSec: "40-60",
            huggingFaceRepo: "Qwen/Qwen3.5-0.8B-GGUF",
            huggingFaceFile: "qwen3.5-0.8b-q8_0.gguf"
        ),
        LLMModelInfo(
            id: "qwen3.5-2b-q4km",
            name: "Qwen3.5-2B",
            displayName: "Qwen 3.5 2B (Q4_K_M)",
            parameters: "2B",
            quantization: "Q4_K_M",
            sizeBytes: 1_500_000_000,
            ramRequired: "~2.5 GB",
            expectedToksPerSec: "25-40",
            huggingFaceRepo: "Qwen/Qwen3.5-2B-GGUF",
            huggingFaceFile: "qwen3.5-2b-q4_k_m.gguf"
        ),
        LLMModelInfo(
            id: "qwen3.5-4b-q4km",
            name: "Qwen3.5-4B",
            displayName: "Qwen 3.5 4B (Q4_K_M)",
            parameters: "4B",
            quantization: "Q4_K_M",
            sizeBytes: 2_800_000_000,
            ramRequired: "~4 GB",
            expectedToksPerSec: "15-25",
            huggingFaceRepo: "Qwen/Qwen3.5-4B-GGUF",
            huggingFaceFile: "qwen3.5-4b-q4_k_m.gguf"
        )
    ]
}
