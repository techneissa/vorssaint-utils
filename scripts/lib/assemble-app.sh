#!/usr/bin/env bash
# Assemble build/stage/$APP_NAME.app from a compiled binary + Resources.
# Expects: APP_NAME, EXECUTABLE, DEV (0/1), BIN (path to Vorssaint executable)
# Optional: UI helpers from cli-ui.sh for detail lines.
# shellcheck shell=bash

assemble_staged_app() {
    local bin="${BIN:?BIN required}"
    local stage_root="build/stage"
    local stage="$stage_root/${APP_NAME}.app"
    local entitlements="Resources/Vorssaint.entitlements"

    if [[ ! -x "$bin" ]]; then
        if declare -F ui_err >/dev/null 2>&1; then
            ui_err "missing binary: $bin"
        else
            echo "missing binary: $bin" >&2
        fi
        return 1
    fi

    mkdir -p build

    # Icon assets — regenerate only when brand logo is newer than stamp.
    local logo="Resources/Brand/logo.png"
    local stamp="build/.icon-stamp"
    local need_icons=1
    if [[ -f "$stamp" && -f "build/AppIcon.icns" && -f "build/MenuBarIcon.png" \
        && -f "build/MenuBarIcon@2x.png" && -f "build/BrandMark.png" \
        && -f "$logo" && ! "$logo" -nt "$stamp" ]]; then
        need_icons=0
    fi
    if (( need_icons )); then
        if declare -F ui_detail >/dev/null 2>&1; then
            ui_detail "generating icons from Resources/Brand/logo.png"
        fi
        swift Tools/MakeIcon.swift build/AppIcon.iconset
        xattr -c -r build/AppIcon.iconset build/AppIcon.icns \
            build/MenuBarIcon.png build/MenuBarIcon@2x.png build/BrandMark.png 2>/dev/null || true
        date >"$stamp"
    else
        if declare -F ui_detail >/dev/null 2>&1; then
            ui_detail "icons up to date"
        fi
    fi

    rm -rf "$stage"
    mkdir -p "$stage/Contents/MacOS" "$stage/Contents/Resources"
    cp "$bin" "$stage/Contents/MacOS/$EXECUTABLE"
    chmod +x "$stage/Contents/MacOS/$EXECUTABLE"
    cp Resources/Info.plist "$stage/Contents/Info.plist"
    cp CHANGELOG.md "$stage/Contents/Resources/CHANGELOG.md"

    local lproj
    for lproj in Resources/*.lproj; do
        [[ -e "$lproj" ]] || continue
        cp -R "$lproj" "$stage/Contents/Resources/"
    done

    if (( DEV )); then
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.vorssaint.utils.dev" "$stage/Contents/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleName Vorssaint (Developer)" "$stage/Contents/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Vorssaint (Developer)" "$stage/Contents/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $EXECUTABLE" "$stage/Contents/Info.plist"
        local sha
        sha="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
        [[ -n "$(git status --porcelain 2>/dev/null)" ]] && sha="$sha-dirty"
        /usr/libexec/PlistBuddy -c "Delete :VorssaintBuildCommit" "$stage/Contents/Info.plist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :VorssaintBuildCommit string '$sha · $(date '+%Y-%m-%d %H:%M')'" "$stage/Contents/Info.plist"
        if declare -F ui_detail >/dev/null 2>&1; then
            ui_detail "stamped dev build: $sha"
        fi
    fi

    printf 'APPL????' >"$stage/Contents/PkgInfo"
    cp build/AppIcon.icns "$stage/Contents/Resources/AppIcon.icns"
    cp build/MenuBarIcon.png build/MenuBarIcon@2x.png build/BrandMark.png "$stage/Contents/Resources/"
    if [[ -d Resources/Gifs ]]; then
        mkdir -p "$stage/Contents/Resources/Gifs"
        cp Resources/Gifs/*.gif "$stage/Contents/Resources/Gifs/" 2>/dev/null || true
    fi
    if [[ -d Resources/Images ]]; then
        mkdir -p "$stage/Contents/Resources/Images"
        cp Resources/Images/* "$stage/Contents/Resources/Images/" 2>/dev/null || true
    fi
    xattr -c -r "$stage" 2>/dev/null || true

    # shellcheck source=codesign-app.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/codesign-app.sh"
    vorssaint_resolve_signing_identity "$entitlements"
    vorssaint_codesign_app "$stage"

    if ! codesign --verify --deep --strict "$stage" >/dev/null 2>&1; then
        xattr -c -r "$stage" 2>/dev/null || true
        vorssaint_codesign_app "$stage"
    fi
    codesign --verify --deep --strict "$stage"

    if declare -F ui_detail >/dev/null 2>&1; then
        ui_detail "signed as: $VORSSAINT_SIGN_AS ($VORSSAINT_SIGN_IDENTITY)"
    fi
    if [[ "$VORSSAINT_SIGN_AS" == "ad-hoc" ]]; then
        if declare -F ui_warn >/dev/null 2>&1; then
            ui_warn "Ad-hoc signature: permissions reset every install. Prefer an Apple Development cert, or ./Tools/setup-signing.sh + Always Trust in Keychain Access."
        else
            echo "warning: ad-hoc signature; permissions will not stick across installs" >&2
        fi
    fi
}
