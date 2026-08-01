# Taris Dueling Arena — Bendak's Challenge

A modernized fan-homage reimagining of the Taris dueling-ring mini-game from
*Star Wars: Knights of the Old Republic* (2003). Single self-contained HTML
file — no build step, no dependencies, no copyrighted assets (all visuals are
procedural canvas vector art).

## Play

Open `index.html` in any modern browser. That's it.

## What's "modernized"

The original arena fights used KOTOR's round-based, queue-and-pause d20
combat. This version keeps the **d20 rules engine intact** (attack rolls vs
Defense, crits on natural 19–20, damage dice — all rolls shown in the combat
log) but presents it as **real-time combat with ability cooldowns**, plus:

- **Tactical pause** (`Space`) — freeze time and queue your next action, as a
  nod to the original combat system
- Floating damage numbers, screen shake, particles, energy-shield bubbles
- A persistent career: win purses, buy weapon/armor upgrades, medpacs, and
  energy shields between fights (saved to `localStorage`)

## The ladder

Climb through five duelists — Deadeye Duncan, Gerlon Two-Fingers, Ice, Marl,
and reigning champion Twitch. Take the title, and a shady promoter offers one
last off-the-books match: an illegal **death match** against the retired
legend, **Bendak Starkiller**.

## Controls

| Input | Action |
|---|---|
| `1` | Blaster Shot — standard attack |
| `2` | Power Blast — −2 to hit, double damage (6s cooldown) |
| `3` | Rapid Shot — two shots at −4 each (8s cooldown) |
| `4` | Energy Shield — absorbs 30 damage (consumes item) |
| `5` | Medpac — heal 20+1d10 (consumes item) |
| `Q` | Dodge — +6 Defense for 1.5s (5s cooldown) |
| `Space` | Tactical pause / queue action |

All abilities are also clickable, so it works on touch devices.
