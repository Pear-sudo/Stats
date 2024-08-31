//
//  SelectedCategory.swift
//  Stats
//
//  Created by A on 31/08/2024.
//

import Foundation
import SwiftData

@Model
class SelectedCategory {
    internal init(category: Category) {
        self.category = category
    }
    
    @Relationship
    var category: Category
}
