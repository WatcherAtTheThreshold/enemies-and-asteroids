# Moonbase Defender — Development Plan

---

## Vision

A short roguelike arcade game with a hidden mythos layer. On the surface: a scrappy pilot defends a moonbase from a meteor storm and a mysterious enemy force. Underneath: something ancient and wrong is pulling the strings.

The tone is Saturday-morning cartoon on the surface — Speed Racer, Voltron, Star Wars Rebels — with a Lovecraftian twist revealed only at the end. Players who pay attention will notice the hints. Players who don't will still get a complete satisfying game.

The story is told almost entirely in images with minimal text. The Eye of Shoggoth symbol appears three times: in the intro (unexplained), as a flash on enemies mid-game (hinted), and on the pilot's forehead in the victory portrait (payoff). First playthrough it's mysterious. Second playthrough it recontextualises everything.

Target: a run lasts ~40 days. Days go by fast and the player loses track of time in the good way — the difficulty curve needs to stay ahead of the player curve the whole way. New threats introduced at key milestones reset the power dynamic before the cruise phase sets in.

---

## Priority Order

### 1. Intro Dialogue System ✓ (built, tuning ongoing)

A short sequence before gameplay. Scrolling star background, two portrait characters, auto-advancing dialogue.

**Sequence:**
1. Stars scrolling. Eye of Shoggoth symbol fades in, holds ~3s, fades out. No text. No explanation.
2. Pilot slides in from left (cinematic, 1.2s) — *"Moonbase, come in!"*
3. Base operator slides in from right — *"We're in trouble! Please stop the meteor storm!"*
4. Fade to black → game starts

**Characters:**
- **The Pilot** — Speed Racer / Voltron / Rebels energy. Cockpit portrait, stars behind her.
- **Moonbase Operator** — at a console, silhouettes visible in the background.

**Future dialogue hooks:**
- On first enemy day: Operator — *"Strange signal on approach..."* (triggers from EnemySpawner signal)
- On Mega Asteroid event: Operator — *"That's not a meteor — it's enormous!"*

**Assets needed:**
- `pilot1.png` ✓
- `base1.png` ✓
- `eye-of-shoggoth.png` ✓
- `pilot-marked.png` — pilot portrait with Eye of Shoggoth symbol on forehead (victory ending image)

**Serendipity note — do not change:** The intro background has a green bloom nebula that lands directly behind the Eye of Shoggoth symbol. It reads as the alien origin point — the place the symbol is pointing to. This was unplanned and is better than anything designed deliberately. The symbol position (640, 360) and the background image must stay as-is to preserve this.

---

### 2. Win Condition — Defeat the Mega Asteroid

The win condition is not surviving a day count — it's defeating the Mega Asteroid at day 30. Surviving day 30 with asteroids still in play is not enough. The Mega Asteroid must be destroyed.

**Day 30 event sequence:**
1. Asteroid spawner stops. Normal asteroids drift off screen.
2. Background shifts — darker, fewer stars. Atmosphere changes.
3. Brief inversion flash effect (bright frames, anime action style) — fast and disorienting.
4. Mega Asteroid descends slowly. Operator: *"That's not a meteor — it's enormous!"*
5. Player fights the Mega Asteroid as the final boss.
6. If player dies → Game Over (normal).
7. If Mega Asteroid destroyed → Victory sequence.

**Victory sequence:**
- Screen flash and shake on kill.
- Operator: *"You did it! We're safe!"*
- Pilot portrait slides in — **symbol of the Eye of Shoggoth on her forehead.** No explanation.
- Victory music + fireworks.
- Fade to Start Screen.

**The mythos payoff:** The pilot doesn't say anything. The symbol is just there. The player connects it to the intro. That's the whole story.

**What needs to exist:**
- `Main.gd` triggers Mega Asteroid event at day 30 instead of routing to next day
- `MegaAsteroid.tscn` / `MegaAsteroid.gd` — final boss
- Inversion flash effect (full-screen ColorRect, rapid modulate flicker)
- `VictoryScene.tscn` — pilot-marked portrait, fireworks, music
- `pilot-marked.png` — pilot with symbol on forehead (key asset)
- Victory music track

---

### 3. Multiple and Varied Enemy Ships

**Multiple ships simultaneously:**
- `EnemySpawner` currently allows one active enemy. Allow 2+ from day 12+.
- Day 12: 2 ships. Day 16+: up to 3.

