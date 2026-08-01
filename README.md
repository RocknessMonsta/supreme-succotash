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

Everything now lives in this one repository — nothing stranded on side
branches anymore:

- **Root:** ErrandBoy investor demo (from `claude/build-out-y26nsn`).
- **`games/`:** the Bendak / Taris Dueling Arena Three.js games (from
  `claude/kotor-porting-feasibility-b82oop`) — open
  `games/bendak/index.html` or `games/dueling-arena/index.html` directly in
  a browser.

See [REFACTOR_PLAN.md](REFACTOR_PLAN.md) for the audit and
[docs/DECISIONS.md](docs/DECISIONS.md) for the decision log.
