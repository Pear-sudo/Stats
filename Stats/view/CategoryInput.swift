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
            HistoryInstances(category: category)
        }
        .padding()
    }
    
    func save() {
        defer {
            count = nil
            start = nil
        }
        let instance = start == nil ? Instance(count: count!, category: category) : Instance(start: start!, category: category)
        modelContext.insert(instance)
    }
    
    var shouldSaveDisabled: Bool {
        if count == nil {
            return true
        }
        return false
    }
}

struct HistoryInstances: View {
    @Environment(\.modelContext) private var modelContext
    var category: Category
    @Query private var instances: [Instance]
    @State private var selectedInstances = Set<Instance.ID>()
    @State private var sortOrder = [KeyPathComparator(\Instance.start, order: .reverse)]
    @SceneStorage("InstanceTableConfig")
    private var columnCustomization: TableColumnCustomization<Instance>
    init(category: Category) {
        self.category = category
        let name = category.name
        let startOfToday = Calendar.current.startOfDay(for: .now)
        _instances = Query(FetchDescriptor(
            predicate: #Predicate<Instance> { instance in
                instance.category.name == name &&
                instance.start >= startOfToday
            },
            sortBy: [.init(\.start, order: .reverse)]
        ), animation: .default)
    }
    var body: some View {
        Table(of: Instance.self, selection: $selectedInstances, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Count", value: \.count) { instance in
                Text(instance.count.formatted())
            }
            .alignment(.center)
            .customizationID("count")
            
            TableColumn("Start", value: \.start) { instance in
                Text(instance.start.formatted(date: .omitted, time: .shortened))
            }
            .alignment(.center)
            .customizationID("start")
            
            TableColumn("End", value: \.end) { instance in
                Text(instance.end.formatted(date: .omitted, time: .shortened))
            }
            .alignment(.center)
            .customizationID("end")
            
            TableColumn("Duration", value: \.duration) { instance in
                Text(instance.duration.formatted(Duration.TimeFormatStyle(
                    pattern: .minuteSecond
                )))
            }
            .alignment(.center)
            .customizationID("duration")
        } rows: {
            ForEach(sortedInstances) { instance in
                TableRow(instance)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(instance)
                        }
                    }
            }
        }
    }
    
    var sortedInstances: [Instance] {
        instances.sorted(using: sortOrder)
    }
}

#Preview {
    CategoryInput(category: Category(name: "push-up"))
        .modelContainer(for: models, inMemory: false)
}
