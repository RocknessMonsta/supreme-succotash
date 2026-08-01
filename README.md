# supreme-succotash

**Status:** Bootstrapping — Phase 1 in progress. See [REFACTOR_PLAN.md](REFACTOR_PLAN.md).

## What is this?

The project's purpose is being defined. The repository previously contained no
source code; it is now being set up with a solid foundation so development can
start immediately once the product decisions land.

## ⚡ Decisions needed (blocking stack-specific work)

Answer in the Claude Code session or a comment on the
`claude/project-refactor-plan-r4fj1g` branch — one sentence each:

1. **Existing code?** Is there code that belongs here (local machine, another
   repo)? If yes, where?
2. **Purpose?** What should this software do, and for whom?
3. **Stack?** Any language/framework preference? (If none, one will be chosen
   and justified based on #2.)

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
