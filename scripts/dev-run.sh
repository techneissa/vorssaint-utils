#!/usr/bin/env bash
# Polished build / install / run for the SpaciousTech vorssaint-utils fork.
#
# Default: incremental `swift build -c release` → real /Applications .app
# (runs like the Homebrew build; reinstall after UI edits stays practical).
# `--optimized` uses upstream ./build.sh (full wipe + swiftc -O, much slower).
#
# Usage:
#   scripts/dev-run.sh --install          # build + install Developer app
#   scripts/dev-run.sh --run              # install + launch
#   scripts/dev-run.sh --build
#   scripts/dev-run.sh --test
#   scripts/dev-run.sh --install --release
#   scripts/dev-run.sh --install --optimized
#
# Env: NO_COLOR=1 · FORCE_COLOR=1

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export UI_REPO_ROOT="$ROOT"
# shellcheck source=lib/cli-ui.sh
source "$ROOT/scripts/lib/cli-ui.sh"
# shellcheck source=lib/swift-env.sh
source "$ROOT/scripts/lib/swift-env.sh"
# shellcheck source=lib/assemble-app.sh
source "$ROOT/scripts/lib/assemble-app.sh"
# shellcheck source=lib/install-app.sh
source "$ROOT/scripts/lib/install-app.sh"

ACTION=""
DEV=1
LAUNCH=0
OPTIMIZED=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build)      ACTION=build; shift ;;
        --install)    ACTION=install; shift ;;
        --run)        ACTION=run; LAUNCH=1; shift ;;
        --test)       ACTION=test; shift ;;
        --dev)        DEV=1; shift ;;
        --release)    DEV=0; shift ;;
        --optimized)  OPTIMIZED=1; shift ;;
        -h|--help)
            sed -n '2,18p' "$0" | sed -E 's/^# ?//'
            exit 0
            ;;
        *)
            ui_err "unknown arg: $1"
            exit 2
            ;;
    esac
done

if [[ -z "$ACTION" ]]; then
    ui_err "need --build | --install | --run | --test"
    exit 2
fi

if [[ "$ACTION" == "run" ]]; then
    ACTION=install
    LAUNCH=1
fi

if (( DEV )); then
    APP_NAME="Vorssaint (Developer)"
    EXECUTABLE="VorssaintDeveloper"
    VARIANT="Developer"
    BUILD_ARGS=(--dev)
else
    APP_NAME="Vorssaint"
    EXECUTABLE="Vorssaint"
    VARIANT="Release"
    BUILD_ARGS=()
fi

SWIFT_COUNT="$(find Sources/Vorssaint -name '*.swift' 2>/dev/null | wc -l | tr -d ' ')"
BRANCH="$(git branch --show-current 2>/dev/null || echo "?")"
SHA="$(git rev-parse --short HEAD 2>/dev/null || echo "?")"
DIRTY=""
[[ -n "$(git status --porcelain 2>/dev/null)" ]] && DIRTY=" · dirty"

vorssaint_swift_env
SDK_LABEL="$(basename "${SDKROOT:-unknown}")"

STAGE_APP="build/stage/${APP_NAME}.app"
DEST_APP="/Applications/${APP_NAME}.app"

# ── test ──────────────────────────────────────────────────────────────────────

if [[ "$ACTION" == "test" ]]; then
    ui_banner "Vorssaint test" "custom-ui · unit tests"
    ui_plan_header "Plan"
    ui_kv "branch" "$BRANCH @ $SHA$DIRTY"
    ui_kv "runner" "./build.sh --test"
    echo
    UI_TOTAL_STEPS=1
    ui_step 1 1 "Unit tests"
    set +e
    ui_run ./build.sh --test
    ec=$?
    set -e
    if (( ec != 0 )); then
        ui_err "tests failed (exit $ec)"
        exit "$ec"
    fi
    ui_step_done "passed"
    ui_done "Tests OK"
    exit 0
fi

# ── plan ──────────────────────────────────────────────────────────────────────

DO_INSTALL=0
[[ "$ACTION" == "install" ]] && DO_INSTALL=1

MODE_LABEL="release · incremental"
if (( OPTIMIZED )); then
    MODE_LABEL="release · build.sh -O"
fi

if (( DO_INSTALL )); then
    ui_banner "Vorssaint install" "custom-ui · $VARIANT · $MODE_LABEL"
else
    ui_banner "Vorssaint build" "custom-ui · $VARIANT · $MODE_LABEL"
fi

ui_plan_header "Plan"
ui_kv "branch"  "$BRANCH @ $SHA$DIRTY"
ui_kv "variant" "$VARIANT" "$UI_CYAN"
ui_kv "sources" "$SWIFT_COUNT Swift files"
ui_kv "sdk"     "$SDK_LABEL"
ui_kv "mode"    "$MODE_LABEL" "$UI_GREEN"
ui_kv "stage"   "$STAGE_APP"
if (( DO_INSTALL )); then
    ui_kv "install" "$DEST_APP" "$UI_GREEN"
