//
//  CategoryView.swift
//  Stats
//
//  Created by A on 02/09/2024.
//


import SwiftUI
import SwiftData

struct CategoryView: View {
    var category: Category
    var body: some View {
        VStack {
            CategoryInput(category: category)
            Divider()
            HistoryInstance(category: category)
        }
        .padding()
    }
}

#Preview {
    CategoryView(category: Category(name: "push-up"))
        .modelContainer(for: models, inMemory: false)
}
