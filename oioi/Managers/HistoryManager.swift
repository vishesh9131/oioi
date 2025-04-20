import Foundation

final class HistoryManager {
    static let shared = HistoryManager()
    
    private(set) var items: [ClipboardItem] = []
    
    private init() {} // Make singleton initialization private
    
    func addItem(_ newItem: ClipboardItem) {
        // Check if an item with the same data type and content already exists
        if let existingIndex = items.firstIndex(where: { $0.dataType == newItem.dataType }) {
            // Found a duplicate based on dataType comparison
            print("Duplicate item found, moving to top.")
            let existingItem = items.remove(at: existingIndex)
            // Update timestamp? Optional: Decide if you want to refresh the timestamp on move.
            // existingItem.timestamp = Date() // Example: uncomment to update timestamp
            items.insert(existingItem, at: 0)
        } else {
            // No duplicate found, insert the new item at the beginning
            print("Adding new unique item to history.")
            items.insert(newItem, at: 0)
            
            // Optional: Limit history size
            // let maxSize = 100 // Example limit
            // if items.count > maxSize {
            //     items.removeLast(items.count - maxSize)
            // }
        }
        itemsDidChange()
    }
    
    func itemsDidChange() {
        NotificationCenter.default.post(name: .historyUpdated, object: nil)
    }
}
