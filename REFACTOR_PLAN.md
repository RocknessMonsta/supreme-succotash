# Project Refactor Plan — supreme-succotash

**Date:** 2026-08-01 (rev. 2 — updated after discovering code on side branches)
**Branch:** `claude/project-refactor-plan-r4fj1g`
**Status:** Ready for review

---

## 1. The Real Problem (root cause found)

Your code exists — it was never lost. **It's stranded on side branches that were
never merged**, while the repository's default branch contains only a `CLAUDE.md`
template. Anyone (human or AI) landing on the repo sees an empty project. That is
why every previous "refactor this project" attempt went nowhere.

### Full branch audit

| Branch | Contents | State |
|--------|----------|-------|
| `claude/claude-md-mk2xq84fd0d1g70k-H6sZH` | **Default branch.** Only `CLAUDE.md` (empty template) | The problem |
| `claude/build-out-y26nsn` | **ErrandBoy investor demo** — React 18 + Vite app, v2.0.0. Customer/Runner/Founder personas, ~20 screens, design system, pitch rail | Complete, unmerged |
| `claude/kotor-porting-feasibility-b82oop` | **Taris Dueling Arena / Bendak fight** — Three.js 3D mini-game with vendored three.js, GLTF character, post-processing | Complete, unmerged |
| `claude/project-refactor-plan-r4fj1g` | This plan + stack-neutral foundation files | Under review |

### ErrandBoy snapshot (the apparent flagship)

- "Returns, handled. Two photos, one flat price, proof at every handoff."
- React 18 + Vite, clean dependency footprint (react + react-dom only).
- Organized: `src/screens/{customer,runner,founder}/`, shared `ui.jsx`,
  `tokens.js` design tokens, `data.js`, demo-reset flow for live pitches.
- Has its own README and a CLAUDE.md "design constitution."

### The game (separate concern)

The Bendak arena is a self-contained static app (`bendak/`, `dueling-arena/`)
with ~25 vendored three.js files. It shares nothing with ErrandBoy — different
audience, different stack, no common code.

---

## 2. Recommended Refactor

The refactor here is **repository surgery, not code rewriting**. The ErrandBoy
code itself is in good shape; the repo structure is what's broken.

### Step 1 — Give the repo a real `main`
Create `main` from the ErrandBoy branch (`claude/build-out-y26nsn`) and make it
the default branch on GitHub. ErrandBoy lives at the repo root: clone → `npm
install` → `npm run dev` just works.

### Step 2 — Separate the game
Recommended: move the Bendak/dueling-arena game to its own repository (it's
fully self-contained), or — if you prefer one repo — keep it under `games/` on
`main`. My recommendation is a separate repo: the vendored three.js bloats
diffs and the two projects will never share code or releases.

### Step 3 — Merge the good parts of this branch
Fold this plan's foundation files (`.editorconfig`, decision log, updated
README/CLAUDE.md) into `main`, with `CLAUDE.md` rewritten to describe the real
stack (React 18/Vite, run commands, screen architecture, design constitution)
instead of "TBD" placeholders.

### Step 4 — Retire the stale branches
After merging: delete `claude/claude-md-*` as default, keep branches only for
in-flight work. Add branch protection on `main`.

### Step 5 (optional, after the above) — Code-level polish on ErrandBoy
Only if you want it: `App.jsx` and `ui.jsx` are the largest files and could be
split; add ESLint/Prettier; add a GitHub Actions build check. None of this
blocks the demo working today.

---

## 3. Decisions Needed From You (much smaller now)

1. **Confirm ErrandBoy is the primary project** for this repo (its `main`).
2. **Game placement:** separate repo (recommended) or `games/` folder here?
3. **Anything in-flight** on either side branch I should preserve before
   restructuring?

Default if I don't hear otherwise: I proceed with the recommendations —
ErrandBoy to `main`, game preserved on its branch untouched pending your call.

---

## 4. How We Communicate in Real Time (working setup)

- **This Claude Code session** (claude.ai/code, web or phone): messages reach
  me live, even mid-task — already proven both directions today. The session
  runs in the cloud; your machine locking doesn't stop it.
- **The review PR for this plan**: comment from the GitHub app on your phone —
  I'm subscribed, comments wake me immediately.
- **Push notifications** to your phone via the Claude app when work is ready.
- **SMS**: not possible from this environment today (no send-capable
  connector). One-time fix on your side: connect Twilio or Quo at claude.ai →
  Settings → Connectors, then I can text 336.391.8120 / 845.702.2154 directly.
- Every 60 minutes I automatically check for your replies and branch activity.

---

## 5. Next Step

Reply here or comment on the PR. Say "go with your recommendations" and Steps
1–4 happen the same day.
