// SPDX-License-Identifier: GPL-3.0-or-later
// Vendored from PraxisUI (focus helpers only).

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
}
