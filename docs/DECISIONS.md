# Decision Log

Running log of project decisions. Newest first.

| Date | Decision | Rationale | Decided by |
|------|----------|-----------|------------|
| 2026-08-01 | Executed consolidation on the review branch (PR #1) rather than waiting | Owner directive "get this going asap"; merge of ErrandBoy into this branch is reversible and lands on the default branch via one PR merge | Claude (per owner's directive) |
| 2026-08-01 | Refactor = repository surgery, not code rewrite | Code found intact on side branches (ErrandBoy demo, Bendak game); the broken part is branch structure — default branch is empty; see REFACTOR_PLAN.md §1–2 | Claude (pending owner confirmation) |
| 2026-08-01 | Stack-neutral foundation committed before restructure | Keep momentum while owner reviews the plan | Claude (per owner's directive) |

## Open decisions (owner input required)

1. Confirm ErrandBoy (`claude/build-out-y26nsn`) becomes `main`.
2. Bendak/dueling-arena game: separate repo (recommended) or `games/` here?
3. Any in-flight work on side branches to preserve before restructuring.

Record answers here when they land.