fi
if (( LAUNCH )); then
    ui_kv "launch" "open -a \"$APP_NAME\""
fi
echo

# ── optimized: upstream build.sh ──────────────────────────────────────────────

if (( OPTIMIZED )); then
    UI_TOTAL_STEPS=3
    current_step=0
    step_closed=0

    close_step() {
        local n="$1"
        (( step_closed == n )) && return
        ui_progress_close
        ui_activity_stop
        case "$n" in
            1) ui_step_done "binary" ;;
            2) ui_step_done "icons" ;;
            3) ui_step_done "bundle" ;;
        esac
        step_closed=$n
    }

    advance_to() {
        local n="$1"
        local label="$2"
        (( current_step == n )) && return
        if (( current_step > 0 )); then close_step "$current_step"; fi
        current_step=$n
        ui_step "$n" "$UI_TOTAL_STEPS" "$label"
        (( n == 1 )) && ui_activity_start "compiling…" 5
    }

    ec_file="$(mktemp)"
    trap 'ui_activity_stop; rm -f "$ec_file"' EXIT INT TERM
    advance_to 1 "Compile"

    while IFS= read -r line || [[ -n "$line" ]]; do
        short="$(ui_shorten_text "$line")"
        case "$line" in
            *"Compiling (release)"*) (( current_step != 1 )) && advance_to 1 "Compile" ;;
            *"Generating app icon"*) advance_to 2 "Generate icons" ;;
            *"Assembling and signing"*) advance_to 3 "Assemble & sign" ;;
            *"✓ Bundle ready"*) ui_colorize_build_line "$short" ;;
            *"Installing into /Applications"*|*"Finalizing installed signature"*) ;;
            *)
                [[ -z "${line// /}" ]] && continue
                ui_colorize_build_line "$short"
                ;;
        esac
    done < <(
        set +e
        if command -v stdbuf >/dev/null 2>&1; then
            stdbuf -oL -eL ./build.sh "${BUILD_ARGS[@]}"
        else
            ./build.sh "${BUILD_ARGS[@]}"
        fi
        printf '%s\n' "$?" >"$ec_file"
    )

    ec="$(cat "$ec_file" 2>/dev/null || echo 1)"
    rm -f "$ec_file"
    trap 'ui_activity_stop' EXIT INT TERM
    (( current_step > 0 )) && close_step "$current_step"
    ui_activity_stop
    if (( ec != 0 )); then
        ui_err "build failed (exit $ec)"
        exit "$ec"
    fi
else
    # Incremental release: brew-speed runtime, practical reinstalls.
    # There is no download phase here. SwiftPM's [n/m] counters are local
    # compile/link jobs. The last few jobs often sit quiet while linking.
    UI_TOTAL_STEPS=2

    ui_step 1 2 "Compile"
    set +e
    ui_run swift build -c release --product Vorssaint
    ec=$?
    set -e
    if (( ec != 0 )); then
        ui_err "swift build failed (exit $ec)"
        exit "$ec"
    fi

    rm -f .build/vorssaint-release-bin-path
    BIN="$(vorssaint_product_bin release)"
    if [[ ! -x "$BIN" ]]; then
        ui_err "binary not found after build: $BIN"
        exit 1
    fi
    ui_step_done "$(ui_shorten_text "$BIN")"

    ui_step 2 2 "Assemble & sign"
    BIN="$BIN" assemble_staged_app
    ui_step_done "bundle"
fi

if [[ ! -d "$STAGE_APP" ]]; then
    ui_err "missing staged app: $STAGE_APP"
    exit 1
fi

ui_ok "Staged  $(ui_shorten_text "$(pwd)/$STAGE_APP")"

if (( ! DO_INSTALL )); then
    ui_done "Build ready" "Next: just install"
    exit 0
fi

if ! install_app_to_applications; then
    exit 1
fi

# Sanity: installed bundle looks like a real app
if [[ ! -x "$DEST_APP/Contents/MacOS/$EXECUTABLE" ]]; then
    ui_err "install incomplete — missing $DEST_APP/Contents/MacOS/$EXECUTABLE"
    exit 1
fi
if [[ ! -f "$DEST_APP/Contents/Info.plist" ]]; then
    ui_err "install incomplete — missing Info.plist"
    exit 1
fi

ui_done "Ready" "$DEST_APP"

if (( LAUNCH )); then
    ui_info "Launching $APP_NAME…"
    echo
    open -a "$APP_NAME"
else
    ui_info "Launch: open -a \"$APP_NAME\"   ·   or: just run"
    echo
fi
