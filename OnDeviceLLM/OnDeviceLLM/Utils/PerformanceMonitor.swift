import Foundation
import os

@Observable
final class PerformanceMonitor {
    var tokensPerSecond: Double = 0
    var totalTokens: Int = 0
    var memoryUsedMB: Double = 0
    var availableMemoryMB: Double = 0
    var thermalState: ProcessInfo.ThermalState = .nominal
    var contextUsed: Int = 0
    var contextMax: Int = 0

    private var generationStartTime: Date?
    private var tokenCount: Int = 0
    private var timer: Timer?

    var thermalStateString: String {
        switch thermalState {
        case .nominal: return "Cool"
        case .fair: return "Warm"
        case .serious: return "Hot"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    var thermalColor: String {
        switch thermalState {
        case .nominal: return "green"
        case .fair: return "yellow"
        case .serious: return "orange"
        case .critical: return "red"
        @unknown default: return "gray"
        }
    }

    var contextUsagePercent: Double {
        guard contextMax > 0 else { return 0 }
        return Double(contextUsed) / Double(contextMax) * 100
    }

    func startGeneration() {
        generationStartTime = Date()
        tokenCount = 0
    }

    func recordToken() {
        tokenCount += 1
        totalTokens += 1
        if let start = generationStartTime {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed > 0 {
                tokensPerSecond = Double(tokenCount) / elapsed
            }
        }
    }

    func stopGeneration() {
        generationStartTime = nil
    }

    func updateMemory() {
        availableMemoryMB = Double(os_proc_available_memory()) / 1_048_576.0
        thermalState = ProcessInfo.processInfo.thermalState
    }

    func updateContext(used: Int, max: Int) {
        contextUsed = used
        contextMax = max
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemory()
            }
        }
        updateMemory()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
