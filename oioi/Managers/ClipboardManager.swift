// Managers/ClipboardManager.swift
import AppKit

final class ClipboardManager {
    static let shared = ClipboardManager()
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount = 0
    private var timer: Timer?
    private var isMonitoringPaused = false
    
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func pauseMonitoring() {
        isMonitoringPaused = true
        print("Clipboard monitoring paused")
    }
    
    func resumeMonitoring() {
        isMonitoringPaused = false
        print("Clipboard monitoring resumed")
    }
    
    private func checkClipboard() {
        // Don't check if monitoring is paused
        if isMonitoringPaused {
            return
        }
        
        // Only check if change count is different
        guard pasteboard.changeCount != lastChangeCount else { 
            return 
        }
        
        lastChangeCount = pasteboard.changeCount
        
        // Only process string content
        guard let content = pasteboard.string(forType: .string) else {
            return
        }
        
        print("New clipboard content detected: \(content.prefix(20))...")
        HistoryManager.shared.addItem(content)
    }
    
    deinit {
        timer?.invalidate()
    }
}

