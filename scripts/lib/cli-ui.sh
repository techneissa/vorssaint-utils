#!/usr/bin/env bash
# Shared terminal polish for Vorssaint fork just recipes (Keyforge-style).
# Source from bash:  source "$ROOT/scripts/lib/cli-ui.sh"
#
# Respects NO_COLOR (plain text) and non-TTY stdout.
# FORCE_COLOR=1 forces ANSI color even when piped / NO_COLOR is set.

# shellcheck disable=SC2034  # exported for callers

if [[ "${VORSSAINT_CLI_UI_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
VORSSAINT_CLI_UI_LOADED=1

_ui_init() {
    UI_T0="${UI_T0:-$(date +%s)}"
    UI_STEP_T0="$UI_T0"
    UI_TOTAL_STEPS="${UI_TOTAL_STEPS:-0}"
    UI_WIDTH="${UI_WIDTH:-56}"
    UI_ACTIVITY_PID=""

    if [[ -n "${FORCE_COLOR:-}" ]]; then
        UI_COLOR=1
    elif [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
        UI_COLOR=0
    else
        UI_COLOR=1
    fi

    if (( UI_COLOR )); then
        UI_RESET=$'\033[0m'
        UI_BOLD=$'\033[1m'
        UI_DIM=$'\033[2m'
        UI_RED=$'\033[31m'
        UI_GREEN=$'\033[32m'
        UI_YELLOW=$'\033[33m'
        UI_BLUE=$'\033[34m'
        UI_CYAN=$'\033[36m'
        UI_MAGENTA=$'\033[35m'
        UI_WHITE=$'\033[37m'
    else
        UI_RESET="" UI_BOLD="" UI_DIM=""
        UI_RED="" UI_GREEN="" UI_YELLOW="" UI_BLUE="" UI_CYAN="" UI_MAGENTA=""
        UI_WHITE=""
    fi
}
_ui_init

ui_elapsed() {
    local now
    now="$(date +%s)"
    echo $((now - UI_T0))
}

ui_step_elapsed() {
    local now
    now="$(date +%s)"
    echo $((now - UI_STEP_T0))
}

# Format seconds as 12s or 1m 05s
ui_fmt_secs() {
    local s="${1:-0}"
    if (( s < 60 )); then
        printf '%ds' "$s"
    else
        printf '%dm %02ds' $((s / 60)) $((s % 60))
    fi
}

ui_hr() {
    local char="${1:-─}"
    local n="$UI_WIDTH"
    local line=""
    local i
    for ((i = 0; i < n; i++)); do
        line+="$char"
    done
    printf '%s\n' "$line"
}

# Compact progress bar: filled/empty for step n of total
ui_bar() {
    local n="$1"
    local total="$2"
    local width="${3:-18}"
    if (( total <= 0 )); then
        printf '%s' ""
        return
    fi
    local filled=$(( (n * width) / total ))
    (( filled > width )) && filled=$width
    local empty=$((width - filled))
    local bar=""
    local i
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done
    printf '%s' "$bar"
}

ui_banner() {
    local title="$1"
    local subtitle="${2:-}"
    echo
    if (( UI_COLOR )); then
        printf '%s╭─ %s%s%s' "$UI_DIM" "$UI_RESET$UI_BOLD$UI_CYAN" "$title" "$UI_RESET"
        local pad=$(( UI_WIDTH - ${#title} - 4 ))
        (( pad < 0 )) && pad=0
        local i
        for ((i = 0; i < pad; i++)); do printf '%s─%s' "$UI_DIM" "$UI_RESET"; done
        printf '%s╮%s\n' "$UI_DIM" "$UI_RESET"
        if [[ -n "$subtitle" ]]; then
            printf '%s│%s  %s%s%s\n' "$UI_DIM" "$UI_RESET" "$UI_DIM" "$subtitle" "$UI_RESET"
        fi
        printf '%s╰' "$UI_DIM"
        local j
        for ((j = 0; j < UI_WIDTH; j++)); do printf '─'; done
        printf '╯%s\n' "$UI_RESET"
    else
        echo "=== $title ==="
        [[ -n "$subtitle" ]] && echo "  $subtitle"
    fi
    echo
}

ui_plan_header() {
    printf '%s%s%s\n' "$UI_BOLD" "$1" "$UI_RESET"
}

# Key/value row used in plan summaries
ui_kv() {
    local key="$1"
    local value="$2"
    local accent="${3:-}"
    printf '  %s%-16s%s' "$UI_DIM" "$key" "$UI_RESET"
    if [[ -n "$accent" ]] && (( UI_COLOR )); then
        printf '%s%s%s\n' "$accent" "$value" "$UI_RESET"
    else
        printf '%s\n' "$value"
    fi
}

# Start a numbered step. Args: n [total] label
ui_step() {
    local n="$1"
    shift
    local total="$UI_TOTAL_STEPS"
    local label
    if [[ "${1:-}" =~ ^[0-9]+$ ]] && [[ $# -ge 2 ]]; then
        total="$1"
        shift
    fi
    label="$*"
    UI_STEP_T0="$(date +%s)"
    local elapsed
    elapsed="$(ui_fmt_secs "$(ui_elapsed)")"
    echo
    if (( total > 0 )); then
        local bar
        bar="$(ui_bar "$n" "$total")"
        if (( UI_COLOR )); then
            printf '  %s[%s%d%s/%d]%s %s%s%s  %s%s%s  %s(+%s)%s\n' \
                "$UI_CYAN$UI_BOLD" "$UI_RESET$UI_CYAN$UI_BOLD" "$n" \
                "$UI_DIM" "$total" "$UI_RESET" \
                "$UI_DIM" "$bar" "$UI_RESET" \
                "$UI_BOLD" "$label" "$UI_RESET" \
                "$UI_DIM" "$elapsed" "$UI_RESET"
        else
            printf '  [%d/%d] %s  (+%s)\n' "$n" "$total" "$label" "$elapsed"
        fi
    else
        if (( UI_COLOR )); then
            printf '  %s[%d]%s %s%s%s  %s(+%s)%s\n' \
                "$UI_CYAN$UI_BOLD" "$n" "$UI_RESET" \
                "$UI_BOLD" "$label" "$UI_RESET" \
                "$UI_DIM" "$elapsed" "$UI_RESET"
        else
            printf '  [%d] %s  (+%s)\n' "$n" "$label" "$elapsed"
        fi
    fi
}

ui_step_done() {
    local detail="${1:-}"
    local took
    took="$(ui_fmt_secs "$(ui_step_elapsed)")"
    if [[ -n "$detail" ]]; then
        printf '  %s✓%s %s %s(%s)%s\n' "$UI_GREEN" "$UI_RESET" "$detail" "$UI_DIM" "$took" "$UI_RESET"
    else
        printf '  %s✓%s done %s(%s)%s\n' "$UI_GREEN" "$UI_RESET" "$UI_DIM" "$took" "$UI_RESET"
    fi
}

ui_detail() {
    printf '  %s%s%s\n' "$UI_DIM" "$*" "$UI_RESET"
}

ui_info() {
    printf '  %s→%s %s\n' "$UI_BLUE" "$UI_RESET" "$*"
}

ui_ok() {
    printf '  %s✓%s %s\n' "$UI_GREEN$UI_BOLD" "$UI_RESET" "$*"
}

ui_warn() {
    printf '  %s!%s %s\n' "$UI_YELLOW$UI_BOLD" "$UI_RESET" "$*" >&2
}

ui_err() {
    printf '  %s✗%s %s\n' "$UI_RED$UI_BOLD" "$UI_RESET" "$*" >&2
}

ui_skip() {
    printf '  %s·%s %s %s(skipped)%s\n' "$UI_YELLOW" "$UI_RESET" "$*" "$UI_DIM" "$UI_RESET"
}

ui_done() {
    local summary="${1:-Done}"
    local extra="${2:-}"
    local elapsed
    elapsed="$(ui_fmt_secs "$(ui_elapsed)")"
    echo
    if (( UI_COLOR )); then
        printf '%s%s%s  %s%s%s\n' \
            "$UI_GREEN$UI_BOLD" "$summary" "$UI_RESET" \
            "$UI_DIM" "in $elapsed" "$UI_RESET"
    else
        printf '%s  in %s\n' "$summary" "$elapsed"
    fi
    if [[ -n "$extra" ]]; then
        printf '  %s%s%s\n' "$UI_DIM" "$extra" "$UI_RESET"
    fi
    echo
}

# ── Silent-phase activity (long compiles with no toolchain output) ────────────

# Background ticks so a long silent compile still looks alive.
# Args: label  [interval_secs=5]
ui_activity_start() {
    local label="$1"
    local interval="${2:-5}"
    ui_activity_stop
    (
        while true; do
            sleep "$interval"
            local elapsed
            elapsed="$(ui_fmt_secs "$(ui_elapsed)")"
            local cpu=""
            if command -v ps >/dev/null 2>&1; then
                local sample
                sample="$(ps -axo %cpu=,comm= 2>/dev/null | awk '
                    tolower($2) ~ /swift/ { cpu+=$1 }
                    END { if (cpu>0) printf "%.0f", cpu }
                ')"
                [[ -n "$sample" ]] && cpu=" · cpu ${sample}%"
            fi
            if (( UI_COLOR )); then
                printf '  %s…%s %s  %s(%s%s)%s\n' \
                    "$UI_DIM" "$UI_RESET" "$label" \
                    "$UI_DIM" "$elapsed" "$cpu" "$UI_RESET"
            else
                printf '  … %s  (%s%s)\n' "$label" "$elapsed" "$cpu"
            fi
        done
    ) &
    UI_ACTIVITY_PID=$!
}

ui_activity_stop() {
    if [[ -n "${UI_ACTIVITY_PID:-}" ]] && kill -0 "$UI_ACTIVITY_PID" 2>/dev/null; then
        kill "$UI_ACTIVITY_PID" 2>/dev/null || true
        wait "$UI_ACTIVITY_PID" 2>/dev/null || true
    fi
    UI_ACTIVITY_PID=""
}

# ── Build-output polish ───────────────────────────────────────────────────────

if [[ -z "${UI_REPO_ROOT:-}" ]]; then
    UI_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

ui_shorten_text() {
    local s="$1"
    local home="${HOME:-}"
    local root="${UI_REPO_ROOT:-}"
    if [[ -n "$root" ]]; then
        s="${s//$root\//}"
        s="${s//$root/}"
    fi
    if [[ -n "$home" ]]; then
        s="${s//$home\//~/}"
        s="${s//$home/~}"
    fi
    local news
    while [[ "$s" == *"/../"* ]]; do
        news="$(sed -E 's|/[^/]+/\.\./|/|g' <<<"$s")"
        [[ "$news" == "$s" ]] && break
        s="$news"
    done
    printf '%s' "$s"
}

# Color one build/tooling line (build.sh markers, Swift PM, codesign).
ui_colorize_build_line() {
    local line="$1"

    if (( ! UI_COLOR )); then
        if [[ "$line" =~ ^[[:space:]]*\[([0-9]+)\/([0-9]+)\][[:space:]]+(.*)$ ]]; then
            printf '  [%s/%s] %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
            return
        fi
        printf '  %s\n' "$line"
        return
    fi

    # build.sh stage markers
    if [[ "$line" =~ ^[[:space:]]*▸[[:space:]]+(.*)$ ]]; then
        printf '  %s▸%s %s%s%s\n' "$UI_CYAN$UI_BOLD" "$UI_RESET" "$UI_BOLD" "${BASH_REMATCH[1]}" "$UI_RESET"
        return
    fi

    # Success markers from build.sh
    if [[ "$line" =~ ^[[:space:]]*✓[[:space:]]+(.*)$ ]]; then
        printf '  %s✓%s %s\n' "$UI_GREEN$UI_BOLD" "$UI_RESET" "${BASH_REMATCH[1]}"
        return
    fi

    # Failure
    if [[ "$line" =~ ^[[:space:]]*✗[[:space:]]+(.*)$ ]]; then
        printf '  %s✗%s %s\n' "$UI_RED$UI_BOLD" "$UI_RESET" "${BASH_REMATCH[1]}" >&2
        return
    fi

    # Indent + dim signing / secondary chatter
    if [[ "$line" =~ ^[[:space:]]*(signing|re-signing|stamped|legacy) ]]; then
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        printf '  %s%s%s\n' "$UI_DIM" "$trimmed" "$UI_RESET"
        return
    fi

    # Swift PM style: [3/5] Compiling …
    if [[ "$line" =~ ^[[:space:]]*\[([0-9]+)\/([0-9]+)\][[:space:]]+(.*)$ ]]; then
        printf '  %s[%s%s%s/%s%s%s]%s %s\n' \
            "$UI_CYAN$UI_BOLD" "$UI_RESET$UI_CYAN$UI_BOLD" "${BASH_REMATCH[1]}" \
            "$UI_DIM" "$UI_CYAN" "${BASH_REMATCH[2]}" "$UI_RESET$UI_CYAN$UI_BOLD" "$UI_RESET" \
            "${BASH_REMATCH[3]}"
        return
    fi

    # Swift: Build complete! (13.04s)
    if [[ "$line" =~ ^[[:space:]]*(Build\ complete!)[[:space:]]*\(([0-9.]+s)\) ]]; then
        printf '  %s%s%s  %s(%s)%s\n' \
            "$UI_GREEN$UI_BOLD" "${BASH_REMATCH[1]}" "$UI_RESET" \
            "$UI_CYAN" "${BASH_REMATCH[2]}" "$UI_RESET"
        return
    fi

    # error: / warning:
    if [[ "$line" =~ error: ]]; then
        printf '  %s%s%s\n' "$UI_RED" "$line" "$UI_RESET" >&2
        return
    fi
    if [[ "$line" =~ warning: ]]; then
        printf '  %s%s%s\n' "$UI_YELLOW" "$line" "$UI_RESET" >&2
        return
    fi

    printf '  %s\n' "$line"
}

# Filter stdin → stdout: shorten paths, then colorize.
ui_filter_build() {
    local line short
    while IFS= read -r line || [[ -n "$line" ]]; do
        short="$(ui_shorten_text "$line")"
        ui_colorize_build_line "$short"
    done
}

# Run a command with polished stdout+stderr. Preserves exit status.
ui_run() {
    local ec
    set +e
    if command -v stdbuf >/dev/null 2>&1; then
        stdbuf -oL -eL "$@" 2>&1 | ui_filter_build
    else
        "$@" 2>&1 | ui_filter_build
    fi
    ec=${PIPESTATUS[0]}
    set -e
    return "$ec"
}
