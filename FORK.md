# FORK.md - vorssaint-utils custom fork

> **Agents:** read [`SYNC.md`](./SYNC.md) first. That file is the policy for conflict-minimizing
> work on `custom-ui` (what to touch, what never to touch, how syncs work).

## Why this fork exists

This is a personal fork of [vorssaint/vorssaint-utils](https://github.com/vorssaint/vorssaint-utils).
It carries local UI/UX customizations under `Sources/Vorssaint/UI` while staying close to
upstream releases.

Upstream ships tags often. This fork syncs against **release tags**, not upstream `main`
HEAD, so update timing stays predictable and conflicts stay manageable.

## Branch policy

| Branch / tag | Role |
|--------------|------|
| `main` | Exact mirror of a chosen upstream release tag. Never commit features here. Safe to `reset --hard` to a newer tag. |
| `custom-ui` | Long-lived branch for all personal UI work. Rebase onto `main` after each chosen sync. |
| `custom-vX.Y.Z` | Snapshot tags of `custom-ui` after a successful rebase + build + test. Rollback points. |

## Remotes

```bash
origin   -> git@github.com:techneissa/vorssaint-utils.git   (push allowed)
upstream -> https://github.com/vorssaint/vorssaint-utils.git  (push disabled)
```

## One-time setup

```bash
git clone git@github.com:techneissa/vorssaint-utils.git
cd vorssaint-utils
git remote add upstream https://github.com/vorssaint/vorssaint-utils.git
git remote set-url --push upstream DISABLED
git fetch upstream --tags

git switch main
git reset --hard v3.3.0          # or whatever tag you pin to
git push origin main --force

git switch -c custom-ui
git push -u origin custom-ui
```

## Day-to-day: build and run

Your custom build installs like a local Homebrew app, next to any official Vorssaint:

| Command | What it does |
|---------|----------------|
| `just install` | Incremental release build → `/Applications/Vorssaint (Developer).app` |
| `just run` | Install + launch |
| `just build` | Compile/stage only (no `/Applications` copy) |
| `just test` | Unit tests |

Edit UI under `Sources/Vorssaint/UI`, then `just install` again. Warm/no-change rebuilds are
near-instant; UI-heavy rebuilds are often about 1 to 2 minutes.

Avoid `just *-optimized` unless you specifically want a full upstream `./build.sh -O` wipe
(that path is much slower, often 5 to 15+ minutes).

Launch the installed app with:

```bash
open "/Applications/Vorssaint (Developer).app"
```

### Developer app vs official app

| | Official / Homebrew | This fork (`just install`) |
|--|---------------------|----------------------------|
| App name | Vorssaint | Vorssaint (Developer) |
| Bundle ID | `com.vorssaint.utils` | `com.vorssaint.utils.dev` |
| Permissions | Separate TCC identity | Separate TCC identity |

macOS permissions granted to the official app **do not** apply to the Developer build.
Grant them again for **Vorssaint (Developer)** in System Settings.

**Sticky permissions across rebuilds:** macOS pins Accessibility / Screen Recording
to the app's code-signing identity. Ad-hoc signing breaks that on every install.
`just install` signs with your Apple Development cert when available (stable +
trusted), otherwise `Vorssaint Utils Signing`, and always keeps entitlements on
both stage and `/Applications` copies.

After a signing identity change (or if the portal stays on "Not granted" while
System Settings shows enabled):

```bash
tccutil reset Accessibility com.vorssaint.utils.dev
tccutil reset ScreenCapture com.vorssaint.utils.dev
just install
open "/Applications/Vorssaint (Developer).app"
```

Then grant **Vorssaint (Developer)** again in System Settings (or use Request).
Later installs with the same signer keep those grants.

## Making UI changes

Prefer new files under `Sources/Vorssaint/UI/Praxis/` (tokens, buttons, toggles, hover tint,
focus helpers). Touch upstream-owned screens only to swap in those shared controls.

```bash
git add Sources/Vorssaint/UI/...
git commit -m "ui: <short description>"
```

Commit style on this branch: short `ui: …` messages for look-and-feel work. Keep commits
small and scoped when you can.

Push when ready (normal push for day-to-day; force-with-lease only after a rebase/sync):

```bash
git push origin custom-ui
```

## Syncing with a new upstream release

Do not sync on every tag. Check `CHANGELOG.md` first. Prefer minor/major bumps
(`v3.x.0`); take patch releases only when they matter to you.

```bash
# 1. Pull tags and review
git fetch upstream --tags
git log <old-tag>..<new-tag> --oneline

# 2. Move the clean mirror
git switch main
git reset --hard <new-tag>
git push origin main --force

# 3. Rebase your work
git switch custom-ui
git rebase main
```

If conflicts occur:

```bash
git status
# resolve files
git add <resolved-files>
git rebase --continue
```

Abort if needed: `git rebase --abort`

## Finishing a sync

```bash
just build && just test
git push --force-with-lease origin custom-ui
git tag custom-<new-tag>
git push origin custom-<new-tag>
```

## Fallback

Official prebuilt binaries live under `ReleaseAssets` on each upstream release. Use those for
day-to-day when you do not need custom UI. Use the Developer build when you want your
customizations active.

## Auditing the delta

```bash
git diff --stat main...custom-ui
git log --oneline main..custom-ui
```
