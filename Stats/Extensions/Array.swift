//
//  Array.swift
//  Stats
//
//  Created by A on 02/09/2024.
//

import Foundation

extension Array where Element: BinaryInteger {
    func mean() -> Double {
        guard !self.isEmpty else { return 0 }
        let sum = self.reduce(Element(0), +)
        return Double(sum) / Double(self.count)
    }
    
    func std() -> Double {
        guard !self.isEmpty else { return 0 }
        let avg = self.mean()
        let sumOfSquaredAvgDiff = self.map { Double($0) - avg }.map { $0 * $0 }.reduce(0, +)
        return (sumOfSquaredAvgDiff / Double(self.count)).squareRoot()
    }
}
