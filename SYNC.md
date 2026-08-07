# SYNC.md — READ THIS BEFORE CHANGING ANYTHING

> **Agent warning:** This is **not** a normal clone of upstream. It is a personal fork
> (`SpaciousTech/vorssaint-utils`) whose `custom-ui` branch carries local look-and-feel
> work and is periodically **rebased** onto upstream **release tags**.
>
> Optimize for **easy, fast upstream syncs with minimal merge conflicts**.
> If a change makes the next rebase harder, it is the wrong change.

Entry point for agents: [`AGENTS.md`](./AGENTS.md). Human workflow details live in [`FORK.md`](./FORK.md). This file is the policy agents must follow.

---

## What this repo/branch is

| Item | Meaning |
|------|---------|
| Upstream | [vorssaint/vorssaint-utils](https://github.com/vorssaint/vorssaint-utils) |
| Fork | [SpaciousTech/vorssaint-utils](https://github.com/SpaciousTech/vorssaint-utils) |
| Working branch | `custom-ui` (long-lived; all personal UI work lives here) |
| `main` | Exact mirror of a chosen upstream **tag** (e.g. `v3.3.0`). Never commit features here. |
| Sync model | Tag → reset `main` → rebase `custom-ui`. Not continuous tracking of upstream `main`. |

Remotes:

- `origin` → fork (push OK)
- `upstream` → official repo (**push DISABLED**)

---

## Hard rules (do not violate)

1. **Work on `custom-ui` only.** Never commit customizations to `main`.
2. **Prefer new fork-owned files** over editing upstream-owned files.
3. **Do not modify `build.sh` or `Package.swift` for UI skinning or CLI polish.** Release compile already uses `Sources/Vorssaint/**/*.swift`. Fork CLI lives under `scripts/` (`dev-run.sh`, `lib/cli-ui.sh`).
4. **Do not add an SPM / path dependency on PraxisUI** (or any design-system package). Vendored Swift under this tree only.
5. **Do not mass-edit call sites** across MenuPanel / Settings / etc. Restyle through shared helpers so upstream can keep adding views without fork churn.
6. **Keep commits small and scoped** (`ui: …`). One concern per commit.
7. **Do not force-push `main` or rebase `custom-ui` unless the user explicitly asked to sync.** Day-to-day work is normal commits on `custom-ui`.

---

## Conflict-minimizing UI strategy

Goal: Praxis-like buttons, tints, radii, chip chrome — with a **tiny** rebase surface.

### Put almost everything here (fork-owned, low conflict)

```text
Sources/Vorssaint/UI/Praxis/     ← NEW files only; upstream will not own these
  DesignTokens.swift
  TintedChipChrome.swift
  ButtonStyle.swift
  PanelCardModifier.swift
  …other look primitives
```

These files should contain the look: tokens, chip chrome, button styles, card modifiers, accent helpers. Copy/adapt from sibling `gitClones/PraxisUI` as needed — **vendor code, do not link the package**.

### Allowed upstream-file patches (keep tiny)

Touch **as few lines as possible**, and only to **rewire implementations** while keeping APIs/signatures stable:

| File | Allowed change |
|------|----------------|
| `Sources/Vorssaint/UI/Theme.swift` | Point `panelCard()`, `PanelSurface`, `sectionTitle`, etc. at Praxis helpers |
| `Sources/Vorssaint/UI/SharedUI.swift` | Only if HUD/shared chrome must call Praxis primitives |
| One shared button helper (e.g. in `MenuPanelView.swift`) | Swap implementation to Praxis-styled control — prefer not spreading edits |

Upstream screens that already call `panelCard()` / shared buttons then inherit the skin **without further fork edits**.

### Forbidden patterns (high conflict)

- Spreading `PraxisButton` / tint changes across dozens of view files
- Rewriting layout structure in large upstream views “while we’re here”
- Editing `build.sh`, `Package.swift`, App/ menu-bar code unless the user explicitly wants that surface
- Renaming or deleting upstream Theme APIs that other files call

---

## When the user asks to sync upstream

Typical flow (user must request this; do not freestyle):

```bash
git fetch upstream --tags
# Review CHANGELOG / git log <old-tag>..<new-tag> — prefer minor/major; skip noisy patches unless needed

git switch main
git reset --hard <new-tag>
git push origin main --force

git switch custom-ui
git rebase main
```

If conflicts appear:

1. Expect them mainly in the **tiny bridge files** (`Theme.swift`, maybe `SharedUI.swift`), not in `UI/Praxis/`.
2. Prefer **upstream structure**; then **re-apply the small rewires** to Praxis helpers.
3. `UI/Praxis/**` should usually take “ours” (fork) if a rare conflict appears.
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
- [ ] Can this live entirely under `Sources/Vorssaint/UI/Praxis/`?
- [ ] If not, is the upstream edit a **minimal bridge** (same signature, new body)?
- [ ] Avoiding `build.sh` / `Package.swift` / SPM?
- [ ] Avoiding drive-by refactors outside the look-and-feel goal?

After editing:

- [ ] `just build` (and `just test` when behavior might break)
- [ ] Diff is mostly new Praxis files + tiny Theme/SharedUI bridge
- [ ] Fork-owned CLI lives under `scripts/` (`dev-run.sh`, `lib/cli-ui.sh`) — do not put this in upstream `build.sh`

After a successful upstream sync, prefer `just build && just test` before tagging.

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
                         custom-ui             (Praxis skin + tiny bridges)
                              │
                         tag custom-vX.Y.Z     (rollback point)
```

**Minimize the red surface.** New files under `UI/Praxis/` are free. Every extra line changed in upstream-owned UI files is debt you pay on the next tag sync.
