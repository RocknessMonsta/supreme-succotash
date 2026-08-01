# ErrandBoy — Investor Demo

Returns, handled. Two photos, one flat price, proof at every handoff.

## Run it

```bash
npm install
npm run dev
```

Open the printed localhost URL. Use the segmented control to switch personas; the rail shows the spoken pitch note for each screen. "Reset demo" returns everything to the opening state before a live pitch.

## Working on it with Claude Code

Open this folder and just describe the change — `CLAUDE.md` carries the design constitution (banned patterns, palette, motion budget) and the pitch-content rules, so generated UI stays on-brand.

## Repository status

This branch consolidates the repository: ErrandBoy (previously stranded on
`claude/build-out-y26nsn`) is now at the root alongside the project docs.
See [REFACTOR_PLAN.md](REFACTOR_PLAN.md) for the full audit and remaining
steps, and [docs/DECISIONS.md](docs/DECISIONS.md) for open decisions — notably
where the Bendak/dueling-arena game on
`claude/kotor-porting-feasibility-b82oop` should live (separate repo
recommended; that branch is untouched).
