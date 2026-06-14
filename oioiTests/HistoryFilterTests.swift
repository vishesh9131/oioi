//
//  HistoryFilterTests.swift
//  oioiTests
//
//  Created by Antigravity on 04/10/25.
//

import Testing
@testable import oioi
import Foundation

struct HistoryFilterTests {

    @Test func testSearchTextFilter() async throws {
        let viewModel = HistoryViewModel()
        
        // Mock items
        let item1 = ClipboardItem(dataType: .text("Apple"))
        let item2 = ClipboardItem(dataType: .text("Banana"))
        let item3 = ClipboardItem(dataType: .text("Apricot"))
        
        viewModel.items = [item1, item2, item3]
        
        // Test 1: Search "Ap"
        viewModel.searchText = "Ap"
        #expect(viewModel.filteredItems.count == 2)
        #expect(viewModel.filteredItems.contains(where: { $0.id == item1.id }))
        #expect(viewModel.filteredItems.contains(where: { $0.id == item3.id }))
        
        // Test 2: Search "ban" (case insensitive)
        viewModel.searchText = "ban"
        #expect(viewModel.filteredItems.count == 1)
        #expect(viewModel.filteredItems.first?.id == item2.id)
        
        // Test 3: Empty search
        viewModel.searchText = ""
        #expect(viewModel.filteredItems.count == 3)
    }

    @Test func testTypeFilter() async throws {
        let viewModel = HistoryViewModel()
        
        let textItem = ClipboardItem(dataType: .text("Text"))
        let imageItem = ClipboardItem(dataType: .image(Data()))
        let fileItem = ClipboardItem(dataType: .fileURLs([URL(fileURLWithPath: "/")]))
        
        viewModel.items = [textItem, imageItem, fileItem]
        
        // Test All
        viewModel.selectedFilter = .all
        #expect(viewModel.filteredItems.count == 3)
        
        // Test Text
        viewModel.selectedFilter = .text
        #expect(viewModel.filteredItems.count == 1)
        #expect(viewModel.filteredItems.first?.id == textItem.id)
        
        // Test Image
        viewModel.selectedFilter = .image
        #expect(viewModel.filteredItems.count == 1)
        #expect(viewModel.filteredItems.first?.id == imageItem.id)
        
        // Test Files
        viewModel.selectedFilter = .files
        #expect(viewModel.filteredItems.count == 1)
        #expect(viewModel.filteredItems.first?.id == fileItem.id)
    }
    
    @Test func testDateFilter() async throws {
        let viewModel = HistoryViewModel()
        
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -6, to: today)!
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: today)!
        
        let itemToday = ClipboardItem(dataType: .text("Today"), timestamp: today)
        let itemYesterday = ClipboardItem(dataType: .text("Yesterday"), timestamp: yesterday)
        let itemLastWeek = ClipboardItem(dataType: .text("Last Week"), timestamp: lastWeek)
        let itemOld = ClipboardItem(dataType: .text("Old"), timestamp: oldDate)
        
        viewModel.items = [itemToday, itemYesterday, itemLastWeek, itemOld]
        
        // Test Today
        viewModel.selectedDateRange = .today
        // Note: Depending on exact time execution, "today" logic might vary if not careful, but unit tests usually fast enough.
        // Ideally we mock the date, but for now we rely on system time.
        // Since we created 'today' just now, it should pass.
        #expect(viewModel.filteredItems.contains(where: { $0.id == itemToday.id }))
        #expect(!viewModel.filteredItems.contains(where: { $0.id == itemOld.id }))
        
        // Test Yesterday
        viewModel.selectedDateRange = .yesterday
        #expect(viewModel.filteredItems.contains(where: { $0.id == itemYesterday.id }))
        
        // Test Last 7 Days (Today, Yesterday, Last Week are in range, Old is not)
        viewModel.selectedDateRange = .last7Days
        #expect(viewModel.filteredItems.contains(where: { $0.id == itemToday.id }))
        #expect(viewModel.filteredItems.contains(where: { $0.id == itemYesterday.id }))
        #expect(viewModel.filteredItems.contains(where: { $0.id == itemLastWeek.id }))
        #expect(!viewModel.filteredItems.contains(where: { $0.id == itemOld.id }))
    }
}
