// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Reusable panel configuration: one expandable block per panel section, each
/// with a master "show in panel" toggle plus per-item toggles. Shared by
/// Settings → Monitor and the onboarding panel step so the two stay identical.
/// Designed to live inside a `Form` (grouped style) in both places.
struct MonitorPanelConfig: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var expandedBlocks = Set<PanelConfigBlock>()

    @AppStorage(DefaultsKey.monitorShowSystem) private var showSystem = true
    @AppStorage(DefaultsKey.monitorSysTemps) private var sysTemps = true
    @AppStorage(DefaultsKey.monitorSysCPU) private var sysCPU = true
    @AppStorage(DefaultsKey.monitorSysGPU) private var sysGPU = true
    @AppStorage(DefaultsKey.monitorPwrTemperature) private var pwrTemperature = true
    @AppStorage(DefaultsKey.monitorSysBattery) private var sysBattery = true
    @AppStorage(DefaultsKey.monitorSysMemory) private var sysMemory = true
    @AppStorage(DefaultsKey.monitorSysUptime) private var sysUptime = true

    @AppStorage(DefaultsKey.monitorShowNetwork) private var showNetwork = true
    @AppStorage(DefaultsKey.monitorNetSpeed) private var netSpeed = true
    @AppStorage(DefaultsKey.monitorNetApps) private var netApps = true
    @AppStorage(DefaultsKey.monitorNetTotals) private var netTotals = true
    @AppStorage(DefaultsKey.monitorNetTest) private var netTest = true

    @AppStorage(DefaultsKey.monitorShowDisk) private var showDisk = true
    @AppStorage(DefaultsKey.monitorDiskUsage) private var diskUsage = true
    @AppStorage(DefaultsKey.monitorDiskActivity) private var diskActivity = true
    @AppStorage(DefaultsKey.monitorDiskSMART) private var diskSMART = true
    @AppStorage(DefaultsKey.monitorDiskProtection) private var diskProtection = true
    @AppStorage(DefaultsKey.monitorDiskTools) private var diskTools = true

    @AppStorage(DefaultsKey.monitorShowPower) private var showPower = true
    @AppStorage(DefaultsKey.monitorPwrSystem) private var pwrSystem = true
    @AppStorage(DefaultsKey.monitorPwrAdapter) private var pwrAdapter = true
    @AppStorage(DefaultsKey.monitorPwrBattery) private var pwrBattery = true
    @AppStorage(DefaultsKey.monitorPwrTimeRemaining) private var pwrTimeRemaining = true
    @AppStorage(DefaultsKey.monitorPwrHealth) private var pwrHealth = true

    @AppStorage(DefaultsKey.monitorShowMixer) private var showMixer = true

    var body: some View {
        if PanelSectionID.system.isAvailable {
            block(.system, title: l10n.s.systemSection, master: $showSystem) {
                if AppFeature.monitorCPU.isAvailable || AppFeature.monitorGPU.isAvailable {
                    PraxisSettingsToggle(label: l10n.s.temperatures, isOn: $sysTemps)
                }
                if AppFeature.monitorCPU.isAvailable {
                    PraxisSettingsToggle(label: l10n.s.cpuLabel, isOn: $sysCPU)
                }
                if AppFeature.monitorGPU.isAvailable {
                    PraxisSettingsToggle(label: l10n.s.gpuLabel, isOn: $sysGPU)
                }
                if AppFeature.monitorMemory.isAvailable {
                    PraxisSettingsToggle(label: l10n.s.memorySection, isOn: $sysMemory)
                }
                PraxisSettingsToggle(label: l10n.s.monitorItemUptime, isOn: $sysUptime)
            }
        }
        if AppFeature.monitorNetwork.isAvailable {
            block(.network, title: l10n.s.networkSection, master: $showNetwork) {
                PraxisSettingsToggle(label: l10n.s.monitorItemNetSpeed, isOn: $netSpeed)
                PraxisSettingsToggle(label: l10n.s.networkApps, isOn: $netApps)
                PraxisSettingsToggle(label: l10n.s.monitorItemNetTotals, isOn: $netTotals)
                PraxisSettingsToggle(label: l10n.s.monitorItemNetTest, isOn: $netTest)
            }
        }
        if AppFeature.monitorDisk.isAvailable {
            block(.disk, title: l10n.s.diskSection, master: $showDisk) {
                PraxisSettingsToggle(label: l10n.s.monitorItemDiskUsage, isOn: $diskUsage)
                PraxisSettingsToggle(label: l10n.s.monitorItemDiskActivity, isOn: $diskActivity)
                PraxisSettingsToggle(label: l10n.s.monitorItemDiskSMART, isOn: $diskSMART)
                PraxisSettingsToggle(label: l10n.s.monitorItemDiskProtection, isOn: $diskProtection)
                PraxisSettingsToggle(label: l10n.s.monitorItemDiskTools, isOn: $diskTools)
            }
        }
        if AppFeature.monitorPower.isAvailable {
            block(.power, title: l10n.s.powerSection, master: $showPower) {
                PraxisSettingsToggle(label: l10n.s.powerSystem, isOn: $pwrSystem)
                PraxisSettingsToggle(label: l10n.s.powerAdapter, isOn: $pwrAdapter)
                if PowerSampler.hasInternalBattery {
                    PraxisSettingsToggle(label: l10n.s.batteryCharge, isOn: $sysBattery)
                    PraxisSettingsToggle(label: l10n.s.powerBattery, isOn: $pwrBattery)
                    PraxisSettingsToggle(label: FeatureStrings.batteryTime(l10n.language).title, isOn: $pwrTimeRemaining)
                    DisclosureGroup(FeatureStrings.mouseClickDebounce(l10n.language).moreOptions) {
                        PraxisSettingsToggle(label: l10n.s.monitorShowBatteryTemperature, isOn: $pwrTemperature)
                        PraxisSettingsToggle(label: l10n.s.powerHealth, isOn: $pwrHealth)
                    }
                }
            }
        }
        // The mixer is a per-app list, so it has no sub-items — just show/hide.
        if AppFeature.mixer.isAvailable {
            PraxisSettingsToggle(label: l10n.s.mixerSection, isOn: $showMixer)
        }
    }

    /// One expandable section: a master "show in panel" toggle, then the per-item
    /// toggles (disabled while the whole block is hidden).
    @ViewBuilder
    private func block<Content: View>(_ id: PanelConfigBlock,
                                      title: String,
                                      master: Binding<Bool>,
                                      @ViewBuilder _ items: @escaping () -> Content) -> some View {
        DisclosureHeaderRow(isExpanded: expansionBinding(for: id)) {
            Text(title)
            Spacer()
        }
        if expandedBlocks.contains(id) {
            PraxisToggleGrid {
                PraxisSettingsToggle(label: l10n.s.monitorShowInPanel, isOn: master)
                Group {
                    items()
                }
                .disabled(!master.wrappedValue)
            }
            .disclosureIndent()
        }
    }

    private func expansionBinding(for id: PanelConfigBlock) -> Binding<Bool> {
        Binding(
            get: { expandedBlocks.contains(id) },
            set: { expanded in
                if expanded {
                    expandedBlocks.insert(id)
                } else {
                    expandedBlocks.remove(id)
                }
            }
        )
    }

}

private enum PanelConfigBlock: Hashable {
    case system, network, disk, power
}
