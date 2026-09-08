#!/usr/bin/env bash
# Compact diagnostic formatting for just run / ui_run.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$HERE/../lib/cli-ui.sh" ]]; then
    ROOT="$(cd "$HERE/../.." && pwd)"
    UI_LIB="$ROOT/scripts/lib/cli-ui.sh"
elif [[ -f "$HERE/cli-ui.sh" ]]; then
    ROOT="$HERE"
    UI_LIB="$HERE/cli-ui.sh"
else
    echo "cli-ui.sh not found next to this test or at scripts/lib/cli-ui.sh" >&2
    exit 1
fi

export UI_REPO_ROOT="$ROOT"
export NO_COLOR=1
export NO_LIVE=1
unset FORCE_COLOR
unset CLI_UI_LOADED KEYFORGE_CLI_UI_LOADED NEXUSLINK_CLI_UI_LOADED VORSSAINT_CLI_UI_LOADED
# shellcheck source=cli-ui.sh
source "$UI_LIB"

PASS=0
FAIL=0

assert_contains() {
    local name="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  PASS  $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $name"
        echo "        missing: $needle"
        echo "        got:"
        printf '%s\n' "$haystack" | sed 's/^/          /'
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local name="$1" haystack="$2" needle="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "  PASS  $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $name (unexpected: $needle)"
        FAIL=$((FAIL + 1))
    fi
}

if declare -F ui_err >/dev/null 2>&1; then
    echo "  PASS  declare -F ui_err"
    PASS=$((PASS + 1))
else
    echo "  FAIL  declare -F ui_err"
    FAIL=$((FAIL + 1))
fi

stripped="$(ui_strip_spm_target "CompileSwift Foo.swift (in target 'AppMac' from project 'App')")"
assert_not_contains "generic in-target strip" "$stripped" "in target"
assert_contains "keeps filename after strip" "$stripped" "Foo.swift"

stripped2="$(ui_strip_spm_target "Compiling AppMac ContentView.swift")"
assert_contains "generic compiling strip" "$stripped2" "Compiling ContentView.swift"
assert_not_contains "compiling strip drops target" "$stripped2" "AppMac"

swift_dump="$(cat <<EOF
Building for debugging...
[Planning deferred tasks]
[3 / 12] Compiling ContentView.swift
${ROOT}/src/ContentView.swift:1277:13: error: argument 'fillsContainer' must precede argument 'help'
src/GraphOverlay.swift:10:5: warning: unused variable 'x'
error: SwiftCompile normal arm64 ContentView.swift failed with a nonzero exit code. Command line:     cd ${ROOT}
Failed frontend command:
/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -c -filelist /tmp/sources -primary-file ContentView.swift -target arm64-apple-macos14.0
error: Build failed
** BUILD FAILED **
EOF
)"

swift_out="$(printf '%s\n' "$swift_dump" | ui_filter_build)"

assert_contains "swift error tag" "$swift_out" "[Error]: src/ContentView.swift:1277:13  argument 'fillsContainer' must precede argument 'help'"
assert_contains "swift warning tag" "$swift_out" "[Warning]: src/GraphOverlay.swift:10:5  unused variable 'x'"
assert_contains "xcodebuild failure banner" "$swift_out" "[Error]: BUILD FAILED"
assert_not_contains "no frontend dump" "$swift_out" "swift-frontend"
assert_not_contains "no Failed frontend" "$swift_out" "Failed frontend"
assert_not_contains "no Build failed echo" "$swift_out" "error: Build failed"
assert_not_contains "no SwiftCompile wrapper" "$swift_out" "SwiftCompile normal"

