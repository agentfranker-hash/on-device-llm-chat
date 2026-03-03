# On-Device LLM Chat — POC Spec

> **Status:** Draft
> **Created:** 2026-03-02
> **Type:** Proof of Concept
> **Target Platform:** iOS (iPhone 15 Pro+)

---

## 1. Overview

A native iOS chat app that runs Qwen 3.5 Small models **entirely on-device** — no server, no API calls, no data leaving the phone. The goal is to prove out the viability of local LLM inference on modern iPhones for conversational AI use cases.

### Why Now
- **Qwen 3.5 Small Series** (released March 2, 2026) ships four models purpose-built for edge: 0.8B, 2B, 4B, 9B — all natively multimodal, 262K context, Apache 2.0
- iPhone 15 Pro/16 series have 8GB RAM and a powerful Neural Engine (16-core)
- llama.cpp and CoreML toolchains have matured significantly for iOS deployment
- On-device = zero latency to first token, full privacy, works offline

### Success Criteria
- [ ] Run a quantized Qwen 3.5 model on iPhone with acceptable token generation speed (>15 tok/s)
- [ ] Functional chat UI with streaming responses
- [ ] Model download + management within the app
- [ ] Demonstrate multimodal capability (image input from camera/photos)
- [ ] Measure and document memory usage, thermal behavior, battery impact

---

## 2. Model Selection

### Primary: Qwen3.5-4B (Q4_K_M quantization)
| Metric | Value |
|--------|-------|
| Parameters | 4B |
| Quantized Size | ~2.5-3 GB |
| VRAM/RAM Required | ~3-4 GB |
| Architecture | Gated DeltaNet hybrid (3:1 linear:full attention) |
| Context Window | 262K native |
| Modalities | Text + Image + Video |
| License | Apache 2.0 |

**Why 4B as primary:**
- Sweet spot for iPhone 15 Pro / 16 (8GB RAM, ~6GB available to apps)
- Benchmarks are strong: 77.6 MMMU, 85.1 MathVista, 86.2 OCRBench
- Natively multimodal — no separate vision adapter needed
- 262K context with constant memory complexity (DeltaNet architecture)

### Fallback: Qwen3.5-2B (Q4_K_M)
| Metric | Value |
|--------|-------|
| Quantized Size | ~1.2-1.5 GB |
| RAM Required | ~2 GB |

**When to use:** Older devices (iPhone 14 Pro, devices with 6GB RAM), or when memory pressure is high. Still very capable — beats many previous-gen 7B models on vision tasks.

### Stretch: Qwen3.5-0.8B (Q8_0)
| Metric | Value |
|--------|-------|
| Quantized Size | ~0.8-1 GB |
| RAM Required | ~1.2 GB |

**When to use:** Background/always-on scenarios, ultra-fast responses, or as a "draft" model for speculative decoding. Can run Q8 (higher quality) since it's so small.

---

## 3. Technical Architecture

### 3.1 Runtime: llama.cpp (Recommended for POC)

