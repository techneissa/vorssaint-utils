#!/usr/bin/env bash
# Shared codesign for staged/installed Vorssaint.app bundles.
# Prefer a stable, OS-trusted identity so TCC grants (Accessibility, Screen
# Recording, Full Disk Access) survive `just install` rebuilds.
# shellcheck shell=bash

# Sets globals: VORSSAINT_SIGN_AS (human label), VORSSAINT_SIGN_IDENTITY (codesign -s arg)
vorssaint_resolve_signing_identity() {
    local entitlements="${1:-Resources/Vorssaint.entitlements}"
    local legacy_identity="Vorssaint Utils Signing"
    local devid_hash="" apple_dev_hash=""

    VORSSAINT_SIGN_ENTITLEMENTS="$entitlements"
    VORSSAINT_SIGN_AS=""
    VORSSAINT_SIGN_IDENTITY=""

    # Prefer SHA-1 identity hashes so duplicate display names (common with
    # Apple Development) do not make codesign abort as "ambiguous".
    devid_hash="$(security find-identity -v -p codesigning 2>/dev/null \
        | grep 'Developer ID Application' \
        | head -1 \
        | awk '{print $2}' || true)"
    apple_dev_hash="$(security find-identity -v -p codesigning 2>/dev/null \
        | grep 'Apple Development:' \
        | head -1 \
        | awk '{print $2}' || true)"

    if [[ -n "$devid_hash" ]]; then
        VORSSAINT_SIGN_IDENTITY="$devid_hash"
        VORSSAINT_SIGN_AS="Developer ID"
        VORSSAINT_SIGN_HARDENED=1
    elif [[ -n "$apple_dev_hash" ]]; then
        # Trusted by macOS on this machine; designated requirement stays stable
        # across rebuilds (unlike ad-hoc cdhash pinning).
        VORSSAINT_SIGN_IDENTITY="$apple_dev_hash"
        VORSSAINT_SIGN_AS="Apple Development"
        VORSSAINT_SIGN_HARDENED=0
    elif security find-identity -p codesigning 2>/dev/null | grep -q "$legacy_identity"; then
        VORSSAINT_SIGN_IDENTITY="$legacy_identity"
        VORSSAINT_SIGN_AS="Vorssaint Utils Signing"
        VORSSAINT_SIGN_HARDENED=0
    else
        VORSSAINT_SIGN_IDENTITY="-"
        VORSSAINT_SIGN_AS="ad-hoc"
        VORSSAINT_SIGN_HARDENED=0
    fi
}

# Codesign $1 (app bundle path). Call vorssaint_resolve_signing_identity first
# or pass entitlements path as $2 to resolve now.
vorssaint_codesign_app() {
    local target="$1"
    local entitlements="${2:-${VORSSAINT_SIGN_ENTITLEMENTS:-Resources/Vorssaint.entitlements}}"

    if [[ -z "${VORSSAINT_SIGN_IDENTITY:-}" ]]; then
        vorssaint_resolve_signing_identity "$entitlements"
    fi

    if [[ "${VORSSAINT_SIGN_HARDENED:-0}" == "1" ]]; then
        codesign --force --strip-disallowed-xattrs --options runtime --timestamp \
            --entitlements "$entitlements" --sign "$VORSSAINT_SIGN_IDENTITY" "$target"
    elif [[ "$VORSSAINT_SIGN_IDENTITY" == "-" ]]; then
        codesign --force --strip-disallowed-xattrs \
            --entitlements "$entitlements" --sign - "$target"
    else
        codesign --force --strip-disallowed-xattrs \
            --entitlements "$entitlements" --sign "$VORSSAINT_SIGN_IDENTITY" "$target"
    fi
}
