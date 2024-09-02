//
//  TodayInstanceStats.swift
//  Stats
//
//  Created by A on 02/09/2024.
//

import SwiftUI
import Foundation

struct TodayInstanceStats: View {
    var instances: [Instance]
    
    var body: some View {
        HStack {
            TextPair("N", instances.count)
            TextPair("Max", max)
            TextPair("Min", min)
            TextPair("Mean", counts.mean())
            TextPair("Std", counts.std())
        }
    }
    
    private var max: Int {
        instances.reduce(0, {Swift.max($0, $1.count)})
    }
    
    private var min: Int {
        instances.isEmpty ? 0 : instances.reduce(Int.max, {Swift.min($0, $1.count)})
    }
    
    private var counts: [Int] {
        instances.map(\.count)
    }
}

fileprivate struct TextPair: View {
    let title: String
    let value: String
    init<T: BinaryInteger>(_ title: String, _ value: T) {
        self.title = title
        self.value = String(value)
    }
    init(_ title: String, _ value: Double) {
        self.title = title
        self.value = value.formatted(.number.precision(.fractionLength(1)))
    }
    var body: some View {
        Text("\(title) ")
            .foregroundStyle(.tertiary) +
        Text(value)
    }
}
