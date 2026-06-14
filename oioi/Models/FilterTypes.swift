import Foundation

enum ContentFilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case text = "Text"
    case image = "Image"
    case files = "Files"
    
    var id: String { rawValue }
}

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case today = "Today"
    case yesterday = "Yesterday"
    case last7Days = "Last 7 Days"
    
    var id: String { rawValue }
    
    func matches(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        switch self {
        case .all:
            return true
        case .today:
            return date >= startOfToday
        case .yesterday:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else { return false }
            return date >= yesterday && date < startOfToday
        case .last7Days:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) else { return false }
            return date >= weekAgo
        }
    }
}
