# supreme-succotash

**Status:** Bootstrapping — Phase 1 in progress. See [REFACTOR_PLAN.md](REFACTOR_PLAN.md).

## What is this?

This repository holds the **ErrandBoy investor demo** (React 18 + Vite —
"Returns, handled") and a Three.js mini-game, currently stranded on unmerged
side branches (`claude/build-out-y26nsn` and
`claude/kotor-porting-feasibility-b82oop`). The refactor plan consolidates
ErrandBoy onto a real `main` branch.

## ⚡ Decisions needed (see REFACTOR_PLAN.md §3)

1. Confirm ErrandBoy becomes `main`.
2. Game: separate repo (recommended) or `games/` folder here?
3. Anything in-flight on the side branches to preserve first?

## Project layout

```
supreme-succotash/
├── README.md          # This file
├── REFACTOR_PLAN.md   # Phased bootstrap/refactor plan
├── CLAUDE.md          # AI assistant guide
└── docs/
    └── DECISIONS.md   # Running log of project decisions
```

`src/` and `tests/` are created in the stack-specific part of Phase 1.

## Workflow

- Branch from the default branch; small, reviewable commits.
- Commit format: `type: description` (`feat`, `fix`, `docs`, `refactor`,
  `test`, `chore`).
- Every feature lands with tests once the stack exists.
