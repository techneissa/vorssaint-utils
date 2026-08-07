// SPDX-License-Identifier: GPL-3.0-or-later
// Vendored/adapted from PraxisUI PraxisButton (no InfoHelp dependency).

import SwiftUI

enum PraxisButtonRole: Equatable {
    case primary
    case secondary
    case destructive
    case ghost
}

enum PraxisButtonSize {
    case mini, small, regular, large

    var font: Font {
        switch self {
        case .mini: return .system(size: PraxisFont.label, weight: .semibold)
        case .small: return .system(size: PraxisFont.body, weight: .semibold)
        case .regular: return .system(size: PraxisFont.headline, weight: .semibold)
        case .large: return .system(size: PraxisFont.title, weight: .semibold)
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .mini: return 9
        case .small: return 10
        case .regular: return 11
        case .large: return 14
        }
    }

    var hPadding: CGFloat {
        switch self {
        case .mini: return 7
        case .small, .regular, .large: return 10
        }
    }

    var vPadding: CGFloat {
        switch self {
        case .mini: return 4
        case .small, .regular, .large: return 5
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .mini: return 5
        case .small: return 6
        case .regular: return 7
        case .large: return 8
        }
    }

    var iconSpacing: CGFloat {
        switch self {
        case .mini: return 4
        case .small, .regular: return 5
        case .large: return 6
        }
    }
}

/// Tinted chip button with hover lift (Praxis look).
struct PraxisButton: View {
    let title: String
    var icon: String? = nil
    var role: PraxisButtonRole = .secondary
    var size: PraxisButtonSize = .small
    var tint: Color? = nil
    var width: CGFloat? = nil
    var fillWidth: Bool = false
    var help: String? = nil
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    init(
        _ title: String,
        icon: String? = nil,
        role: PraxisButtonRole = .secondary,
        size: PraxisButtonSize = .small,
        tint: Color? = nil,
        width: CGFloat? = nil,
        fillWidth: Bool = false,
        help: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.role = role
        self.size = size
        self.tint = tint
        self.width = width
        self.fillWidth = fillWidth
        self.help = help
        self.action = action
    }

    private var resolvedTint: Color {
        switch role {
        case .primary: return tint ?? .accentColor
        case .secondary: return tint ?? .orange
        case .destructive: return .red
        case .ghost: return tint ?? .secondary
        }
    }

    private var isGhost: Bool { role == .ghost }
    private var isPrimary: Bool { role == .primary }
    private var isActive: Bool { isHovered && isEnabled }

    private var foreground: Color {
        guard isEnabled else { return resolvedTint.opacity(0.4) }
        if isGhost { return isActive ? .primary : .secondary }
        if isPrimary { return resolvedTint }
        return resolvedTint.opacity(isActive ? 1 : 0.88)
    }

    private var background: Color {
        guard isEnabled else { return resolvedTint.opacity(0.06) }
        if isGhost { return isActive ? Color.primary.opacity(0.06) : .clear }
        if isPrimary { return resolvedTint.opacity(isActive ? 0.20 : 0.14) }
        return resolvedTint.opacity(isActive ? 0.18 : 0.10)
    }

    private var border: Color {
        guard isEnabled else { return resolvedTint.opacity(0.20) }
        if isGhost { return isActive ? Color.primary.opacity(0.12) : .clear }
        if isPrimary { return resolvedTint.opacity(isActive ? 0.50 : 0.38) }
        return resolvedTint.opacity(isActive ? 0.42 : 0.22)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: size.iconSpacing) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }
                Text(title)
                    .lineLimit(1)
            }
            .font(size.font)
            .foregroundStyle(foreground)
            .frame(width: width)
            .padding(.horizontal, size.hPadding)
            .padding(.vertical, size.vPadding)
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .background(
                background,
                in: RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .praxisNoFocusRing()
        .onHover { hovering in
            if isEnabled {
                isHovered = hovering
            } else {
                isHovered = false
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isActive)
        .help(help ?? title)
    }
}
