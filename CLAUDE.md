# ErrandBoy — Investor Demo

Interactive product demo for ErrandBoy, a consumer returns service: a runner picks up your return at the door, packages it, drops it at the carrier, and every handoff is photo-verified. Three personas (Customer, Runner, Founder) rendered inside a phone frame with a pitch-note rail for live investor demos.

## Commands

- `npm run dev` — local dev server
- `npm run build` — production build (must pass before any commit)

## Architecture

- Vite + React 18, zero other runtime dependencies. Keep it that way unless a feature is impossible without one.
- Everything currently lives in `src/App.jsx`. If you split it, split by persona (`screens/customer/`, `screens/runner/`, `screens/founder/`) plus `ui.jsx` (shared primitives: Status, Nav, DrawnCheck, icons) and `tokens.js`. Do not introduce a state library; `useState` at the root is sufficient.
- All demo data (item, custody steps, pitch notes, metrics) lives in plain constants at the top of the file. Keep data and presentation separated so numbers can be updated before a pitch without touching layout.

## Design constitution — read before writing any UI

The founder's product principles are **simplicity and delight**. The bar is Apple. The previous version was rejected for looking AI-generated. These rules are not preferences; they are requirements.

**Never do these (the "AI tells"):**
- No emoji as icons. Icons are hand-drawn inline SVG, 1.5–1.6px stroke, round caps. Extend the `ic` map; do not add an icon library.
- No uppercase letter-spaced micro-labels (`LIKE THIS`). Labels are sentence case, 12.5–14px, gray.
- No badge pills, chips with borders, or status tags. State is shown through color of text, a single dot, or weight.
- No bordered cards. Surfaces separate by background contrast: warm-gray canvas `#F5F4F2`, white groups, iOS-Settings-style inset hairlines (`.eb-row + .eb-row`) only inside grouped lists.
- No second typeface. Hanken Grotesk only; hierarchy comes from size and weight. Numerals use `.num` (tabular).
- No confetti, no gradients-as-decoration, no stagger-animating every list. Motion budget: the drawn checkmark, the counting numeral, the breathing live-dot, the route dash. That's it. Respect `prefers-reduced-motion`.
- No new colors. Palette is ink `#161617`, sub `#86868B`, canvas `#F5F4F2`, white, and pine `#0E6B4F`. Pine is reserved exclusively for money and proof. If a design needs another color, the design is wrong.

**Always:**
- Copy is part of the design. Plain verbs, sentence case, no filler. Buttons say what happens ("Pay $14.50", not "Submit").
- Whitespace before chrome. If two elements need separating, try spacing before adding any line or box.
- One delight moment per flow, executed precisely, not three executed loosely.

## Product / pitch content rules

- The Founder screen must always answer, in order: unit economics (contribution margin per order), retention (cohort grid), the ask tied to milestones, and the three kill risks with answers. Never replace these with vanity metrics (downloads, GMV alone).
- The business story is: batching (4 returns → 1 carrier run) is the unit-economics unlock; the chain-of-custody record is the eventual B2B/acquisition asset. Any new feature should reinforce one of those two.
- Pitch notes in the rail are spoken lines for a live demo. One sentence each, operator's voice.

## Verification

After any change: `npm run build`, then run dev and click the full golden path — Customer: home → snap two photos → window → pay → watch tracking auto-advance → done screen counter; Runner: feed → accept → three checks; Founder: scroll full screen. Check at 390px width.
