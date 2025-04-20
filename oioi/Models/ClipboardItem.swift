import Foundation

struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    
    init(content: String, timestamp: Date = Date()) {
        self.content = content
        self.timestamp = timestamp
    }
}
