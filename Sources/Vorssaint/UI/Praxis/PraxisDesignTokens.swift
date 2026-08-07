// SPDX-License-Identifier: GPL-3.0-or-later
// Vendored from PraxisUI for the SpaciousTech custom-ui fork (conflict-minimizing).

import CoreGraphics
import SwiftUI

/// Corner-radius scale (identical to PraxisUI tokens).
enum PraxisRadius {
    static let chip: CGFloat = 4
    static let field: CGFloat = 5
    static let control: CGFloat = 6
    static let card: CGFloat = 8
    static let panel: CGFloat = 10
}

/// Font-size scale (identical to PraxisUI tokens).
enum PraxisFont {
    static let micro: CGFloat = 8
    static let tag: CGFloat = 9
    static let label: CGFloat = 10
    static let body: CGFloat = 11
    static let headline: CGFloat = 12
    static let title: CGFloat = 13
}

extension Font {
    static func praxis(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func praxisMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
