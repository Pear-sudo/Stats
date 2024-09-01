//
//  HistoryInstances.swift
//  Stats
//
//  Created by A on 01/09/2024.
//


import SwiftUI
import SwiftData

struct HistoryInstances: View {
    @Environment(\.modelContext) private var modelContext
    var category: Category
    @Query private var instances: [Instance]
    @State private var selectedInstances = Set<Instance.ID>()
    @State private var sortOrder = [KeyPathComparator(\Instance.start, order: .reverse)]
    @SceneStorage("InstanceTableConfig")
    private var columnCustomization: TableColumnCustomization<Instance>
    @State private var countPopoverInstance: Instance? = nil
    @State private var count: Int = 0
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
                    .popover(isPresented: .init(get: {countPopoverInstance == instance}, set: {$0 == true ? (countPopoverInstance = instance) : (countPopoverInstance = nil)})) {
                        TextField("Count", value: $count, format: .number)
                            .onSubmit {
                                instance.count = count
                                countPopoverInstance = nil
                            }
                            .frame(minWidth: 50)
                            .padding()
                    }
                    .onTapGesture(count: 2) {
                        count = instance.count
                        countPopoverInstance = instance
                    }
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
