//
//  HistoryInstanceController.swift
//  Stats
//
//  Created by A on 01/09/2024.
//

import SwiftUI
import SwiftData

struct HistoryInstanceController: View {
    
    var category: Category
    init(category: Category) {
        self.category = category
    }
    
    @State private var date: Date = .now
    @State private var datePickerIsShown = false
    
    private let calendar =  Calendar.current
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(date, style: .date)
                    .font(.headline)
                    .frame(minWidth: 130, alignment: .trailing)
                    .onTapGesture {
                        onDateTextTap()
                    }
                    .popover(isPresented: $datePickerIsShown) {
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                            .labelsHidden()
                            .datePickerStyle(.graphical)
                            .padding()
                    }
                    .contextMenu {
                        if !calendar.isDateInToday(date) {
                            Button("Today") {
                                date = .now
                            }
                        }
                    }
                Stepper(
                    value: $date,
                    step: 60 * 60 * 24
                ) {}

            }
            HistoryInstanceTable(category: category, date: date)
        }
    }
    
    private func onDateTextTap() {
        datePickerIsShown.toggle()
    }
}

struct HistoryInstanceControllerWrapper: View {
    @Query private var categories: [Category]
    var body: some View {
        HistoryInstanceController(category: categories.first!)
            .padding()
    }
}

#Preview {
    HistoryInstanceControllerWrapper()
        .modelContainer(for: models, inMemory: false)
}
