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
        HistoryInstanceKernel(category: category, date: $date)
    }
}

fileprivate struct HistoryInstanceKernel: View {
    @Binding var date: Date
    var category: Category
    init(category: Category, date: Binding<Date>) {
        self.category = category
        self._date = date
        
        let calendar = Calendar.current
        
        let name = category.name
        let startOfDate = calendar.startOfDay(for: date.wrappedValue)
        let endOfDate = calendar.date(byAdding: .day, value: 1, to: startOfDate)!.addingTimeInterval(-1e-9)
        
        _instances = Query(FetchDescriptor(
            predicate: #Predicate<Instance> { instance in
                instance.category.name == name &&
                instance.start >= startOfDate &&
                instance.start <= endOfDate
            },
            sortBy: [.init(\.start, order: .reverse)]
        ), animation: .default)
    }
    
    @Query(FetchDescriptor<Instance>.dummy) private var instances: [Instance]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HistoryInstanceController(date: $date)
                Spacer()
                TodayInstanceStats(instances: instances)
            }
            HistoryInstanceTable(instances: instances)
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
