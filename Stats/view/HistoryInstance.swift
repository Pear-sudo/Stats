//
//  HistoryInstance.swift
//  Stats
//
//  Created by A on 02/09/2024.
//

import SwiftUI
import SwiftData

struct HistoryInstance: View {
    var category: Category
    
    @State private var date: Date = .now
    
    var body: some View {
        VStack(alignment: .leading) {
            HistoryInstanceController(date: $date)
            HistoryInstanceTable(category: category, date: date)
        }
    }
}

fileprivate struct HistoryInstanceWrapper: View {
    @Query private var categories: [Category]
    var body: some View {
        HistoryInstance(category: categories.first!)
    }
}

#Preview {
    HistoryInstanceWrapper()
        .modelContainer(for: models, inMemory: false)
}
