# Bendak Starkiller — Death Match

A first-person 3D reimagining of the illegal death match against **Bendak
Starkiller** from the Taris dueling ring in *Star Wars: Knights of the Old
Republic* (2003) — rebuilt the way a modern remake might frame it: you step
into the ring yourself, but every shot is still resolved by the original-style
**d20 rules engine** under the hood.

## Play

Serve this folder over HTTP and open `index.html` — or play straight from the
repo via githack:

```
https://raw.githack.com/RocknessMonsta/supreme-succotash/claude/kotor-porting-feasibility-b82oop/bendak/index.html
```

Works on desktop and iPhone Safari (landscape). No build step, no external
CDN — the engine and all assets live in this folder.

## What's in the fight

- **Intro cinematic** — a low orbit around Bendak while the announcer works
  the crowd, then a fly-to-your-eyes countdown. Tap to skip.
- **First-person d20 combat** — attack rolls vs Defense, crits (19–20) deal
  double damage, every roll printed to the combat log.
- **A real opponent** — Bendak circles the ring, closes distance when
  enraged, pops medpacs and energy shields, throws one frag grenade, and
  flinches when your bolts land. At 33% health he enrages and speeds up.
- **A living arena** — up to 20 animated spectators on two gallery tiers who
  wave, argue, and cheer your crits; a scrolling holoboard; a mirror-polished
  ring floor; Taris towers on the horizon.
- **Kill cam** — win, and the ring goes slow-motion for a low orbit around
  the falling legend before the stats screen.
- **Tactical pause** (`Space`) — freeze time and queue your next action, as a
  nod to KOTOR's combat queue.

## Controls

| Input | Action |
|---|---|
| `1` | Blaster Shot |
| `2` | Power Blast — −2 to hit, double damage (6s cd) |
| `3` | Rapid Shot — two shots at −4 (8s cd) |
| `4` | Energy Shield — absorbs 30 (item) |
| `5` | Medpac — heal 20+1d10 (item) |
| `Q` | Dodge — +6 DEF for 1.6s |
| `A`/`D` or drag | Circle the ring |
| `Space` | Tactical pause / queue |

All abilities are tappable on touch devices.

## Tech

- **three.js r160**, vendored in `vendor/` (no CDN dependency)
- **Character**: Quaternius' CC0 animated soldier (`assets/Character_Soldier.gltf`),
  17 animations including `Idle_Shoot`, `HitReact`, and `Death`; Bendak is a
  gold-armored material variant, the crowd are hue-shifted clones sharing one
  rig (`SkeletonUtils.clone`)
- **Rendering**: ACES tonemapping, PMREM RoomEnvironment IBL, UnrealBloom
  (HDR-threshold), chromatic-aberration + vignette pass, PCFSoft shadows,
  `THREE.Reflector` mirror floor
- **Audio**: fully synthesized Web Audio — blaster sweeps, impacts, shield
  chimes, crowd murmur that swells on big hits, countdown beeps, victory
  fanfare, ambient tension drone
- **Balance**: stat lines tuned by Monte-Carlo simulation (~4,000 fights per
  candidate) to a ~55–60% win rate for attentive play, ~40s fights
- `?lite=1` forces the low-spec path; the game also auto-degrades (drops
  post-processing and the mirror) if it measures sustained low fps.

## Credits

- Character model: [Quaternius](https://quaternius.com) — CC0
- Engine: [three.js](https://threejs.org) — MIT
- Everything else (arena, audio, game code): original, written for this repo
