# FORK.md — vorssaint-utils custom fork

> **Agents:** read [`SYNC.md`](./SYNC.md) first. It is the policy for conflict-minimizing
> work on `custom-ui` (what to touch, what never to touch, how syncs work).

## Why this fork exists

This is a personal fork of [vorssaint/vorssaint-utils](https://github.com/vorssaint/vorssaint-utils) that carries
local UI/UX customizations (`Sources/Vorssaint/UI`) while staying as close as possible to upstream releases.

Upstream ships new tags frequently (multiple per week at times), so this fork syncs against **release tags**,
not against upstream's `main` HEAD, to keep update timing predictable and conflicts manageable.

## Branch policy

- `main` — mirrors a specific upstream release tag exactly. Never commit here directly. Always safe to
  `reset --hard` to a newer upstream tag.
- `custom-ui` — long-lived branch carrying all personal UI changes, rebased onto `main` after each chosen sync.
- Tags `custom-vX.Y.Z` — snapshots of `custom-ui` after a successful rebase + build + test, used as rollback points.

## Remotes

```bash
origin   -> git@github.com:SpaciousTech/vorssaint-utils.git   (push allowed)
upstream -> https://github.com/vorssaint/vorssaint-utils.git  (push disabled)
```

## One-time setup

```bash
git clone git@github.com:SpaciousTech/vorssaint-utils.git
cd vorssaint-utils
git remote add upstream https://github.com/vorssaint/vorssaint-utils.git
git remote set-url --push upstream DISABLED
git fetch upstream --tags

git switch main
git reset --hard v3.3.0
git push origin main --force

git switch -c custom-ui v3.3.0
git push -u origin custom-ui
```

## Making changes

Work only in `Sources/Vorssaint/UI` (or new files of your own) whenever possible. Keep commits small and scoped:

```bash
git add Sources/Vorssaint/UI/...
git commit -m "ui: <short description>"
```

Install your custom build like a local Homebrew app:

```bash
just install    # → /Applications/Vorssaint (Developer).app (release, incremental)
just run        # install + launch
```

Edit UI under `Sources/Vorssaint/UI`, then `just install` again. Avoid `just *-optimized`
unless you specifically want a full upstream `./build.sh -O` rebuild.

## Syncing with a new upstream release

Don't sync on every tag — check `CHANGELOG.md` first and decide if the release matters to you
(always review minor/major bumps like `v3.x.0`; patch releases `v3.x.y` are optional unless they fix
something relevant).

```bash
# 1. Pull latest tags and review what changed
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

Official prebuilt binaries are published under `ReleaseAssets` in each upstream release. Use those for
day-to-day use when your UI changes aren't needed, and switch to a `custom-ui` build only when you want
your customizations active. This decouples "staying current" from "keeping my UI tweaks."

## Auditing the delta

```bash
git diff --stat main...custom-ui
git log --oneline main..custom-ui
```
