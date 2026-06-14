//
//  oioiTests.swift
//  oioiTests
//
//  Created by Vishesh Yadav on 19/04/25.
//

import Testing
@testable import oioi

struct oioiTests {

    @Test func historyLimit() async throws {
        let historyManager = HistoryManager.shared
        // Reset history
        historyManager.clearHistory()
        
        let limit = 50
        
        // When we add 60 items
        for i in 1...60 {
            let item = ClipboardItem(dataType: .text("Item \(i)"))
            historyManager.addItem(item)
        }
        
        // Then
        #expect(historyManager.items.count <= limit)
        #expect(historyManager.items.count == limit)
        
        // Verify the content: The LAST added item (Item 60) should be at index 0
        if let firstItem = historyManager.items.first {
             if case .text(let text) = firstItem.dataType {
                 #expect(text == "Item 60")
             } else {
                 #expect(Bool(false), "Wrong data type")
             }
        }
        
        // The FIRST added item (Item 1) should be gone
        let foundOldItem = historyManager.items.contains { item in
            if case .text(let text) = item.dataType {
                return text == "Item 1"
            }
            return false
        }
        
        #expect(!foundOldItem)
    }

}
