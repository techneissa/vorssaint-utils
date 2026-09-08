// SPDX-License-Identifier: GPL-3.0-or-later
// Vendored/adapted from PraxisUI PraxisFlowLayout.

import SwiftUI

/// Left-to-right wrapping layout. Subviews keep their intrinsic width, so
/// Praxis toggle chips never shrink into truncated labels; the row count
/// becomes 1, 2, or 3+ based on available width.
struct PraxisFlowLayout: Layout {
    var hSpacing: CGFloat
    var vSpacing: CGFloat
    /// When true, the layout reports the full proposed width (Form rows).
    var fillsWidth: Bool = false

    init(hSpacing: CGFloat, vSpacing: CGFloat, fillsWidth: Bool = false) {
        self.hSpacing = hSpacing
        self.vSpacing = vSpacing
        self.fillsWidth = fillsWidth
    }

    init(spacing: CGFloat, fillsWidth: Bool = false) {
        self.init(hSpacing: spacing, vSpacing: spacing, fillsWidth: fillsWidth)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var trailingX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + vSpacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + hSpacing
            trailingX = max(trailingX, x - hSpacing)
        }

        let height = y + rowHeight
        let width: CGFloat
        if fillsWidth {
            width = maxWidth.isFinite ? maxWidth : (frames.map(\.maxX).max() ?? 0)
        } else {
            width = trailingX
        }
        return (CGSize(width: width, height: height), frames)
    }
}

private struct PraxisToggleFitContentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// When true, `PraxisSettingsToggle` hugs its label instead of stretching.
    var praxisToggleFitContent: Bool {
        get { self[PraxisToggleFitContentKey.self] }
        set { self[PraxisToggleFitContentKey.self] = newValue }
    }
}

/// Wraps Praxis settings toggles into a responsive wrap row (typically 2–3
/// chips wide). Children keep intrinsic label width so text is not truncated.
struct PraxisToggleGrid<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        PraxisFlowLayout(hSpacing: spacing, vSpacing: spacing, fillsWidth: true) {
            content()
        }
        .environment(\.praxisToggleFitContent, true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
