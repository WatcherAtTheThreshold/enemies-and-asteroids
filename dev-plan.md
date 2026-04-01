# Moonbase Defender — Development Plan

---

## Vision

A short roguelike arcade game with a story. A scrappy pilot defends a moonbase from a meteor storm and a mysterious enemy force. Runs feel like a complete arc — intro, escalating danger, a climactic moment, and a victory or defeat. The tone is Saturday-morning cartoon: Speed Racer, Voltron, Star Wars Rebels.

Target: a run lasts ~40 days. Days go by fast and the player loses track of time in the good way — the difficulty curve needs to stay ahead of the player curve the whole way. New threats introduced at key milestones reset the power dynamic before the cruise phase sets in.

---

## Priority Order

### 1. Intro Dialogue System

A short back-and-forth between two portrait characters before gameplay begins. Static portraits with illustrated backgrounds. Short quips — players won't skip it if it's under 30 seconds.

**Characters:**
- **The Pilot** — Speed Racer / Voltron / Rebels energy. In a cockpit, stars moving behind him. Portrait sits top-right.
- **Moonbase Operator** — at a console, silhouettes visible in the background. Portrait sits bottom-left.

**Dialogue structure (draft):**
> Pilot: "Moonbase, come in!"
> Operator: "We're in trouble! Please stop the meteor storm!"
> *gameplay begins*
> *(later, on enemy day)*
> Operator: "Strange signal on approach..."
> *enemy arrives*

**Technical approach:**
- `IntroScene.tscn` — CanvasLayer over a static or scrolling background
- Dialogue driven by a data array (text, portrait, speaker side)
- Advances on button press / ui_accept
- Optional: voice lines as AudioStreamPlayer clips per line
- "Strange signal" trigger hooks into the enemy spawner signal that already exists

---

### 2. Win Condition

**Target: survive Day 40.** After Day 40 the Operator says "You did it! We're safe." Victory sequence plays.

**Victory scene:**
- Operator portrait: "You did it! We're safe!"
- Pilot portrait: *something punchy*
- Victory music (needs a track)
- Fireworks — particle effect or sprite animation over the screen
- Final score / day survived display
- Return to Start Screen

**What needs to exist:**
- `Main.gd` checks `GameManager.day_number >= 40` at day end and routes to `VictoryScene` instead of next day
- `VictoryScene.tscn` — reuses the dialogue portrait system from the intro
- Fireworks effect
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

### 4. Mega Asteroid Event

A scripted set-piece moment, not a random spawn. Appears once per run at a fixed day (e.g. Day 10).

**Behaviour:**
- Much larger sprite, high HP (e.g. 150+)
- Fires smaller asteroids downward in bursts as it takes damage (damage phases)
- Moves slowly and deliberately — a boss fight feel
- Operator dialogue trigger: "That's not a meteor — it's enormous!"
- On death: large resource drop, screen shake, big explosion

**Technical approach:**
- Separate `MegaAsteroid.tscn` / `MegaAsteroid.gd`
- `Main.gd` checks for the trigger day and spawns it as a special event
- Damage phase thresholds (75%, 50%, 25% HP) trigger burst spawns

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
- **Days 13–25:** Enemy variety becomes the dominant pressure. Interceptors appear, multiple ships possible. Asteroids are background noise. Mega Asteroid event around day 15–18.
- **Days 26–40:** Both at full intensity. Player needs a strong build to keep up. Win condition at day 40.

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

- **Run length:** Day 40 as win condition — revisit after new enemies and the mega asteroid are in place.
- **Skip intro:** After the first run, should the intro be skippable from the start screen?
- **Voice acting:** Real recordings or synthesized? Scoped as optional/later.
- **Scoring:** Is there a score or is survival the only metric?
- **Mobile:** Is HTML5/mobile a target? (Affects control scheme considerations)
