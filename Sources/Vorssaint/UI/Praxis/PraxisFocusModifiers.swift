// SPDX-License-Identifier: GPL-3.0-or-later
// Vendored from PraxisUI (focus helpers) + fork-wide focus chrome kill.

import SwiftUI

extension View {
    /// Suppress the default macOS blue focus ring on buttons/menus.
    @ViewBuilder
    func praxisNoFocusRing() -> some View {
        if #available(macOS 14.0, *) {
            self.focusEffectDisabled()
        } else {
            self
        }
    }

    /// Apply at panel/window roots so nested controls don't show the system
    /// accent focus outline (the blue rounded border around clicked buttons).
    func vorssaintNoFocusChrome() -> some View {
        praxisNoFocusRing()
    }
}
