//
//  CategoryInspector.swift
//  Stats
//
//  Created by A on 31/08/2024.
//

import SwiftUI
import SwiftData

struct CategoryInspector: View {
    private typealias DisclosureGroupStates = [DisclosureGroupName: Bool]
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var stats = Stats()
    @State private var disclosureGroupStates: DisclosureGroupStates = [
        .historicalStats: true
    ]
    
    private var __latestInstance: Query<Instance, [Instance]>
    
    var category: Category
    init(category: Category) {
        self.category = category
        let name = category.name
        // TODO: fix bug: no change detected if something other than the last is deleted
        __latestInstance = Query({
            var d = FetchDescriptor(
                predicate: #Predicate<Instance>{ instance in
                    instance.category.name == name
                },
                sortBy: [.init(\.start, order: .reverse)]
            )
            d.fetchLimit = 1
            d.propertiesToFetch = [\.count]
            return d
        }())
    }
    
    var body: some View {
        VStack(alignment: .center) {
            ScrollView {
                DisclosureGroup(DisclosureGroupName.historicalStats.rawValue, isExpanded: self[.historicalStats]) { historicalStats }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            handleOnAppear()
        }
        .onChange(of: __latestInstance.wrappedValue) {
            calculateStats()
        }
        .onChange(of: disclosureGroupStates) {
            let jsonData = try! JSONEncoder().encode(disclosureGroupStates)
            UserDefaults.standard.set(jsonData, forKey: "disclosureGroupStates")
        }
    }
    
    private func handleOnAppear() {
        calculateStats()
        restoreDisclosureGroupStats()
    }
    
    // MARK: - Views
    
    var historicalStats: some View {
        Grid(alignment: .leading) {
            GridRow {
                Text("min: \(stats.min.formatted())")
                Text("max: \(stats.max.formatted())")
            }
            .fixedSize()
            GridRow {
                Text("avg: \(stats.avg.formatted(.number.precision(.fractionLength(2))))")
                Text("std: \(stats.std.formatted(.number.precision(.fractionLength(2))))")
            }
            .fixedSize()
        }
    }
    
    // MARK: - Disclosure Group
    
    private func restoreDisclosureGroupStats() {
        guard
            let data = UserDefaults.standard.data(forKey: "disclosureGroupStates"),
            let states = try? JSONDecoder().decode(DisclosureGroupStates.self, from: data) else {
            return
        }
        if states != disclosureGroupStates {
            disclosureGroupStates = states
        }
    }
    
    private subscript(key: DisclosureGroupName) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                self.disclosureGroupStates[key, default: false]
            },
            set: { newValue in
                withAnimation {
                    disclosureGroupStates[key] = newValue
                }
            }
        )
    }
    
    private enum DisclosureGroupName: String, Codable {
        case historicalStats = "Historical States"
    }
    
    // MARK: - Statistics
    
    private func calculateStats() {
        // TODO: cache stats for each day, month etc
        let name = category.name
        var stats = Stats()
        let fetchDescriptor = {
            var d = FetchDescriptor(predicate: #Predicate<Instance>{ instance in
                instance.category.name == name
            })
            d.propertiesToFetch = [\.count]
            return d
        }()
        try? modelContext.enumerate(fetchDescriptor) { instance in
            stats.add(value: instance.count)
        }
        self.stats = stats
    }
    struct Stats {
        var count: Double = 0
        var min: Double = .greatestFiniteMagnitude
        var max: Double = 0
        var avg: Double = 0
        private var m2: Double = 0
        mutating func add(value: Double) {
            count += 1
            min = Swift.min(min, value)
            max = Swift.max(max, value)
            let avg_previous = avg
            avg = (avg * (count - 1) + value) / count
            m2 = m2 + (value - avg_previous) * (value - avg)
        }
        var std: Double {
            sqrt(m2/count)
        }
        mutating func add(value: Int) {
            add(value: Double(value))
        }
    }
}

// MARK: - Previews

struct PreviewDataInjector: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let schema = Schema(models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @available(macOS 15.0, *)
    @MainActor static var injectData: Self = .modifier(PreviewDataInjector())
}

struct DataInjector<Content>: View where Content: View {
    private let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .modelContainer(for: models, inMemory: false)
    }
}

struct CategoryInspectorWrapper: View {
    @Query var categories: [Category]
    var body: some View {
        CategoryInspector(category: categories.first!)
    }
}

#Preview {
    CategoryInspectorWrapper()
        .modelContainer(for: models, inMemory: false)
        .frame(width: 300)
}
