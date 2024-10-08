//
//  ContentView.swift
//  Stats
//
//  Created by A on 30/08/2024.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Query private var categories: [Category]
    
    @AppStorage("inspectorIsPresented") private var inspectorIsPresented = true
    @AppStorage("inspectorIdealWidth") private var inspectorIdealWidth = 200
    
    @State private var newCategorySheetIsShown = false
    @State private var selections = Set<PersistentIdentifier>()
    @State private var cancellable: AnyCancellable? = nil
    @State private var inspectorIsRestored = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openSettings) private var openSettings
    @Environment(\.commands) private var commands
    
    private let widthSubject = PassthroughSubject<CGFloat, Never>()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selections) {
                ForEach(categories, id: \.persistentModelID) { category in
                    Text(category.name)
                }
                .onDelete(perform: deleteCategories)
            }
            .onDisappear {
                saveSelectedCategories()
            }
            .onAppear {
                guard let selected = try? modelContext.fetch(FetchDescriptor<SelectedCategory>()) else {
                    return
                }
                let newSelections = Set(selected.map({$0.category.persistentModelID}))
                selections = newSelections
            }
            .onAppear {
                cancellable = NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
                    .sink { notification in
                        defer {
                            cancellable?.cancel()
                        }
                        saveSelectedCategories()
                    }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if selections.count == 1 {
                detail
                    .navigationTitle((modelContext.model(for: selections.first!) as! Category).name)
                    .inspector(isPresented: $inspectorIsPresented) {
                        CategoryInspector(category: modelContext.model(for: selections.first!) as! Category)
                            .inspectorColumnWidth(min: inspectorIsRestored ? 100 : CGFloat(inspectorIdealWidth), ideal: CGFloat(inspectorIdealWidth), max: 300)
                            .background {
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            setupWidthSubscriber()
                                        }
                                        .onChange(of: geometry.size) {
                                            if geometry.size.width < CGFloat(inspectorIdealWidth) && !inspectorIsRestored {
                                                return
                                            }
                                            inspectorIsRestored = true
                                            widthSubject.send(geometry.size.width)
                                        }
                                        .onDisappear {
                                            cancellable?.cancel()
                                            cancellable = nil
                                        }
                                }
                            }
                    }
            } else {
                detail
            }
        }
        .onReceive(commands, perform: { command in
            switch command {
            case .toggleNavigation:
                if columnVisibility == .detailOnly {
                    columnVisibility = .doubleColumn
                } else {
                    columnVisibility = .detailOnly
                }
            default:
                break
            }
        })
        .onChange(of: columnVisibility, {
            guard let data = try? JSONEncoder().encode(columnVisibility) else {
                return
            }
            UserDefaults.standard.set(data, forKey: "columnVisibility")
        })
        .onAppear {
            guard let data = UserDefaults.standard.data(forKey: "columnVisibility"),
                  let visibility = try? JSONDecoder().decode(NavigationSplitViewVisibility.self, from: data) else {
                return
            }
            if columnVisibility !=  visibility {
                columnVisibility = visibility
            }
        }
        .toolbar {
            Button("Show Inspector", systemImage: "info.circle") {
                inspectorIsPresented.toggle()
            }
            .disabled(selections.count != 1)
        }
        .sheet(isPresented: $newCategorySheetIsShown) {
            NewCategorySheet()
        }
        .onDeleteCommand(perform: deleteCategories)
    }
    
    private func saveSelectedCategories() {
        try? modelContext.delete(model: SelectedCategory.self)
        for selection in selections {
            let category = modelContext.model(for: selection) as! Category
            let selected = SelectedCategory(category: category)
            modelContext.insert(selected)
        }
        try? modelContext.save()
    }
    
    @ViewBuilder
    private var detail: some View {
        if categories.isEmpty {
            Text("Create a category")
        } else if selections.isEmpty {
            Text("Select a category")
        } else if selections.count == 1 {
            CategoryView(category: modelContext.model(for: selections.first!) as! Category)
        } else {
            Text("\(selections.count) categories selected")
        }
    }
    
    private func setupWidthSubscriber() {
        cancellable = widthSubject
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { newWidth in
                inspectorIdealWidth = Int(newWidth)
            }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(categories[offset])
        }
    }
    
    private func deleteCategories() {
        for id in selections {
            let model = modelContext.model(for: id)
            modelContext.delete(model)
        }
        selections.removeAll()
    }

    private func addItem() {
        newCategorySheetIsShown = true
    }
}

struct NewCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State var text: String = ""
    
    var body: some View {
        TextField("Name", text: $text)
            .onSubmit {
                submit()
            }
            .frame(idealWidth: 100)
            .padding()
    }
    
    private func submit() {
        let newCategory = Category(name: text)
        modelContext.insert(newCategory)
        dismiss()
    }
}

#Preview {
    NewCategorySheet()
}

#Preview {
    ContentView()
        .modelContainer(for: models, inMemory: false)
}
