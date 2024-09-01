//
//  FetchDescriptor.swift
//  Stats
//
//  Created by A on 01/09/2024.
//

import Foundation
import SwiftData

extension FetchDescriptor {
    func fetchLimit(_ limit: Int?) -> FetchDescriptor {
        var copy = self
        copy.fetchLimit = limit
        return copy
    }
}

extension FetchDescriptor {
    static var dummy: Self {
        Self.init().fetchLimit(0)
    }
}