```
┌─────────────────────────────────────────────┐
│                  SwiftUI App                 │
│  ┌────────────┐  ┌────────────────────────┐  │
│  │  Chat UI   │  │  Model Manager         │  │
│  │  (SwiftUI) │  │  (Download / Switch)   │  │
│  └─────┬──────┘  └──────────┬─────────────┘  │
│        │                    │                │
│  ┌─────▼────────────────────▼─────────────┐  │
│  │        LLM Engine (Swift Bridge)       │  │
│  │  - Token streaming                     │  │
│  │  - Conversation management             │  │
│  │  - Image preprocessing                 │  │
│  │  - Context window management           │  │
│  └─────────────┬─────────────────────────┘  │
│                │                             │
│  ┌─────────────▼─────────────────────────┐  │
│  │     llama.cpp (C++ via Swift bridge)  │  │
│  │  - Metal GPU acceleration             │  │
│  │  - GGUF model loading                 │  │
│  │  - KV cache management                │  │
│  │  - Multi-token prediction             │  │
│  └───────────────────────────────────────┘  │
│                                              │
│  ┌───────────────────────────────────────┐  │
│  │     Apple Silicon (A17 Pro / A18)     │  │
│  │  GPU (Metal) + Neural Engine + CPU    │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

**Why llama.cpp over CoreML for POC:**
- Fastest path to working prototype — no model conversion step
- GGUF quantized models available immediately on HuggingFace
- Active community, well-tested on iOS via Metal backend
- Supports all Qwen 3.5 features including multimodal + MTP
- Easy to swap models (just download a different GGUF)

**CoreML consideration for v2:**
- Better Neural Engine utilization (could be faster for smaller models)
- Requires conversion pipeline via `coremltools`
- More complex setup but potentially better battery efficiency
- Worth exploring after POC validates the use case

### 3.2 Key Components

#### Model Manager
- Download GGUF models from HuggingFace (background download with progress)
- Store in app's Documents directory
- Support multiple models (switch between 0.8B/2B/4B)
- Show model size, RAM requirements, estimated speed
- Delete models to free space

#### LLM Engine
- Swift wrapper around llama.cpp C API
- Async token generation with Swift Concurrency (AsyncStream)
- Conversation history management (chat template formatting)
- System prompt configuration
- Temperature / top-p / top-k sampling controls
- Context window management (auto-truncation when approaching limit)
- Graceful degradation under memory pressure

#### Image Pipeline (Multimodal)
- Camera capture and photo library picker
- Image preprocessing (resize, normalize for model input)
- Pass image tokens alongside text to the model
- Support for "describe this image" / "what do you see" flows

#### Chat UI
- Standard chat bubble interface (SwiftUI)
- Streaming text display (token by token)
- Image attachment support
- Model selector (dropdown or settings)
- Performance stats overlay (tok/s, memory, context usage)
- Conversation persistence (Core Data or SwiftData)

---

## 4. Implementation Plan

### Phase 1: Core Chat (Week 1-2)
**Goal:** Text chat working end-to-end on device

- [ ] Set up Xcode project with SwiftUI
- [ ] Integrate llama.cpp as SPM package (or build from source)
- [ ] Download and load Qwen3.5-2B GGUF (start small)
- [ ] Implement basic token generation with Metal acceleration
- [ ] Build minimal chat UI with streaming responses
- [ ] Add conversation history / chat template formatting
- [ ] Basic performance metrics (tokens/sec display)

**Milestone:** Can have a text conversation with Qwen 3.5 running 100% on-device

### Phase 2: Model Management + Polish (Week 3)
**Goal:** Multi-model support, better UX

- [ ] Model download manager (HuggingFace → local storage)
- [ ] Support 0.8B / 2B / 4B model switching
- [ ] Conversation persistence (save/load chats)
- [ ] System prompt customization
- [ ] Sampling parameter controls
- [ ] Memory pressure handling (auto-unload, warnings)
- [ ] App size optimization (model files are separate downloads)

**Milestone:** User can download models and switch between them

### Phase 3: Multimodal (Week 4)
**Goal:** Image understanding working on-device

- [ ] Integrate vision preprocessing pipeline
- [ ] Camera capture flow
- [ ] Photo library picker
- [ ] Image + text prompting
- [ ] Test with OCR, scene description, document reading
- [ ] Performance profiling with vision workloads

**Milestone:** Can take a photo and ask the model questions about it

### Phase 4: Benchmarking + Documentation (Week 5)
**Goal:** Know exactly what this can and can't do

- [ ] Comprehensive benchmarks across all three models
- [ ] Token generation speed (prompt processing + generation)
- [ ] Memory usage profiling
- [ ] Thermal throttling behavior over extended use
- [ ] Battery drain measurements
- [ ] Quality assessment (subjective + benchmark tasks)
- [ ] Document findings and recommendations

**Milestone:** Clear data on viability for production use cases

---

## 5. Performance Expectations

Based on community benchmarks for similar models on Apple Silicon:

| Model | Device | Expected tok/s | Prompt Processing | RAM Usage |
|-------|--------|---------------|-------------------|-----------|
| Qwen3.5-0.8B Q8 | iPhone 15 Pro | 40-60 | ~500 tok/s | ~1.5 GB |
| Qwen3.5-2B Q4_K_M | iPhone 15 Pro | 25-40 | ~300 tok/s | ~2.5 GB |
| Qwen3.5-4B Q4_K_M | iPhone 15 Pro | 15-25 | ~150 tok/s | ~4 GB |
| Qwen3.5-2B Q4_K_M | iPhone 16 Pro | 30-50 | ~400 tok/s | ~2.5 GB |
| Qwen3.5-4B Q4_K_M | iPhone 16 Pro | 20-35 | ~200 tok/s | ~4 GB |

> ⚠️ These are estimates. Actual numbers depend on context length, quantization method, Metal optimization level, and thermal state. Phase 4 will produce real measurements.

**Key factors:**
- **DeltaNet architecture advantage:** The 3:1 linear-to-full attention ratio means memory usage stays more constant as context grows — huge win for mobile
- **MTP (Multi-Token Prediction):** Qwen 3.5 models predict multiple tokens at once, providing a direct speed boost if the runtime supports it
- **Metal acceleration:** llama.cpp Metal backend is well-optimized for Apple GPU

---

## 6. Technical Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Memory pressure / OOM crashes** | High | Start with 2B model. Implement memory monitoring. Auto-unload model when app backgrounds. Set max context to 4K-8K for POC. |
| **Thermal throttling** | Medium | Monitor thermal state via `ProcessInfo`. Warn user. Reduce batch size when hot. Consider limiting continuous generation. |
| **Slow prompt processing** | Medium | Keep initial context small. Use KV cache. Pre-process system prompts. |
| **llama.cpp Qwen 3.5 support gaps** | Medium | Qwen models well-supported in llama.cpp. Verify multimodal + MTP support specifically. Fall back to text-only if vision pipeline isn't ready. |
| **App Store size limits** | Low | Models are downloaded separately (not bundled). App binary stays small. |
| **Model quality at small sizes** | Low | Qwen 3.5 benchmarks are genuinely strong at 2B/4B. Acceptable for POC. |

---

## 7. Dependencies & Resources

### Required
- Xcode 16+ with Swift 6
- iPhone 15 Pro or newer (for testing)
- llama.cpp iOS-compatible build ([ggerganov/llama.cpp](https://github.com/ggerganov/llama.cpp))
- Qwen 3.5 GGUF models from HuggingFace

### Model Sources
```
https://huggingface.co/Qwen/Qwen3.5-0.8B-GGUF
https://huggingface.co/Qwen/Qwen3.5-2B-GGUF
https://huggingface.co/Qwen/Qwen3.5-4B-GGUF
```

### Key References
- [llama.cpp Metal documentation](https://github.com/ggerganov/llama.cpp/blob/master/docs/backend/METAL.md)
- [Apple Core ML On-Device LLM Guide](https://machinelearning.apple.com/research/core-ml-on-device-llama)
- [Qwen 3.5 Model Cards](https://github.com/QwenLM/Qwen3.5)
- [Gated DeltaNet Paper](https://arxiv.org/abs/2412.06464)

---

## 8. Future Considerations (Post-POC)

If the POC validates on-device inference:

- **CoreML conversion** for better Neural Engine utilization + battery efficiency
- **Speculative decoding** — use 0.8B as draft model, 4B as verifier for faster generation
- **RAG on-device** — SQLite + vector embeddings for grounded responses
- **Background processing** — summarize notifications, pre-process context
- **Coaching integration** — could this power the Coach App's on-device layer?
- **Hybrid architecture** — on-device for fast/private tasks, cloud for heavy reasoning
- **Fine-tuning** — QLoRA adapters for domain-specific behavior (loaded on-device)
- **Widget / Live Activity** — quick interactions without opening the app

---

## 9. Open Questions

- [ ] Does llama.cpp fully support Qwen 3.5's vision pipeline on iOS, or is that text-only for now?
- [ ] What's the practical max context length on iPhone before memory becomes an issue? (262K native but RAM-limited)
- [ ] Is the MTP (multi-token prediction) supported in llama.cpp's Metal backend?
- [ ] TestFlight distribution — can we ship GGUF model downloads without App Store review issues?
- [ ] Should we consider ExecuTorch as an alternative runtime? (Meta's mobile-first framework)

---

*This is a POC spec. The goal is to prove viability, not ship a product. Keep it lean, measure everything, and let the data guide what comes next.*
