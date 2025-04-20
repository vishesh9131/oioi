import Foundation
import AppKit // Needed for NSImage

// Enum to represent the different types of clipboard data
enum ClipboardDataType: Equatable {
    case text(String)
    case image(Data) // Store raw image data (e.g., TIFF or PNG)
    case fileURLs([URL]) // Store array of file URLs

    // Equatable conformance (basic implementation)
    static func == (lhs: ClipboardDataType, rhs: ClipboardDataType) -> Bool {
        switch (lhs, rhs) {
        case (.text(let l), .text(let r)): return l == r
        case (.image(let l), .image(let r)): return l == r
        case (.fileURLs(let l), .fileURLs(let r)): return l == r
        default: return false
        }
    }
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let dataType: ClipboardDataType

    // Explicit initializer accepting dataType
    init(dataType: ClipboardDataType, timestamp: Date = Date()) {
        self.dataType = dataType
        self.timestamp = timestamp
    }
    
    // Helper for displaying a preview in the UI
    var previewString: String {
        switch dataType {
        case .text(let string):
            return string
        case .image:
            return "Image" // Placeholder text for images
        case .fileURLs(let urls):
            if urls.count == 1 {
                return urls.first?.lastPathComponent ?? "File"
            } else {
                return "\(urls.count) Files"
            }
        }
    }

    // Helper to get a display icon
    var displayIcon: NSImage {
        switch dataType {
        case .text:
            return NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Text")!
        case .image:
            // Try to create a thumbnail from data, fallback to generic icon
            if case .image(let data) = dataType, let image = NSImage(data: data) {
                // Create a smaller thumbnail version if needed, or just return the image
                 image.size = NSSize(width: 24, height: 24) // Example size
                 return image
            } else {
                 return NSImage(systemSymbolName: "photo", accessibilityDescription: "Image")!
            }

        case .fileURLs(let urls):
            if urls.count == 1, let url = urls.first {
                // Get specific file icon
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                icon.size = NSSize(width: 24, height: 24) // Ensure consistent icon size
                return icon
            } else {
                // Generic multiple files icon
                let icon = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Files")!
                icon.size = NSSize(width: 24, height: 24)
                return icon
            }
        }
    }

    // Equatable conformance
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        // Compare based on dataType first for potential performance win
        // Note: Comparing image Data might be slow for large images.
        // Consider using a hash or checksum if performance becomes an issue.
        lhs.dataType == rhs.dataType
    }
}

// REMOVED Extension for Notification Name - It's defined elsewhere
// extension Notification.Name {
//     static let historyUpdated = Notification.Name("historyUpdatedNotification")
// }
