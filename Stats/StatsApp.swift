//
//  StatsApp.swift
//  Stats
//
//  Created by A on 30/08/2024.
//

import SwiftUI
import SwiftData

let models: [any PersistentModel.Type] = [
    Category.self,
    Instance.self,
]

@main
struct StatsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
