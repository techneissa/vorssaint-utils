#!/usr/bin/env bash
# SDK / toolchain env for local swift build (mirrors build.sh preferences).
# shellcheck shell=bash

vorssaint_swift_env() {
    local pinned="/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk"
    if [[ -d "$pinned" ]]; then
        export SDKROOT="$pinned"
    elif [[ -z "${SDKROOT:-}" ]]; then
        export SDKROOT="$(xcrun --show-sdk-path)"
    fi

    if [[ -z "${DEVELOPER_DIR:-}" ]]; then
        if [[ -d "/Applications/Xcode-beta.app/Contents/Developer" ]]; then
            export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"
        elif [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
            export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
        fi
    fi
}

# Resolved product binary. config: debug | release
vorssaint_product_bin() {
    local config="${1:-release}"
    local cache=".build/vorssaint-${config}-bin-path"
    local base
    mkdir -p .build
    if [[ -f "$cache" ]]; then
        base="$(cat "$cache")"
        if [[ -x "$base/Vorssaint" ]]; then
            printf '%s/Vorssaint\n' "$base"
            return 0
        fi
    fi
    if [[ "$config" == "release" ]]; then
        base="$(swift build -c release --product Vorssaint --show-bin-path)"
    else
        base="$(swift build --product Vorssaint --show-bin-path)"
    fi
    printf '%s\n' "$base" >"$cache"
    printf '%s/Vorssaint\n' "$base"
}
