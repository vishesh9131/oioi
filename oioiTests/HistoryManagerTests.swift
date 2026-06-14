//
//  HistoryManagerTests.swift
//  oioiTests
//
//  Created by Antigravity on 04/10/25.
//

import XCTest
@testable import oioi

final class HistoryManagerTests: XCTestCase {

    var historyManager: HistoryManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Reset the singleton state if possible or mock it. 
        // Swift singletons are hard to reset. We might need to expose a method to clear items for testing.
        // For now, let's assume we can modify the items directly if we make the setter internal or check if there's a clear method.
        // Looking at the code: private(set) var items
        // We might need to add a reset method to HistoryManager for testing purposes.
        historyManager = HistoryManager.shared
        // Clean up before test
        resetHistory()
    }

    override func tearDownWithError() throws {
        resetHistory()
        historyManager = nil
        try super.tearDownWithError()
    }
    
    // Helper to reset history
    private func resetHistory() {
        historyManager.clearHistory()
    }

    func testHistoryLimit() throws {
        // Given a limit of 50
        let limit = 50
        
        // When we add 60 items
        for i in 1...60 {
            let item = ClipboardItem(dataType: .text("Item \(i)"))
            historyManager.addItem(item)
        }
        
        // Then
        XCTAssertLessThanOrEqual(historyManager.items.count, limit, "History size should not exceed the limit")
        XCTAssertEqual(historyManager.items.count, limit, "History size should be equal to the limit if enough items are added")
        
        // Verify the content: The LAST added item (Item 60) should be at index 0
        if let firstItem = historyManager.items.first {
             if case .text(let text) = firstItem.dataType {
                 XCTAssertEqual(text, "Item 60", "The most recent item should be at the top")
             } else {
                 XCTFail("Wrong data type")
             }
        }
        
        // The FIRST added item (Item 1) should be gone (since we added 60, and limit is 50, items 1-10 should be gone)
        // If we search for "Item 1", it should not be found.
        let foundOldItem = historyManager.items.contains { item in
            if case .text(let text) = item.dataType {
                return text == "Item 1"
            }
            return false
        }
        
        XCTAssertFalse(foundOldItem, "Old items should be removed when limit is reached")
    }
}
