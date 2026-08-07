# AGENTS.md

**Read these before changing anything in this fork:**

1. [`SYNC.md`](./SYNC.md) - required policy: what `custom-ui` is, conflict-minimizing UI rules, sync/rebase workflow
2. [`FORK.md`](./FORK.md) - human-oriented fork setup, remotes, day-to-day and tag-sync commands

This is **not** a normal upstream clone. Optimize for easy rebases onto upstream release tags.
Prefer new files under `Sources/Vorssaint/UI/Praxis/`; swap Settings/panel controls to shared
Praxis helpers; keep structural patches to upstream-owned UI tiny.

**Build / run:** `just install` puts a real release `.app` in `/Applications` (Developer
variant, bundle ID `com.vorssaint.utils.dev`). `just run` installs and launches. Loop:
edit → `just install` → reopen the Developer app. Default compile is incremental
`swift build -c release`. `just *-optimized` is the slow upstream `./build.sh` wipe path;
avoid for day-to-day.

Permissions for the official Vorssaint app do not apply to the Developer build; grant them
again for **Vorssaint (Developer)** in System Settings when needed.

CLI: `scripts/dev-run.sh` + `scripts/lib/cli-ui.sh`. `NO_COLOR=1` for plain text.
