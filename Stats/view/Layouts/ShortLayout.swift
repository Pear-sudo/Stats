//
//  ShortLayout.swift
//  Stats
//
//  Created by A on 31/08/2024.
//

import SwiftUI

struct ShortLayout: Layout {
    
    var anchor: Int = -1
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        let spacing = spacing(subviews: subviews)

        let maxHeight = getMaxHeight(subviews: subviews, anchor: anchor)
        let totalWidth = widths(proposal: proposal, subviews: subviews, spacing: spacing, maxHeight: maxHeight).1 // spacing is included
        
        return CGSize(
            width: totalWidth,
            height: maxHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        let maxHeight = getMaxHeight(subviews: subviews, anchor: anchor)
        let spacing = spacing(subviews: subviews)
        let widths = widths(proposal: proposal, subviews: subviews, spacing: spacing, maxHeight: maxHeight).0

        var nextX: CGFloat = bounds.minX

        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(x: nextX, y: bounds.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: widths[index], height: maxHeight))
            nextX += widths[index] + spacing[index]
        }
    }
    
    private func getMaxHeight(subviews: Subviews, anchor: Int) -> Double {
        var anchor = anchor
        if anchor < 0 {
            anchor = subviews.count + anchor
        }
        if anchor < subviews.startIndex || anchor > subviews.endIndex {
            anchor = subviews.endIndex
        }
        
        return subviews[anchor].sizeThatFits(.unspecified).height
    }
    
    /// Gets an array of preferred spacing sizes between subviews in the
    /// horizontal dimension.
    private func spacing(subviews: Subviews) -> [CGFloat] {
        subviews.indices.map { index in
            guard index < subviews.count - 1 else { return 0 }
            return subviews[index].spacing.distance(
                to: subviews[index + 1].spacing,
                along: .horizontal)
        }
    }
    
    private func widths(proposal: ProposedViewSize, subviews: Subviews, spacing: [CGFloat], maxHeight: CGFloat) -> ([CGFloat], CGFloat) {
        var totalWidth: CGFloat = 0
        return (subviews.indices.map { index in
            let width = subviews[index].sizeThatFits(.init(width: minus(proposal.width, totalWidth), height: maxHeight)).width
            totalWidth = totalWidth + width + spacing[index]
            return width
        }, totalWidth)
    }
    
    @inline(__always)
    private func minus(_ x: CGFloat?, _ y: CGFloat?) -> CGFloat? {
        if x == nil || y == nil {
            return nil
        }
        return x! - y!
    }
}
