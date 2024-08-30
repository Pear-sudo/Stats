//
//  Category.swift
//  Stats
//
//  Created by A on 30/08/2024.
//

import Foundation
import SwiftData

@Model
final class Category: Identifiable {
    init(name: String) {
        self.name = name
    }
    @Attribute(.unique)
    var name: String
    
    var id: PersistentIdentifier {
        persistentModelID
    }
}
