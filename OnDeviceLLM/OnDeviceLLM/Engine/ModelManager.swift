import Foundation
import os

@Observable
final class ModelManager: NSObject {
    var downloadProgress: [String: Double] = [:]
    var downloadedModels: Set<String> = []
    var activeDownloads: Set<String> = []
    var errorMessage: String?

    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var backgroundSession: URLSession?
    private var downloadCompletionHandlers: [String: (URL) -> Void] = [:]

    private let logger = Logger(subsystem: "com.ondevicellm", category: "ModelManager")

    static let shared = ModelManager()

    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.ondevicellm.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        scanDownloadedModels()
    }

    var modelsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsDir = docs.appendingPathComponent("models", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        return modelsDir
    }

    func modelPath(for modelInfo: LLMModelInfo) -> URL {
        modelsDirectory.appendingPathComponent(modelInfo.huggingFaceFile)
    }

    func isDownloaded(_ modelInfo: LLMModelInfo) -> Bool {
        downloadedModels.contains(modelInfo.id)
    }

    func scanDownloadedModels() {
        downloadedModels.removeAll()
        for model in LLMModelInfo.availableModels {
            let path = modelPath(for: model)
            if FileManager.default.fileExists(atPath: path.path) {
                downloadedModels.insert(model.id)
            }
        }
    }

    func downloadModel(_ modelInfo: LLMModelInfo) {
        guard !activeDownloads.contains(modelInfo.id) else { return }
        guard !isDownloaded(modelInfo) else { return }

        logger.info("Starting download: \(modelInfo.displayName)")
        activeDownloads.insert(modelInfo.id)
        downloadProgress[modelInfo.id] = 0

        let task = backgroundSession!.downloadTask(with: modelInfo.downloadURL)
        task.taskDescription = modelInfo.id
        downloadTasks[modelInfo.id] = task

        downloadCompletionHandlers[modelInfo.id] = { [weak self] tempURL in
            guard let self else { return }
            let destination = self.modelPath(for: modelInfo)
            try? FileManager.default.removeItem(at: destination)
            do {
                try FileManager.default.moveItem(at: tempURL, to: destination)
                Task { @MainActor in
                    self.downloadedModels.insert(modelInfo.id)
                    self.activeDownloads.remove(modelInfo.id)
                    self.downloadProgress.removeValue(forKey: modelInfo.id)
                    self.logger.info("Download complete: \(modelInfo.displayName)")
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to save model: \(error.localizedDescription)"
                    self.activeDownloads.remove(modelInfo.id)
                    self.downloadProgress.removeValue(forKey: modelInfo.id)
                }
            }
        }

        task.resume()
    }

    func cancelDownload(_ modelInfo: LLMModelInfo) {
        downloadTasks[modelInfo.id]?.cancel()
        downloadTasks.removeValue(forKey: modelInfo.id)
        activeDownloads.remove(modelInfo.id)
        downloadProgress.removeValue(forKey: modelInfo.id)
        downloadCompletionHandlers.removeValue(forKey: modelInfo.id)
    }

    func deleteModel(_ modelInfo: LLMModelInfo) {
        let path = modelPath(for: modelInfo)
        try? FileManager.default.removeItem(at: path)
        downloadedModels.remove(modelInfo.id)
        logger.info("Deleted model: \(modelInfo.displayName)")
    }

    func diskUsage(for modelInfo: LLMModelInfo) -> String? {
        let path = modelPath(for: modelInfo)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path.path),
              let size = attrs[.size] as? Int64 else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - URLSessionDownloadDelegate
extension ModelManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let modelId = downloadTask.taskDescription,
              let handler = downloadCompletionHandlers[modelId] else { return }
        handler(location)
        downloadCompletionHandlers.removeValue(forKey: modelId)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let modelId = downloadTask.taskDescription else { return }
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0
        Task { @MainActor in
            self.downloadProgress[modelId] = progress
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let modelId = task.taskDescription, let error else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        Task { @MainActor in
            self.errorMessage = "Download failed: \(error.localizedDescription)"
            self.activeDownloads.remove(modelId)
            self.downloadProgress.removeValue(forKey: modelId)
        }
    }
}
