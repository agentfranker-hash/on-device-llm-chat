import SwiftUI

struct SettingsView: View {
    @AppStorage("systemPrompt") private var systemPrompt = AppDefaults.systemPrompt
    @AppStorage("temperature") private var temperature = Double(AppDefaults.temperature)
    @AppStorage("topP") private var topP = Double(AppDefaults.topP)
    @AppStorage("maxContext") private var maxContext = Double(AppDefaults.maxContextLength)

    var body: some View {
        NavigationStack {
            Form {
                Section("System Prompt") {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 80)
                        .font(.subheadline)

                    Button("Reset to Default") {
                        systemPrompt = AppDefaults.systemPrompt
                    }
                    .font(.caption)
                    .foregroundStyle(.cyan)
                }

                Section("Generation") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.2f", temperature))
                                .foregroundStyle(.cyan)
                                .fontDesign(.monospaced)
                        }
                        Slider(value: $temperature, in: 0...2, step: 0.05)
                            .tint(.cyan)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Top-P")
                            Spacer()
                            Text(String(format: "%.2f", topP))
                                .foregroundStyle(.cyan)
                                .fontDesign(.monospaced)
                        }
                        Slider(value: $topP, in: 0...1, step: 0.05)
                            .tint(.cyan)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Context")
                            Spacer()
                            Text("\(Int(maxContext))")
                                .foregroundStyle(.cyan)
                                .fontDesign(.monospaced)
                        }
                        Slider(value: $maxContext, in: 512...8192, step: 512)
                            .tint(.cyan)
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "NeonChat v0.1")
                    LabeledContent("Runtime", value: "llama.cpp + Metal")
                    LabeledContent("Models", value: "Qwen 3.5 Small Series")
                    LabeledContent("License", value: "MIT")

                    Link(destination: URL(string: "https://github.com/ggml-org/llama.cpp")!) {
                        LabeledContent("llama.cpp") {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.cyan)
                        }
                    }

                    Link(destination: URL(string: "https://huggingface.co/Qwen")!) {
                        LabeledContent("Qwen Models") {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.cyan)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
