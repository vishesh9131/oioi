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
        pasteboard.setString(item.content, forType: .string)
        
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
