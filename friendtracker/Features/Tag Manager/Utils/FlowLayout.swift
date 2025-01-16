/// `FlowLayout` is a custom SwiftUI layout that arranges its child views
/// in a horizontal flow. It wraps to a new row when the current row runs out of space.
///
/// This is useful for displaying items like tags or buttons in a compact,
/// flexible way.
///
/// - Parameters:
///   - spacing: The space between items in the flow.
///   - alignment: The vertical alignment of items within a row (default: `.center`).
///   - content: A `ViewBuilder` closure that provides the views to be arranged.
///
/// Example:
/// ```swift
/// FlowLayout(spacing: 8) {
///     ForEach(tags) { tag in
///         Text(tag.name)
///             .padding(4)
///             .background(Color.gray.opacity(0.2))
///             .cornerRadius(4)
///     }
/// }

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > width {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            height = y + maxHeight
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            view.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
} 
