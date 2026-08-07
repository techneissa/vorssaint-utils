# Vorssaint utils — SpaciousTech custom-ui fork
#
# Workflow (Homebrew-like local install of your custom build):
#   just install   → incremental release build → /Applications/Vorssaint (Developer).app
#   just run       → install + launch
#
# Edit UI → just install again. Warm/no-change is near-instant; UI-only rebuilds
# are typically ~1–2 min (not the 5–15 min full ./build.sh wipe).
#
#   just build-optimized / run-optimized  → upstream ./build.sh -O (slowest)
#
# CLI: scripts/dev-run.sh · NO_COLOR=1 · FORCE_COLOR=1

set shell := ["bash", "-cu"]

default:
    @just --list

# Incremental release → build/stage only
build:
    bash scripts/dev-run.sh --build --dev

# Build + install to /Applications/Vorssaint (Developer).app (fully usable)
install:
    bash scripts/dev-run.sh --install --dev

# Install + launch
run:
    bash scripts/dev-run.sh --run --dev

# Unit tests
test:
    bash scripts/dev-run.sh --test

# Upstream ./build.sh full swiftc -O (slow)
build-optimized:
    bash scripts/dev-run.sh --build --dev --optimized

install-optimized:
    bash scripts/dev-run.sh --install --dev --optimized

run-optimized:
    bash scripts/dev-run.sh --run --dev --optimized

# Official-named Vorssaint.app (overwrites that name if present)
build-release:
    bash scripts/dev-run.sh --build --release

install-release:
    bash scripts/dev-run.sh --install --release

run-release:
    bash scripts/dev-run.sh --run --release
