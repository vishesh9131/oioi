import Combine
import SwiftUI

class HistoryViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var lastCopiedId: UUID? = nil // Track last copied item
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadItems()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .historyUpdated)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.loadItems()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadItems() {
        // Get new items, keeping track of old count
        let oldCount = items.count
        items = HistoryManager.shared.items
        
        // Force animation if items were added
        if items.count > oldCount {
            objectWillChange.send()
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        // Don't continue if it's already the last copied item
        if lastCopiedId == item.id {
            return
        }
        
        // This is crucial: Pause clipboard monitoring before copying
        ClipboardManager.shared.pauseMonitoring()
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Set pasteboard content based on item type
        var success = false
        switch item.dataType {
        case .text(let string):
            print("Attempting to copy text to clipboard...")
            success = pasteboard.setString(string, forType: .string)
            if success { print("Successfully copied text.") }
            
        case .image(let data):
            print("Attempting to copy image data to clipboard...")
            // Provide data in common formats applications might look for.
            // Create an NSImage object first to potentially get better type handling.
            if let image = NSImage(data: data) {
                 // NSPasteboardWriting protocol works well here
                 success = pasteboard.writeObjects([image])
                 if success { 
                      print("Successfully copied image using NSImage.") 
                 } else {
                      // Fallback: Try writing raw data with common types
                      print("NSImage write failed, falling back to raw data...")
                      // Order matters, some apps prefer specific types
                      if pasteboard.setData(data, forType: .tiff) { success = true }
                      if pasteboard.setData(data, forType: .png) { success = true } // Add data even if TIFF succeeded
                 }
            } else {
                 print("Error: Could not create NSImage from stored data.")
            }
             if success { print("Image data copy attempt finished (success=\(success)).") }

        case .fileURLs(let urls):
            print("Attempting to copy file URLs to clipboard...")
            // Make sure the URLs are file URLs
            let fileURLs = urls.filter { $0.isFileURL }
            if !fileURLs.isEmpty {
                // Cast URL to NSURL for NSPasteboardWriting conformance
                let nsURLs = fileURLs.map { $0 as NSURL } 
                success = pasteboard.writeObjects(nsURLs)
                if success { print("Successfully copied \(fileURLs.count) file URL(s).") }
            } else {
                 print("Error: No valid file URLs found in the item.")
            }
        }
        
        // Only proceed with feedback/closing if copy was successful
        guard success else {
             print("Error: Failed to write item of type \(item.dataType) to pasteboard.")
             // Resume monitoring even if copy failed
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Short delay
                  ClipboardManager.shared.resumeMonitoring()
             }
             return
        }
        
        // Haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        
        // Visual feedback
        withAnimation(.spring()) {
            lastCopiedId = item.id
        }
        
        // Play a subtle sound feedback
        // if let sound = NSSound(named: "Tink") {
        //     sound.volume = 0.3
        //     sound.play()
        // }
        
        // Reset feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation(.easeOut) {
                self?.lastCopiedId = nil
            }
        }
        
        // Automatically close the panel after successful copy with slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.menuBarController.togglePopover(nil)
            }
        }
        
        // Resume monitoring after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ClipboardManager.shared.resumeMonitoring()
        }
    }
}
