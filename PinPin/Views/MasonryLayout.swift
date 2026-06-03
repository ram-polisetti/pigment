import SwiftUI

struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard columns > 1, let width = proposal.width else {
            return singleColumnSize(proposal: proposal, subviews: subviews)
        }

        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var columnHeights = Array(repeating: CGFloat(0), count: columns)

        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            let shortest = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            columnHeights[shortest] += size.height + spacing
        }

        let totalHeight = columnHeights.max() ?? 0
        return CGSize(width: width, height: max(totalHeight - spacing, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard columns > 1, bounds.width > 0 else {
            placeSingleColumn(in: bounds, subviews: subviews)
            return
        }

        let columnWidth = (bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var columnHeights = Array(repeating: CGFloat(0), count: columns)

        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            let column = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset

            let x = bounds.minX + (columnWidth + spacing) * CGFloat(column)
            let y = bounds.minY + columnHeights[column]

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: .init(width: columnWidth, height: size.height)
            )

            columnHeights[column] += size.height + spacing
        }
    }

    private func singleColumnSize(proposal: ProposedViewSize, subviews: Subviews) -> CGSize {
        var totalHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: proposal.width, height: nil))
            totalHeight += size.height + spacing
        }
        return CGSize(width: proposal.width ?? 0, height: max(totalHeight - spacing, 0))
    }

    private func placeSingleColumn(in bounds: CGRect, subviews: Subviews) {
        var y = bounds.minY
        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: bounds.width, height: nil))
            subview.place(at: CGPoint(x: bounds.minX, y: y), proposal: .init(width: bounds.width, height: size.height))
            y += size.height + spacing
        }
    }
}
