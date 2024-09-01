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
    var category: Category
    @State var start: Date? = nil
    @State var count: Int? = nil
    var body: some View {
        VStack {
            HStack {
                Button(start == nil ? "Start" : start!.formatted(
                    Date.FormatStyle()
                        .hour(.defaultDigits(amPM: .abbreviated))
                        .minute(.defaultDigits)
                        .second(.defaultDigits)
                )) {
                    start = .now
                }
                .disabled(start != nil)
                .contextMenu {
                    if start != nil {
                        Button(role: .destructive) {
                            start = .now
                        } label: {
                            Text("Reset to now")
                                .foregroundStyle(.red)
                        }
                    }
                }
                TextField("Count", value: $count, format: .number)
                    .onSubmit {
                        save()
                    }
                Button("Save") {
                    save()
                }
                .disabled(shouldSaveDisabled)
            }
            Divider()
            HistoryInstanceController(category: category)
        }
        .padding()
    }
    
    func save() {
        defer {
            count = nil
            start = nil
        }
        let instance = start == nil ? Instance(count: count!, category: category) : Instance(start: start!, count: count!, category: category)
        modelContext.insert(instance)
    }
    
    var shouldSaveDisabled: Bool {
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
