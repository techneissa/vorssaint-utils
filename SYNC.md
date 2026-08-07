# SYNC.md - READ THIS BEFORE CHANGING ANYTHING

> **Agent warning:** This is **not** a normal clone of upstream. It is a personal fork
> (`SpaciousTech/vorssaint-utils`) whose `custom-ui` branch carries local look-and-feel
> work and is periodically **rebased** onto upstream **release tags**.
>
> Optimize for **easy, fast upstream syncs with minimal merge conflicts**.
> If a change makes the next rebase harder, it is the wrong change.

Entry point for agents: [`AGENTS.md`](./AGENTS.md). Human workflow details live in
[`FORK.md`](./FORK.md). This file is the policy agents must follow.

---

## What this repo/branch is

| Item | Meaning |
|------|---------|
| Upstream | [vorssaint/vorssaint-utils](https://github.com/vorssaint/vorssaint-utils) |
| Fork | [SpaciousTech/vorssaint-utils](https://github.com/SpaciousTech/vorssaint-utils) |
| Working branch | `custom-ui` (long-lived; all personal UI work lives here) |
| `main` | Exact mirror of a chosen upstream **tag** (e.g. `v3.3.0`). Never commit features here. |
| Sync model | Tag → reset `main` → rebase `custom-ui`. Not continuous tracking of upstream `main`. |
| Local app | `/Applications/Vorssaint (Developer).app` (`com.vorssaint.utils.dev`) via `just install` |

Remotes:

- `origin` → fork (push OK)
- `upstream` → official repo (**push DISABLED**)

---

## Hard rules (do not violate)

1. **Work on `custom-ui` only.** Never commit customizations to `main`.
2. **Prefer new fork-owned files** over editing upstream-owned files.
3. **Do not modify `build.sh` or `Package.swift` for UI skinning or CLI polish.** Release
   compile already picks up `Sources/Vorssaint/**/*.swift`. Fork CLI lives under `scripts/`
   (`dev-run.sh`, `lib/cli-ui.sh`).
4. **Do not add an SPM / path dependency on PraxisUI** (or any design-system package).
   Vendored Swift under this tree only.
5. **Restyle through shared Praxis helpers** (`PraxisButton`, `PraxisSettingsToggle`,
   `TextToggleButton`, hover/focus modifiers). When skinning Settings or the panel, swap
   call sites to those helpers. Do not rewrite layout structure "while we are here."
6. **Keep commits small and scoped** (`ui: …`). One concern per commit when practical.
7. **Do not force-push `main` or rebase `custom-ui` unless the user explicitly asked to
   sync.** Day-to-day work is normal commits on `custom-ui`.

---

## Conflict-minimizing UI strategy

Goal: Praxis-like buttons, toggles, tints, radii, chip chrome, with a **small** rebase surface.

### Put look primitives here (fork-owned, low conflict)

```text
Sources/Vorssaint/UI/Praxis/     ← NEW files only; upstream will not own these
  PraxisDesignTokens.swift
  PraxisButton.swift
  PraxisSettingsToggle.swift
  TextToggleButton.swift
  PraxisHoverTint.swift
  PraxisFocusModifiers.swift
  …other look primitives
```

Copy/adapt from sibling `gitClones/PraxisUI` as needed. **Vendor code, do not link the package.**
Skip InfoHelp / adaptive Color APIs that pull in the full PraxisUI module; keep lean forks.

### Allowed upstream-file patches

Touch as few lines as possible. Prefer **rewiring to shared helpers** over inventing one-off chrome:

| Area | Allowed change |
|------|----------------|
| `Sources/Vorssaint/UI/Theme.swift` | Point shared chrome (`panelCard()`, surfaces, section titles) at Praxis helpers |
| `Sources/Vorssaint/UI/SharedUI.swift` | Only if HUD/shared chrome must call Praxis primitives |
| Settings / MenuPanel / related views | Replace `Toggle` / system `Button` with `PraxisSettingsToggle` / `PraxisButton` (or existing wrappers like `SettingsToggleWithCaption`). Keep structure and bindings. |
| Tiny Defaults keys | Only when a UI control needs a new preference (keep the key + default small) |

Upstream screens that already call shared Theme helpers then inherit the skin with less fork churn.

### Forbidden patterns (high conflict)

- Rewriting layout structure in large upstream views beyond the control swap
- Editing `build.sh`, `Package.swift`, or App/menu-bar lifecycle unless the user asks
- Renaming or deleting upstream Theme APIs that other files call
- Linking PraxisUI as an SPM dependency

### Developer build permissions

The Developer app uses bundle ID `com.vorssaint.utils.dev`. TCC grants for official
`com.vorssaint.utils` do not apply. If permission checks look wrong after `just install`,
grant again for **Vorssaint (Developer)** in System Settings. Do not "fix" this by changing
the bundle ID back to the release ID.

---

## When the user asks to sync upstream

Typical flow (user must request this; do not freestyle):

```bash
git fetch upstream --tags
# Review CHANGELOG / git log <old-tag>..<new-tag>
# Prefer minor/major; skip noisy patches unless needed

git switch main
git reset --hard <new-tag>
git push origin main --force

git switch custom-ui
git rebase main
```

If conflicts appear:

1. Expect them mainly where Settings/panel call sites or tiny Theme bridges changed, not in
   brand-new `UI/Praxis/` files.
2. Prefer **upstream structure**; then **re-apply** the Praxis helper swaps.
3. `UI/Praxis/**` should usually take "ours" (fork) if a rare conflict appears.
4. Abort safely with `git rebase --abort` if stuck; ask the user.

After a clean rebase:

```bash
just build && just test
git push --force-with-lease origin custom-ui
git tag custom-<new-tag>
git push origin custom-<new-tag>
```

---

## Day-to-day agent checklist

Before editing:

- [ ] On branch `custom-ui`?
- [ ] Can the look live under `Sources/Vorssaint/UI/Praxis/`?
- [ ] If touching upstream UI, is it a helper swap (same bindings/structure)?
- [ ] Avoiding `build.sh` / `Package.swift` / SPM?
- [ ] Avoiding drive-by refactors outside the look-and-feel goal?

After editing:

- [ ] `just install` (or `just build`) to verify; `just test` when behavior might break
- [ ] Quit/reopen **Vorssaint (Developer)** so `/Applications` picks up the new binary
- [ ] Diff is mostly Praxis files + helper swaps in Settings/panel (not layout rewrites)
- [ ] Fork-owned CLI stays under `scripts/` (`dev-run.sh`, `lib/cli-ui.sh`)

Audit fork delta anytime:

```bash
git diff --stat main...custom-ui
git log --oneline main..custom-ui
```

---

## Mental model

```text
upstream tag  ──reset──►  origin/main          (clean mirror, no custom commits)
                              │
                           rebase
                              ▼
                         custom-ui             (Praxis skin + helper swaps)
                              │
                         tag custom-vX.Y.Z     (rollback point)
```

**Minimize the red surface.** New files under `UI/Praxis/` are cheap. Every extra structural
change in upstream-owned UI files is debt on the next tag sync.