xcode27_dump="$(cat <<EOF
SwiftCompile normal arm64 Compiling\ BubbleGridView.swift ${ROOT}/src/BubbleGridView.swift (in target 'AppMac' from project 'App')
${ROOT}/src/BubbleGridView.swift:296:29: error: cannot convert value of type 'String' to specified type 'Int'
294 | }
295 |
296 | let probe: Int = "boom"
    |                  \`- error: cannot convert value of type 'String' to specified type 'Int'
Failed frontend command:
/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -c -primary-file BubbleGridView.swift
clang: error: linker command failed with exit code 1
xcodebuild: error: Unable to find a destination matching the provided destination specifier
** BUILD FAILED **
Building project App with scheme AppMac and configuration Debug
EOF
)"
xcode27_out="$(printf '%s\n' "$xcode27_dump" | ui_filter_build)"
assert_contains "xcode 27 file error" "$xcode27_out" "[Error]: src/BubbleGridView.swift:296:29  cannot convert value of type 'String' to specified type 'Int'"
assert_contains "clang linker error" "$xcode27_out" "[Error]: linker command failed with exit code 1"
assert_contains "xcodebuild destination error" "$xcode27_out" "[Error]: Unable to find a destination matching the provided destination specifier"
assert_contains "xcode 27 failure banner" "$xcode27_out" "[Error]: BUILD FAILED"
assert_not_contains "no swift source gutter" "$xcode27_out" "let probe"
assert_not_contains "no caret snippet" "$xcode27_out" "\`- error"
assert_not_contains "no scheme footer" "$xcode27_out" "Building project"

rust_dump="$(cat <<'EOF'
   Compiling demo-core v0.1.0
error[E0308]: mismatched types
   --> src/foo.rs:12:5
    |
 12 |     x
    |     ^ expected String, found i32
    = help: consider using `.to_string()`
error: could not compile `demo-core` (lib) due to 1 previous error
EOF
)"

rust_out="$(printf '%s\n' "$rust_dump" | ui_filter_build)"

assert_contains "rust error tag" "$rust_out" "[Error]: src/foo.rs:12:5  mismatched types (E0308)"
assert_not_contains "no rustc caret" "$rust_out" "expected String, found i32"
assert_not_contains "no could not compile" "$rust_out" "could not compile"

xcode_dump="$(cat <<EOF
note: Building targets in dependency order
CompileSwift normal arm64 ${ROOT}/src/BubbleGridView.swift (in target 'AppMac' from project 'App')
Ld ${ROOT}/.build/derived/Build/Products/Debug/App.app/Contents/MacOS/App normal (in target 'AppMac' from project 'App')
** BUILD SUCCEEDED **
EOF
)"

xcode_out="$(printf '%s\n' "$xcode_dump" | ui_filter_build)"

assert_contains "xcode compile filename" "$xcode_out" "BubbleGridView.swift"
assert_contains "xcode link verb" "$xcode_out" "linking"
assert_not_contains "no xcode chatter" "$xcode_out" "Building targets in dependency order"
assert_not_contains "no success banner" "$xcode_out" "BUILD SUCCEEDED"
assert_not_contains "no in-target in output" "$xcode_out" "in target"

pcm_dump="$(cat <<'EOF'
SwiftExplicitDependencyGeneratePcm arm64 .build/derived/ModuleCache.noindex/_Builtin_stdarg-9P1C2834I66PUTAGO9BZV972G.pcm
SwiftExplicitDependencyGeneratePcm arm64 .build/derived/ModuleCache.noindex/Foundation-879985IEG95S7QIEVVN42A7CR.pcm
SwiftExplicitDependencyGeneratePcm arm64 .build/derived/ModuleCache.noindex/Metal-1DRM4LUDJVVASX81C7TFNMRX7.pcm
CompileSwift normal arm64 src/BubbleGridView.swift
** BUILD SUCCEEDED **
EOF
)"
pcm_out="$(printf '%s\n' "$pcm_dump" | ui_filter_build)"
assert_contains "pcm dump still compiles" "$pcm_out" "BubbleGridView.swift"
assert_not_contains "no pcm action" "$pcm_out" "SwiftExplicitDependencyGeneratePcm"
assert_not_contains "no pcm path" "$pcm_out" "ModuleCache"
assert_not_contains "no pcm filename" "$pcm_out" "Foundation-"

plan_dump="$(cat <<EOF
Command line invocation:
Build settings from command line:
CODE_SIGNING_ALLOWED = NO
Resolve Package Graph
cd
cd /tmp/other-repo
write-file .build/derived/foo.json
builtin-copy -exclude .DS_Store
Copy .build/derived/Build/Products/Debug/App.swiftmodule/arm64-apple-macos.swiftdoc
CompileSwift normal arm64 src/ContentView.swift
** BUILD SUCCEEDED **
EOF
)"
plan_out="$(printf '%s\n' "$plan_dump" | ui_filter_build)"
assert_contains "keeps compile after planning" "$plan_out" "ContentView.swift"
assert_not_contains "no command line invocation" "$plan_out" "Command line invocation"
assert_not_contains "no resolve package graph" "$plan_out" "Resolve Package Graph"
assert_not_contains "no write-file" "$plan_out" "write-file"
assert_not_contains "no builtin-copy" "$plan_out" "builtin-copy"
assert_not_contains "no stray cd" "$plan_out" $'\ncd\n'

thin=$'\xe2\x80\x89'
thin_dump="[3${thin}/${thin}12] Compiling ThinFile.swift"
thin_out="$(printf '%s\n' "$thin_dump" | ui_filter_build)"
assert_contains "thin space spm progress" "$thin_out" "ThinFile.swift"

empty_spm_out="$(printf '%s\n' '[1 / 4]' '[3 / 4]' '[4 / 4]' | ui_filter_build)"
assert_contains "empty spm compiling" "$empty_spm_out" "[1/4] compiling"
assert_contains "empty spm linking" "$empty_spm_out" "[4/4] linking"
assert_not_contains "empty spm not working" "$empty_spm_out" "working"

vors_dump="$(cat <<'EOF'
▸ Compiling (release)
  signing as Apple Development
✓ Bundle ready
Build complete! (13.04s)
✗ link failed
EOF
)"
vors_out="$(printf '%s\n' "$vors_dump" | ui_filter_build 2>&1)"
assert_contains "build.sh stage marker" "$vors_out" "▸ Compiling (release)"
assert_contains "build.sh signing dim" "$vors_out" "signing as Apple Development"
assert_contains "build.sh ok marker" "$vors_out" "✓ Bundle ready"
assert_contains "build.sh complete" "$vors_out" "Build complete!"
assert_contains "build.sh fail marker" "$vors_out" "✗ link failed"

if declare -F ui_activity_start >/dev/null && declare -F ui_activity_stop >/dev/null \
    && declare -F ui_progress_update >/dev/null && declare -F ui_progress_close >/dev/null; then
    echo "  PASS  activity/progress API present"
    PASS=$((PASS + 1))
else
    echo "  FAIL  activity/progress API present"
    FAIL=$((FAIL + 1))
fi

ui_activity_start "compiling…" 60
ui_activity_stop
echo "  PASS  ui_activity start/stop"

PASS=$((PASS + 1))

UI_PROGRESS_LAST_PRINTED=0
UI_PROGRESS_OPEN=0
prog_out="$(ui_progress_update 5 5 "Linking")"
assert_contains "progress last job" "$prog_out" "[5/5] Linking"
ui_progress_close

color_probe="$(
    unset CLI_UI_LOADED KEYFORGE_CLI_UI_LOADED NEXUSLINK_CLI_UI_LOADED VORSSAINT_CLI_UI_LOADED
    export NO_COLOR=1 FORCE_COLOR=0 NO_LIVE=1
    unset UI_COLOR
    # shellcheck source=cli-ui.sh
    source "$UI_LIB"
    printf '%s' "$UI_COLOR"
)"
assert_contains "FORCE_COLOR=0 does not override NO_COLOR" "$color_probe" "0"

color_probe0="$(
    unset CLI_UI_LOADED KEYFORGE_CLI_UI_LOADED NEXUSLINK_CLI_UI_LOADED VORSSAINT_CLI_UI_LOADED
    unset NO_COLOR
    export FORCE_COLOR=0 NO_LIVE=1
    unset UI_COLOR
    # shellcheck source=cli-ui.sh
    source "$UI_LIB"
    printf '%s' "$UI_COLOR"
)"
assert_contains "FORCE_COLOR=0 forces off" "$color_probe0" "0"

echo
echo "  $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
