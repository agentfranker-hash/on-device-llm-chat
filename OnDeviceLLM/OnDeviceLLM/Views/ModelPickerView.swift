import SwiftUI

struct ModelPickerView: View {
    @State private var modelManager = ModelManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(LLMModelInfo.availableModels) { model in
                        ModelRow(model: model, manager: modelManager)
                    }
                } header: {
                    Text("Qwen 3.5 Small Series")
                } footer: {
                    Text("Models are downloaded from HuggingFace and stored on-device. All inference runs locally with Metal GPU acceleration.")
                }

                if !modelManager.downloadedModels.isEmpty {
                    Section("Storage") {
                        ForEach(LLMModelInfo.availableModels.filter { modelManager.isDownloaded($0) }) { model in
                            HStack {
                                Text(model.displayName)
                                    .font(.subheadline)
                                Spacer()
                                Text(modelManager.diskUsage(for: model) ?? "—")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Models")
            .alert("Download Error", isPresented: .init(
                get: { modelManager.errorMessage != nil },
                set: { if !$0 { modelManager.errorMessage = nil } }
            )) {
                Button("OK") { modelManager.errorMessage = nil }
            } message: {
                Text(modelManager.errorMessage ?? "")
            }
        }
    }
}

struct ModelRow: View {
    let model: LLMModelInfo
    @Bindable var manager: ModelManager

    var isDownloaded: Bool { manager.isDownloaded(model) }
    var isDownloading: Bool { manager.activeDownloads.contains(model.id) }
    var progress: Double { manager.downloadProgress[model.id] ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.headline)
                    HStack(spacing: 12) {
                        Label(model.sizeFormatted, systemImage: "internaldrive")
                        Label(model.ramRequired, systemImage: "memorychip")
                        Label("\(model.expectedToksPerSec) tok/s", systemImage: "speedometer")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if isDownloaded {
                    Menu {
                        Button(role: .destructive) {
                            manager.deleteModel(model)
                        } label: {
                            Label("Delete Model", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                    }
                } else if isDownloading {
                    Button {
                        manager.cancelDownload(model)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)
                    }
                } else {
                    Button {
                        manager.downloadModel(model)
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.cyan)
                            .font(.title2)
                    }
                }
            }

            if isDownloading {
                ProgressView(value: progress)
                    .tint(.cyan)
                HStack {
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Downloading...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModelPickerView()
}
