#!/usr/bin/env bash
# Install a staged Vorssaint .app into /Applications (Keyforge-style install step).
# Sourced by scripts/dev-run.sh after a successful build.
#
# Expects: APP_NAME, EXECUTABLE, UI helpers from cli-ui.sh, cwd = repo root.

install_app_to_applications() {
    local src="build/stage/${APP_NAME}.app"
    local dest="/Applications/${APP_NAME}.app"
    local entitlements="Resources/Vorssaint.entitlements"

    if [[ ! -d "$src" ]]; then
        ui_err "missing staged app: $src"
        return 1
    fi

    echo
    ui_plan_header "Install"

    # Avoid copying over a running binary (codesign / dyld weirdness).
    if pgrep -f "/Contents/MacOS/${EXECUTABLE}" >/dev/null 2>&1 \
        || { (( ${#EXECUTABLE} <= 15 )) && pgrep -x "$EXECUTABLE" >/dev/null 2>&1; }; then
        ui_detail "Quitting running ${APP_NAME}…"
        osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
        local _
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            if ! pgrep -f "/Contents/MacOS/${EXECUTABLE}" >/dev/null 2>&1; then
                break
            fi
            sleep 0.2
        done
        pkill -f "/Contents/MacOS/${EXECUTABLE}" 2>/dev/null || true
        if (( ${#EXECUTABLE} <= 15 )); then
            pkill -x "$EXECUTABLE" 2>/dev/null || true
        fi
    fi

    # Legacy bundle names (same idea as build.sh --install).
    local legacy name proc
    for legacy in "Vorss:Vorss" "Vorssaint Utils:VorssaintUtils"; do
        name="${legacy%%:*}"
        proc="${legacy##*:}"
        if [[ -d "/Applications/${name}.app" ]]; then
            pkill -x "$proc" 2>/dev/null || true
            rm -rf "/Applications/${name}.app"
            ui_detail "removed legacy ${name}.app"
        fi
    done

    ui_detail "$(ui_shorten_text "$(pwd)/$src") → $dest"
    rm -rf "$dest"
    ditto --noextattr --noqtn "$src" "$dest"
    touch "$dest"

    # Re-sign after copy with the SAME identity + entitlements as assemble.
    # (Omitting entitlements here previously stripped them and confused TCC.)
    # shellcheck source=codesign-app.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/codesign-app.sh"
    vorssaint_resolve_signing_identity "$entitlements"
    ui_detail "re-signing install as: $VORSSAINT_SIGN_AS"
    vorssaint_codesign_app "$dest"

    # Second pass if filesystem metadata unsettled the first signature.
    sleep 1
    xattr -c -r "$dest" 2>/dev/null || true
    if ! codesign --verify --deep --strict "$dest" >/dev/null 2>&1; then
        ui_detail "re-signing after filesystem metadata settled ($VORSSAINT_SIGN_AS)"
        vorssaint_codesign_app "$dest"
    fi
    codesign --verify --deep --strict "$dest"

    ui_ok "Installed  $dest"
    if [[ "$VORSSAINT_SIGN_AS" == "ad-hoc" ]]; then
        ui_detail "ad-hoc: first launch on a new Mac may need right-click → Open"
        ui_warn "Ad-hoc: TCC grants will not stick. Use Apple Development or ./Tools/setup-signing.sh."
    fi
}
