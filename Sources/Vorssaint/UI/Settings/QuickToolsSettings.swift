// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct QuickToolsSettings: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var micMute = MicMuteService.shared
    @ObservedObject private var ocr = ScreenTextService.shared
    @ObservedObject private var colorSampler = ColorSamplerService.shared
    @ObservedObject private var launcher = QuickLauncherService.shared
    @ObservedObject private var cameraPreview = CameraPreviewService.shared
    @ObservedObject private var scratchpad = ScratchpadService.shared
    @AppStorage(DefaultsKey.quickLauncherShortcutEnabled) private var launcherShortcutEnabled = true
    @AppStorage(DefaultsKey.screenOCRShortcutEnabled) private var ocrShortcutEnabled = false
    @AppStorage(DefaultsKey.screenOCRDetectQRCodes) private var ocrDetectQRCodes = true
    @AppStorage(DefaultsKey.colorPickerShortcutEnabled) private var colorShortcutEnabled = false
    @AppStorage(DefaultsKey.micMuteShortcutEnabled) private var micShortcutEnabled = false
    @AppStorage(DefaultsKey.cameraPreviewShortcutEnabled) private var cameraShortcutEnabled = false
    @AppStorage(DefaultsKey.scratchpadShortcutEnabled) private var scratchpadShortcutEnabled = false
    @AppStorage(DefaultsKey.scratchpadRetention) private var scratchpadRetention = ScratchpadRetention.never.rawValue
    @AppStorage(DefaultsKey.scratchpadCloseOnClickOutside) private var scratchpadCloseOnClickOutside = true
    @AppStorage(DefaultsKey.scratchpadBackgroundOpacity) private var scratchpadBackgroundOpacity = 0.0
    @AppStorage(DefaultsKey.colorPickerFormat) private var colorFormat = "hex"
    @AppStorage(DefaultsKey.colorPickerBareHex) private var colorBareHex = false
    @AppStorage(DefaultsKey.micMuteMenuBarIndicator) private var micMenuBarIndicator = false

    var body: some View {
        Form {
            if AppFeature.quickLauncher.isAvailable {
                Section {
                    PraxisButton(l10n.s.launcherOpenNow, icon: "square.grid.2x2", role: .secondary) {
                        QuickLauncherService.shared.show()
                    }
                    Text(l10n.s.launcherCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(l10n.s.launcherEditHint)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    PraxisSettingsToggle(label: l10n.s.quickToolShortcutToggle, isOn: $launcherShortcutEnabled)
                        .onChange(of: launcherShortcutEnabled) { _, _ in
                            QuickLauncherService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .quickLauncher,
                                          isEnabled: launcherShortcutEnabled) {
                        QuickLauncherService.shared.syncWithPreferences()
                    }
                    if launcherShortcutEnabled, launcher.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text(l10n.s.launcherName)
                }
            }

            if AppFeature.quickToggles.isAvailable {
                Section {
                    PraxisButton(colorScheme == .dark
                                 ? FeatureStrings.quickToggles(l10n.language).darkModeToLight
                                 : FeatureStrings.quickToggles(l10n.language).darkModeToDark,
                                 icon: colorScheme == .dark ? "sun.max.fill" : "moon.fill",
                                 role: .secondary) {
                        QuickTogglesService.shared.toggleDarkMode()
                    }
                    Text(FeatureStrings.quickToggles(l10n.language).panelCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(FeatureStrings.quickToggles(l10n.language).pageTitle)
                }
            }

            if AppFeature.screenOCR.isAvailable {
                Section {
                    PraxisButton(l10n.s.ocrName, icon: "text.viewfinder", role: .secondary) {
                        ScreenTextService.shared.capture()
                    }
                    Text(l10n.s.ocrCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PraxisSettingsToggle(label: l10n.s.ocrQRToggle, isOn: $ocrDetectQRCodes)
                    Text(l10n.s.ocrQRCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PraxisSettingsToggle(label: l10n.s.quickToolShortcutToggle, isOn: $ocrShortcutEnabled)
                        .onChange(of: ocrShortcutEnabled) { _, _ in
                            ScreenTextService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .screenOCR,
                                          isEnabled: ocrShortcutEnabled) {
                        ScreenTextService.shared.syncWithPreferences()
                    }
                    if ocrShortcutEnabled, ocr.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if !permissions.screenRecording {
                        PermissionRow(kind: .screenRecording)
                    }
                } header: {
                    Text(l10n.s.ocrName)
                }
            }

            if AppFeature.colorPicker.isAvailable {
                Section {
                    PraxisButton(l10n.s.colorPickerPickNow, icon: "eyedropper", role: .secondary) {
                        ColorSamplerService.shared.pick()
                    }
                    Text(l10n.s.colorPickerCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker(l10n.s.colorPickerFormatLabel, selection: $colorFormat) {
                        ForEach(ColorCopyFormat.allCases) { format in
                            Text(format.label).tag(format.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    if colorFormat == ColorCopyFormat.hex.rawValue {
                        PraxisSettingsToggle(label: l10n.s.colorPickerBareHexToggle, isOn: $colorBareHex)
                    }
                    PraxisSettingsToggle(label: l10n.s.quickToolShortcutToggle, isOn: $colorShortcutEnabled)
                        .onChange(of: colorShortcutEnabled) { _, _ in
                            ColorSamplerService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .colorPicker,
                                          isEnabled: colorShortcutEnabled) {
                        ColorSamplerService.shared.syncWithPreferences()
                    }
                    if colorShortcutEnabled, colorSampler.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text(l10n.s.colorPickerName)
                }
            }

            if AppFeature.micMute.isAvailable {
                Section {
                    PraxisButton(micMute.isMuted ? l10n.s.micUnmuteName : l10n.s.micMuteName,
                                 icon: micMute.isMuted ? "mic.slash.fill" : "mic",
                                 role: .secondary) {
                        MicMuteService.shared.toggle()
                    }
                    if micMute.isMuted {
                        Label(l10n.s.micMutedHUD, systemImage: "mic.slash.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(l10n.s.micMuteCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PraxisSettingsToggle(label: l10n.s.micMuteMenuBarToggle, isOn: $micMenuBarIndicator)
                    Text(l10n.s.micMuteMenuBarCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PraxisSettingsToggle(label: l10n.s.quickToolShortcutToggle, isOn: $micShortcutEnabled)
                        .onChange(of: micShortcutEnabled) { _, _ in
                            MicMuteService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .micMute,
                                          isEnabled: micShortcutEnabled) {
                        MicMuteService.shared.syncWithPreferences()
                    }
                    if micShortcutEnabled, micMute.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text(l10n.s.micMuteName)
                }
            }

            if AppFeature.cameraPreview.isAvailable {
                Section {
                    PraxisButton(FeatureStrings.cameraPreview(l10n.language).openButton,
                                 icon: "web.camera",
                                 role: .secondary) {
                        CameraPreviewService.shared.show()
                    }
                    Text(FeatureStrings.cameraPreview(l10n.language).panelCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PraxisSettingsToggle(label: l10n.s.quickToolShortcutToggle, isOn: $cameraShortcutEnabled)
                        .onChange(of: cameraShortcutEnabled) { _, _ in
                            CameraPreviewService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .cameraPreview,
                                          isEnabled: cameraShortcutEnabled) {
                        CameraPreviewService.shared.syncWithPreferences()
                    }
                    if cameraShortcutEnabled, cameraPreview.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if permissions.camera == .denied {
                        CameraPermissionRow()
                    }
                } header: {
                    Text(FeatureStrings.cameraPreview(l10n.language).pageTitle)
                }
            }

            if AppFeature.scratchpad.isAvailable {
                Section {
                    PraxisButton(FeatureStrings.scratchpad(l10n.language).openButton,
                                 icon: "note.text",
                                 role: .secondary) {
                        ScratchpadService.shared.show()
                    }
                    Text(FeatureStrings.scratchpad(l10n.language).panelCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker(FeatureStrings.scratchpad(l10n.language).retentionTitle,
                           selection: $scratchpadRetention) {
                        Text(FeatureStrings.scratchpad(l10n.language).retentionNever)
                            .tag(ScratchpadRetention.never.rawValue)
                        Text(FeatureStrings.scratchpad(l10n.language).retentionDay)
                            .tag(ScratchpadRetention.day.rawValue)
                        Text(FeatureStrings.scratchpad(l10n.language).retentionWeek)
                            .tag(ScratchpadRetention.week.rawValue)
                        Text(FeatureStrings.scratchpad(l10n.language).retentionMonth)
                            .tag(ScratchpadRetention.month.rawValue)
                    }
                    Text(FeatureStrings.scratchpad(l10n.language).retentionCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PraxisSettingsToggle(label: FeatureStrings.scratchpad(l10n.language).closeOnClickOutside, isOn: $scratchpadCloseOnClickOutside)
                        .onChange(of: scratchpadCloseOnClickOutside) { _, _ in
                            ScratchpadService.shared.outsideClickPreferenceDidChange()
                        }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(FeatureStrings.scratchpad(l10n.language).backgroundOpacity)
                        Slider(value: scratchpadBackgroundOpacityBinding,
                               in: ScratchpadSupport.backgroundOpacityRange,
                               step: 0.05)
                        HStack {
                            Text(FeatureStrings.scratchpad(l10n.language).backgroundTranslucent)
                            Spacer()
                            Text(FeatureStrings.scratchpad(l10n.language).backgroundOpaque)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    PraxisSettingsToggle(label: l10n.s.quickToolShortcutToggle, isOn: $scratchpadShortcutEnabled)
                        .onChange(of: scratchpadShortcutEnabled) { _, _ in
                            ScratchpadService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .scratchpad,
                                          isEnabled: scratchpadShortcutEnabled) {
                        ScratchpadService.shared.syncWithPreferences()
                    }
                    if scratchpadShortcutEnabled, scratchpad.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text(FeatureStrings.scratchpad(l10n.language).pageTitle)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var scratchpadBackgroundOpacityBinding: Binding<Double> {
        Binding(
            get: { ScratchpadSupport.sanitizedBackgroundOpacity(scratchpadBackgroundOpacity) },
            set: { scratchpadBackgroundOpacity = ScratchpadSupport.sanitizedBackgroundOpacity($0) }
        )
    }
}

/// The camera state has no re-prompt once denied, so the row goes straight
/// to System Settings instead of offering a dead request button.
private struct CameraPermissionRow: View {
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text(FeatureStrings.cameraPreview(l10n.language).permName)
                Spacer()
                Text(l10n.s.permissionMissing)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            PraxisButton(l10n.s.permissionOpenSettings, icon: "gearshape", role: .ghost, size: .mini) {
                Permissions.shared.openCameraSettings()
            }
        }
    }
}
