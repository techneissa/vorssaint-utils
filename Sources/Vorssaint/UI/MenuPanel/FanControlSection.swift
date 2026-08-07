// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Beta entry point for fan control. It is intentionally informational for now:
/// writing fan curves safely needs model-by-model validation before controls are
/// enabled in a public build.
struct FanControlSection: View {
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.colorScheme) private var colorScheme
    var collapsible = true

    var body: some View {
        PanelSection(.fanControl, title: l10n.s.fanControlBetaSection, collapsible: collapsible) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "fanblades.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PanelMetricColor.cyan(for: colorScheme))
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text(l10n.s.fanControlBetaTitle)
                                .font(.system(size: 12, weight: .semibold))
                            Text(l10n.s.betaBadge)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(PanelMetricColor.cyan(for: colorScheme).opacity(0.16)))
                                .foregroundStyle(PanelMetricColor.cyan(for: colorScheme))
                        }
                        Text(l10n.s.fanControlBetaStatus)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Custom chips — system `.segmented` + `.disabled` washes out the
                // selected label to near-invisible on dark surfaces.
                HStack(spacing: 6) {
                    fanModeChip(title: l10n.s.fanControlModeAutomatic, selected: true)
                    fanModeChip(title: l10n.s.fanControlModeManual, selected: false)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(l10n.s.fanControlBetaTitle)

                Text(l10n.s.fanControlBetaCaption)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .panelCard()
        }
    }

    private func fanModeChip(title: String, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(selected ? Color.primary : Color.secondary.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: PraxisRadius.control, style: .continuous)
                    .fill(selected ? Color.primary.opacity(0.12) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: PraxisRadius.control, style: .continuous)
                    .strokeBorder(
                        selected ? Color.primary.opacity(0.18) : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .opacity(selected ? 1 : 0.85)
    }
}
