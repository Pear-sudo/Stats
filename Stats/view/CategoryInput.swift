//
//  CategoryInput.swift
//  Stats
//
//  Created by A on 30/08/2024.
//

import SwiftUI
import SwiftData

struct CategoryInput: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.commands) private var commands
    
    var category: Category
    
    @State private var startDate: Date? = nil
    @State private var count: Int? = nil
    @FocusState private var inputIsFocused
    
    var body: some View {
        VStack {
            HStack {
                Button(startDate == nil ? "Start" : startDate!.formatted(
                    Date.FormatStyle()
                        .hour(.defaultDigits(amPM: .abbreviated))
                        .minute(.defaultDigits)
                        .second(.defaultDigits)
                )) {
                    start()
                }
                .disabled(startDate != nil)
                .contextMenu {
                    if startDate != nil {
                        Button("Reset to now", role: .destructive) {
                            startDate = .now
                        }
                        Button("Cancel") {
                            startDate = nil
                            inputIsFocused = false
                        }
                    }
                }
                TextField("Count", value: $count, format: .number)
                    .onSubmit {
                        save()
                    }
                    .focused($inputIsFocused)
                Button("Save") {
                    save()
                }
                .disabled(shouldSaveDisabled)
            }
            Divider()
            HistoryInstance(category: category)
        }
        .padding()
        .onReceive(commands) { command in
            switch command {
            case .start:
                start()
            }
        }
    }
    
    private func start() {
        startDate = .now
        inputIsFocused = true
    }
    
    private func save() {
        defer {
            count = nil
            startDate = nil
            inputIsFocused = false
        }
        let instance = startDate == nil ? Instance(count: count!, category: category) : Instance(start: startDate!, count: count!, category: category)
        modelContext.insert(instance)
    }
    
    private var shouldSaveDisabled: Bool {
        if count == nil {
            return true
        }
        return false
    }
}

#Preview {
    CategoryInput(category: Category(name: "push-up"))
        .modelContainer(for: models, inMemory: false)
}
