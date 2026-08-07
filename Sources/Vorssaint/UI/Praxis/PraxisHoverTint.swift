// SPDX-License-Identifier: GPL-3.0-or-later
// Fork-owned hover chrome for panel/settings controls.

import SwiftUI

/// Subtle primary-tint fill while the pointer is over a control.
struct PraxisHoverTintModifier: ViewModifier {
    var cornerRadius: CGFloat = PraxisRadius.control
    var idleOpacity: Double = 0
    var hoverOpacity: Double = 0.08
    var selected: Bool = false
    var selectedOpacity: Double = 0.14

    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(selected ? selectedOpacity : idleOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(hovering && !selected ? hoverOpacity : 0))
                    .allowsHitTesting(false)
            )
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

extension View {
    /// Neutral hover / selection tint (no system-accent blue).
    func praxisHoverTint(
        cornerRadius: CGFloat = PraxisRadius.control,
        idleOpacity: Double = 0,
        hoverOpacity: Double = 0.08,
        selected: Bool = false,
        selectedOpacity: Double = 0.14
    ) -> some View {
        modifier(PraxisHoverTintModifier(
            cornerRadius: cornerRadius,
            idleOpacity: idleOpacity,
            hoverOpacity: hoverOpacity,
            selected: selected,
            selectedOpacity: selectedOpacity
        ))
    }
}
