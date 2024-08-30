//
//  ContentView.swift
//  Stats
//
//  Created by A on 30/08/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var newCategorySheetIsShown = false
    @State private var selections = Set<PersistentIdentifier>()

    var body: some View {
        NavigationSplitView {
            List(selection: $selections) {
                ForEach(categories, id: \.persistentModelID) { category in
                    Text(category.name)
                }
                .onDelete(perform: deleteCategories)
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
            if categories.isEmpty {
                Text("Create a category")
            } else if selections.isEmpty {
                Text("Select a category")
            } else if selections.count == 1 {
                CategoryInput(category: modelContext.model(for: selections.first!) as! Category)
            } else {
                Text("\(selections.count) categories selected")
            }
        }
        .sheet(isPresented: $newCategorySheetIsShown) {
            NewCategorySheet()
        }
        .onDeleteCommand(perform: deleteCategories)
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
