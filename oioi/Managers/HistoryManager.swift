import Foundation

final class HistoryManager {
    static let shared = HistoryManager()
    
    private(set) var items: [ClipboardItem] = []
    
    private init() {} // Make singleton initialization private
    
    func addItem(_ content: String) {
        // Check if content already exists to prevent duplicates
        if let existingIndex = items.firstIndex(where: { $0.content == content }) {
            // Move existing item to top instead of creating duplicate
            let existingItem = items.remove(at: existingIndex)
            items.insert(existingItem, at: 0)
        } else {
            // Create new item only if it doesn't exist
            let newItem = ClipboardItem(content: content)
            items.insert(newItem, at: 0)
        }
        itemsDidChange()
    }
    
    func itemsDidChange() {
        NotificationCenter.default.post(name: .historyUpdated, object: nil)
    }
}
