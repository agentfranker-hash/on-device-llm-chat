# NeonChat — On-Device LLM Chat

An iOS app running **Qwen 3.5 Small models entirely on-device** via llama.cpp with Metal GPU acceleration. No server, no API calls, no data leaving your phone.

## Features

- 🧠 **On-device inference** — Qwen 3.5 (0.8B / 2B / 4B) running locally via llama.cpp
- ⚡ **Metal GPU acceleration** — Optimized for Apple Silicon (A17 Pro / A18)
- 💬 **Streaming chat UI** — Token-by-token response display with neon dark theme
- 📊 **Performance monitoring** — Live tok/s, memory usage, thermal state
- 📦 **Model manager** — Download models from HuggingFace, manage storage
- 🔒 **Fully offline** — Works without internet once models are downloaded
- ⚙️ **Configurable** — Temperature, top-p, context length, system prompt

## Requirements

- iOS 17.0+
- iPhone 15 Pro or newer (8GB RAM recommended)
- Xcode 16+

## Build

1. Clone the repo
2. Open `OnDeviceLLM/` in Xcode
3. The llama.cpp SPM dependency will resolve automatically
4. Build and run on a physical device (simulator won't have Metal)

## Architecture

```
SwiftUI App
  ├── ChatView        — Chat interface with streaming bubbles
  ├── ModelPickerView  — Download/manage GGUF models
  ├── SettingsView     — Generation parameters
  ├── LLMEngine       — llama.cpp Swift bridge (AsyncStream)
  ├── ModelManager     — HuggingFace download + storage
  └── PerformanceMonitor — tok/s, memory, thermal tracking
```

## Models

| Model | Size | RAM | Speed (est.) |
|-------|------|-----|-------------|
| Qwen 3.5 0.8B Q8_0 | ~900 MB | ~1.5 GB | 40-60 tok/s |
| Qwen 3.5 2B Q4_K_M | ~1.5 GB | ~2.5 GB | 25-40 tok/s |
| Qwen 3.5 4B Q4_K_M | ~2.8 GB | ~4 GB | 15-25 tok/s |

## Status

**Phase 1 (Current):** Core chat app with text generation, model management, and performance monitoring. The llama.cpp C bridge has placeholder implementations with detailed TODO comments showing the exact API calls needed — connect them in Xcode with the SPM package resolved.

**Phase 2:** Multi-model switching, conversation persistence via SwiftData, memory pressure handling.

**Phase 3:** Multimodal (camera/photo input for vision tasks).

**Phase 4:** Benchmarking and documentation.

See [SPEC.md](SPEC.md) for the full technical specification.

## License

MIT
