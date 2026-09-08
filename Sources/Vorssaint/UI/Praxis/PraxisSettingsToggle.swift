// SPDX-License-Identifier: GPL-3.0-or-later
// Vendored/adapted from PraxisUI PraxisSettingsToggle (no InfoHelp dependency).

import SwiftUI

/// Button-styled ON/OFF toggle for settings forms (tinted when active, grey when idle).
struct PraxisSettingsToggle: View {
    let label: String
    var note: String? = nil
    var icon: String? = nil
    var compact: Bool = false
    /// Center icon + label as a unit inside the chip.
    var centered: Bool = false
    /// Feature accent when on.
    var accent: Color? = nil
    /// Hug the label width instead of stretching to the row. Prefer setting
    /// this via `PraxisToggleGrid` / `praxisToggleFitContent` environment.
    var fitContent: Bool = false
    @Binding var isOn: Bool
    @Environment(\.praxisToggleFitContent) private var fitContentFromEnvironment
    @State private var isHovered = false

    private var hugsContent: Bool { fitContent || fitContentFromEnvironment }
    private var onTint: Color { accent ?? Color(nsColor: .systemGreen) }
    private var buttonHeight: CGFloat { compact ? 28 : 36 }
    private var leadingPadding: CGFloat { compact ? 8 : 12 }
    private var trailingPadding: CGFloat { compact ? 8 : 12 }

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 3) {
            if centered {
                centeredChip
            } else {
                leadingButton
            }

            if let note {
                Text(note)
                    .font(.system(size: PraxisFont.label))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(centered ? .center : .leading)
                    .frame(maxWidth: hugsContent ? nil : .infinity,
                           alignment: centered ? .center : .leading)
                    .fixedSize(horizontal: hugsContent, vertical: false)
                    .padding(.leading, centered ? 0 : (icon != nil ? 32 : 12))
            }
        }
        .fixedSize(horizontal: hugsContent, vertical: false)
    }

    private var leadingButton: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: compact ? 6 : 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: PraxisFont.title, weight: .medium))
                        .foregroundStyle(isOn ? onTint : Color.secondary)
                        .frame(width: 18, height: 18)
                }
                Text(label)
                    .font(.system(size: PraxisFont.headline, weight: .semibold))
                    .foregroundStyle(isOn ? onTint : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(hugsContent ? 1 : 0.8)
                    .fixedSize(horizontal: hugsContent, vertical: false)
                    .frame(maxWidth: hugsContent ? nil : .infinity, alignment: .leading)
            }
            .padding(.leading, leadingPadding)
            .padding(.trailing, trailingPadding)
            .frame(height: buttonHeight)
            .frame(maxWidth: hugsContent ? nil : .infinity)
            .background(chipBackground, in: RoundedRectangle(cornerRadius: PraxisRadius.control, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: PraxisRadius.control))
            .overlay { chipBorder }
        }
        .buttonStyle(.plain)
        .praxisNoFocusRing()
        .onHover(perform: setHovered)
        .animation(.snappy(duration: 0.15), value: isOn)
    }

    private var centeredChip: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: compact ? 5 : 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: PraxisFont.title, weight: .medium))
                        .foregroundStyle(isOn ? onTint : Color.secondary)
                        .frame(width: 18, height: 18)
                }
                Text(label)
                    .font(.system(size: PraxisFont.headline, weight: .semibold))
                    .foregroundStyle(isOn ? onTint : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(hugsContent ? 1 : 0.7)
                    .fixedSize(horizontal: hugsContent, vertical: false)
            }
            .padding(.horizontal, leadingPadding)
            .frame(height: buttonHeight)
            .frame(maxWidth: hugsContent ? nil : .infinity)
            .background(chipBackground, in: RoundedRectangle(cornerRadius: PraxisRadius.control, style: .continuous))
            .overlay { chipBorder }
        }
        .buttonStyle(.plain)
        .praxisNoFocusRing()
        .onHover(perform: setHovered)
        .animation(.snappy(duration: 0.15), value: isOn)
    }

    private var chipBackground: Color {
        if isOn { return onTint.opacity(0.12) }
        return isHovered ? Color.primary.opacity(0.04) : Color.primary.opacity(0.02)
    }

    private var chipBorder: some View {
        RoundedRectangle(cornerRadius: PraxisRadius.control, style: .continuous)
            .strokeBorder(
                isOn ? onTint.opacity(0.35) : Color.primary.opacity(0.08),
                lineWidth: 1
            )
    }

    private func setHovered(_ hovering: Bool) {
        withAnimation(.easeOut(duration: 0.15)) {
            isHovered = hovering
        }
    }
}
