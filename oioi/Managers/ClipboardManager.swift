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
        
        // Check for different data types in order of preference
        
        // 1. Check for File URLs
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !fileURLs.isEmpty {
            print("New clipboard content detected: \(fileURLs.count) File(s)")
            let newItem = ClipboardItem(dataType: .fileURLs(fileURLs))
            HistoryManager.shared.addItem(newItem) // Pass the whole item
            return // Found files, stop checking
        }

        // 2. Check for Images (check common types)
        // Prioritize specific image types if available, fallback to general image check
        let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png] // Add other types like .jpeg if needed
        if let availableImageType = pasteboard.availableType(from: imageTypes),
           let imageData = pasteboard.data(forType: availableImageType) {
            print("New clipboard content detected: Image (Type: \(availableImageType.rawValue))")
            let newItem = ClipboardItem(dataType: .image(imageData))
            HistoryManager.shared.addItem(newItem) // Pass the whole item
            return // Found image, stop checking
        }

        // 3. Check for Plain Text
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            print("New clipboard content detected: Text - \(content.prefix(30))...")
            let newItem = ClipboardItem(dataType: .text(content))
            HistoryManager.shared.addItem(newItem) // Pass the whole item
            return // Found text, stop checking
        }
        
        // Optional: Log if no supported content type was found for the change
        // print("Clipboard changed, but no supported content type found.")
    }
    
    deinit {
        timer?.invalidate()
    }
}