**New ship variant — the Interceptor:**
- Faster, less HP than the current Battlecruiser
- Fires projectiles only (no missiles) at higher rate
- Drops fewer resources — more of a harassment unit
- Easy to mock up visually as a resized/recolored enemy sprite

**Ship naming for flavour:**
- Current ship → "Battlecruiser" (slow, heavy, missiles + projectiles)
- New ship → "Interceptor" (fast, light, projectiles only)

---

### 4. Mega Asteroid (Final Boss)

The climax of the run. See Win Condition section for full sequence.

**Boss behaviour:**
- Descends slowly and deliberately — feels inevitable
- High HP (150+), scaled to day 30 difficulty
- Fires bursts of smaller asteroids at damage phase thresholds (75%, 50%, 25% HP)
- Inversion flash effect pulses occasionally during the fight — bright frames, disorienting
- Enemies occasionally flash to show tentacles / wrong geometry (enemy modulate flicker in sickly purple-green — art swap later)
- On death: massive screen shake, explosion, victory trigger

**The enemy flash hint:**
From day 15+ onwards, enemy ships occasionally flicker for 2–3 frames showing something wrong — tentacles, or a color/distortion shift (purple-green modulate). Not explained. Connects to the Eye of Shoggoth. A color flash is achievable now; a sprite swap can come later when art exists.

**Technical approach:**
- `MegaAsteroid.tscn` / `MegaAsteroid.gd`
- Inversion flash: full-screen ColorRect, rapid modulate between normal and inverted for a few frames
- Enemy flicker: occasional tween on enemy modulate in `EnemyShip.gd`, triggered on a random timer

---

### 5. Visual Upgrade States

Right now upgrades are numbers. This pass makes them visible on the ship and base.

**Ideas per upgrade:**
| Upgrade | Visual change |
|---------|--------------|
| Overcharge | Ship weapon glow / tint |
| Expand Cockpit | Slightly larger ship sprite or cockpit detail |
| Rapid Fire | Exhaust trail gets more intense |
| Reinforce Base | Visible armor plating added to base sprite |
| Reinforce Hull | Base color shifts slightly warmer |
| Deploy Turret | Already visual — turrets appear |
| Turret Upgrade | Turret sprite changes (glows, gains detail) |

**Approach:** sprite swaps or modulate tints driven by upgrade counters tracked on Player/Base nodes. No new systems needed — just art + a few conditionals in the upgrade apply logic.

---

## Upgrade Design Notes

The current upgrade set runs a bit generic. Once the win condition and run length are fixed, a pass on upgrade naming and specificity would help. Goals:

- Each upgrade should feel like it belongs to a character build
- Names should have personality ("Overcharge" is good, "Repair Base" is flat)
- Consider 2–3 upgrade paths that feel distinct: aggressive (damage), defensive (HP/shields), tactical (turrets/spawn control)
- Mutually exclusive upgrades (pick one of two) could make runs feel more different

---

## Difficulty Arc (Three Acts)

- **Days 1–12:** Asteroids are the main threat. Enemy ship appears every 3 days — scary but manageable.
- **Days 13–29:** Enemy variety becomes the dominant pressure. Interceptors appear, multiple ships possible. Enemy flicker hints begin. Asteroids stay intense.
- **Day 30:** Asteroids stop. Background shifts. Inversion flash. Mega Asteroid descends. Final boss fight. Win or die.

New threats at act boundaries reset the power dynamic before the cruise phase sets in.

---

## Architecture Notes

A full GameFlow refactor is **not needed**. `Main.gd` is clean and readable at ~110 lines. Each new feature slots in without restructuring:

- **IntroScene** — StartScreen routes to it before Main. Main never knows it existed.
- **VictoryScene** — one extra branch in Main's day-end logic. Five lines.
- **Multiple enemies** — lives in EnemySpawner only.
- **Mega Asteroid** — one trigger check in Main's day cycle.

Incremental additions are the right approach. No new root node, no project migration needed.

---

## Open Questions

- **Run length:** Day 30 as win condition (Mega Asteroid fight) — revisit after boss is built and playtested.
- **Skip intro:** After the first run, should the intro be skippable from the start screen?
- **Voice acting:** Real recordings or synthesized? Scoped as optional/later.
- **Scoring:** Is there a score or is survival the only metric?
- **Mobile:** Is HTML5/mobile a target? (Affects control scheme considerations)
