//
//  Instance.swift
//  Stats
//
//  Created by A on 30/08/2024.
//

import SwiftData
import Foundation

@Model
final class Instance: Identifiable {
    
    init(start: Date = .now, end: Date = .now, count: Int = 0, category: Category) {
        self.start = start
        self.end = end
        self.count = count
        self.category = category
    }
    
    init(count: Int = 0, category: Category) {
        self.count = count
        self.category = category
    }
    
    var start: Date = Date.now
    var end: Date = Date.now
    var count: Int = 0
    @Relationship(deleteRule: .noAction)
    var category: Category
    
    var id: PersistentIdentifier {
        persistentModelID
    }
}

extension Instance {
    var duration: Duration {
        .seconds(end.timeIntervalSince(start))
    }
}
