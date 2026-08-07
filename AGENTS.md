# AGENTS.md

**Read these before changing anything in this fork:**

1. [`SYNC.md`](./SYNC.md) — required policy: what `custom-ui` is, conflict-minimizing UI rules, sync/rebase workflow
2. [`FORK.md`](./FORK.md) — human-oriented fork setup, remotes, day-to-day and tag-sync commands

This is **not** a normal upstream clone. Optimize for easy rebases onto upstream release tags. Prefer new files under `Sources/Vorssaint/UI/Praxis/`; keep patches to upstream-owned UI files tiny.

**Build / run:** `just install` puts a real release `.app` in `/Applications` (Developer
variant). `just run` installs and launches. This is the Homebrew-like loop for UI work:
edit → `just install` → use the app. Default compile is incremental `swift build -c release`
(app runs fast; reinstalls stay practical). `just *-optimized` is the slow upstream
`./build.sh` wipe path — avoid for day-to-day.

CLI: `scripts/dev-run.sh` + `scripts/lib/cli-ui.sh`. `NO_COLOR=1` for plain text.
