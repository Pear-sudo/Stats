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
    
    @State private var disclosureGroupStates: DisclosureGroupStates = [
        .historicalStats: true,
        .historicalCharts: true
    ]
    
    @Query(FetchDescriptor<Instance>.dummy) private var instances: [Instance]
    
    var category: Category
    
    init(category: Category) {
        self.category = category
        
        let calendar = Calendar.current
        let endOfToday = calendar.dateInterval(of: .day, for: .now)!.end
        let includeCount = 14
        let startOfPeriod = calendar.date(byAdding: .day, value: -includeCount - 1, to: endOfToday)!
        self._instances = Query(FetchDescriptor<Instance>(
            predicate: #Predicate { instance in
                instance.start > startOfPeriod &&
                instance.start < endOfToday
            }
        ))
    }
    
    var body: some View {
        VStack(alignment: .center) {
            ScrollView {
                DisclosureGroup(DisclosureGroupName.historicalStats.rawValue, isExpanded: self[.historicalStats]) {
                    HistoricalStats(category: category)
                }
                DisclosureGroup(DisclosureGroupName.historicalCharts.rawValue, isExpanded: self[.historicalCharts]) {
                    HistoricalChart(category: category, instances: instances)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            handleOnAppear()
        }
        .onChange(of: disclosureGroupStates) {
            let jsonData = try! JSONEncoder().encode(disclosureGroupStates)
            UserDefaults.standard.set(jsonData, forKey: "disclosureGroupStates")
        }
    }
    
    private func handleOnAppear() {
        restoreDisclosureGroupStats()
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
        case historicalStats = "Stats"
        case historicalCharts = "Charts"
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

fileprivate struct CategoryInspectorWrapper: View {
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
