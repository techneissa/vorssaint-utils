// SPDX-License-Identifier: GPL-3.0-or-later
// Vendored/adapted from PraxisUI TextToggleButton (no InfoHelp dependency).

import SwiftUI

/// Clickable text toggle: grey when off, feature-tinted highlight when on.
struct TextToggleButton: View {
    let title: String
    @Binding var isOn: Bool
    var compact: Bool = true
    /// When true, label and fill expand to the grid cell.
    var fillsWidth: Bool = false
    var help: String? = nil
    /// Feature accent when on.
    var accent: Color? = nil
    /// Optional SF Symbol shown before the title.
    var leadingIcon: String? = nil
    /// When false, chip is non-interactive and visually muted.
    var isEnabled: Bool = true

    @State private var isHovered = false

    private var onTint: Color { accent ?? Color(nsColor: .systemGreen) }
    private var fillHeight: CGFloat { compact ? 24 : 28 }
    private var labelTint: Color {
        guard isEnabled else { return Color.secondary.opacity(0.7) }
        return isOn ? onTint : Color.secondary
    }

    var body: some View {
        Group {
            if isEnabled {
                Button {
                    isOn.toggle()
                } label: {
                    chipLabel
                }
                .buttonStyle(.plain)
                .praxisNoFocusRing()
                .onHover { isHovered = $0 }
            } else {
                chipLabel
            }
        }
        .animation(.snappy(duration: 0.15), value: isOn)
        .help(help ?? title)
    }

    private var chipLabel: some View {
        HStack(spacing: leadingIcon != nil ? 4 : 0) {
            if fillsWidth {
                Spacer(minLength: 0)
            }
            if let leadingIcon {
                Image(systemName: leadingIcon)
                    .font(.system(size: compact ? 10 : 11, weight: .semibold))
                    .foregroundStyle(labelTint)
                    .opacity(isEnabled ? 1 : 0.55)
            }
            Text(title)
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
                .foregroundStyle(labelTint)
                .lineLimit(1)
                .minimumScaleFactor(fillsWidth && compact ? 0.55 : 1)
                .fixedSize(horizontal: !fillsWidth, vertical: false)
                .opacity(isEnabled ? 1 : 0.55)
            if fillsWidth {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: fillsWidth ? .infinity : nil)
        .frame(height: fillsWidth ? fillHeight : nil)
        .padding(.horizontal, fillsWidth ? 6 : (compact ? 8 : 12))
        .padding(.vertical, fillsWidth ? 0 : (compact ? 4 : 6))
        .background(
            isEnabled
                ? (isOn
                    ? onTint.opacity(0.12)
                    : (isHovered ? Color.primary.opacity(0.04) : Color.primary.opacity(0.02)))
                : Color.primary.opacity(0.03),
            in: RoundedRectangle(cornerRadius: PraxisRadius.control, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: PraxisRadius.control, style: .continuous)
                .strokeBorder(
                    isEnabled
                        ? (isOn ? onTint.opacity(0.35) : Color.primary.opacity(0.08))
                        : Color.primary.opacity(0.06),
                    lineWidth: 1
                )
        }
    }
}
