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
    SelectedCategory.self,
]

var sharedModelContainer: ModelContainer = {
    let schema = Schema(models)
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

var sharedModelContest: ModelContext = ModelContext(sharedModelContainer)

@main
struct StatsApp: App {
    private var commandSubject: CommandSubject = .init()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\EnvironmentValues.commands, commandSubject)
        }
        .commands(content: {
            CommandMenu("Control") {
                Button("Start") {
                    commandSubject.send(.start)
                }
                .keyboardShortcut("s", modifiers: .command)
                Button("Enter") {
                    commandSubject.send(.enter)
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
        })
        .modelContainer(sharedModelContainer)
        
        Settings {
            BackupInfo()
        }
        .modelContainer(sharedModelContainer)
    }
}
