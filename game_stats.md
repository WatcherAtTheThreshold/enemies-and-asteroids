# Moonbase Defender — Game Stats Reference

---

## Player Ship

| Stat | Value | File |
|------|-------|------|
| Max HP | 15 | Player.tscn |
| Move speed | 200 px/s | Player.tscn |
| Fire rate | 1 shot per 0.15s | Player.tscn |
| Projectile speed | 500 px/s | PlayerProjectile.gd |
| Projectile damage | 1 per hit | PlayerProjectile.gd |

**Notes:**
- Ship rotates to face shoot direction, holds last facing when input released
- Thruster sprite animates when moving

---

## Moonbase

| Stat | Value | File |
|------|-------|------|
| Max HP | 50 | Base.tscn |
| Move speed | Set in inspector (user increased) | Base.tscn |

**Notes:**
- Crawls right across screen; when it exits the right edge the day ends
- Teleports back to left edge to begin the next day

---

## Asteroids

| Size | HP (Day 1–3) | HP Multiplier | Impact Damage | Move Speed | Drop Count |
|------|-------------|---------------|---------------|------------|------------|
| Small | 3 | see below | 5 | ~90 px/s (inspector) | 2 |
| Medium | 7 | see below | 12 | ~70 px/s (inspector) | 4 |
| Large | 15 | see below | 25 | ~50 px/s (inspector) | 7 |

**HP scaling by day:**
| Day | Multiplier |
|-----|-----------|
| 1–3 | 1.0× |
| 4–6 | 1.3× |
| 7–9 | 1.6× |
| 10–13 | 2.0× |
| 14+ | 2.5× |

**Spawn interval by day:**
- Formula: `max(min_interval, base_interval - (day × 0.1))`
- Base interval: 1.5s (inspector) — Min interval: 0.4s (inspector)
- Day 1 ≈ 1.4s, Day 11+ = 0.4s (floor)

**Size distribution by day (pool-weighted):**
| Day | Small | Medium | Large |
|-----|-------|--------|-------|
| 1–2 | 100% | 0% | 0% |
| 3–4 | 80% | 20% | 0% |
| 5–6 | 60% | 40% | 0% |
| 7–8 | 40% | 40% | 20% |
| 9–11 | 20% | 40% | 40% |
| 12+ | ~17% | ~17% | ~67% |

**Asteroid splitting (on player kill only):**
| Destroyed | Splits into |
|-----------|-------------|
| Small | Nothing (destroyed) |
| Medium | 2 smalls, spread ±28° |
| Large | 50% → 2 mediums spread ±35°, 50% → 3 smalls spread ±40° |

- 40% chance to split, 60% chance to just be destroyed (drops resources normally)
- Split children inherit the day's HP multiplier
- Split children also split if they are medium
- No splitting on base collision, player collision, or ground impact

**Resource drops (per asteroid, randomised from pool):**
- Pool: General ×3, Physical ×2, Shield ×1
- No weapon drops from asteroids

**Damage targets:** Player, Base, Ground (ground = break apart, no damage)

---

## Enemy Ship

| Stat | Value | File |
|------|-------|------|
| Max HP | 40 | EnemyShip.tscn |
| Move speed | 80 px/s | EnemyShip.gd |
| Projectile fire rate | 1 shot per 1.5s | EnemyShip.gd |
| Missile fire rate | 1 missile per 5.0s | EnemyShip.gd |
| Resource drop count | 6 | EnemyShip.gd |
| Spawn cycle | Every 3rd day | EnemySpawner.tscn |
| Mid-day spawn | Day 10+ | EnemySpawner.gd |

**Resource drops (per enemy, randomised from pool):**
- Pool: Weapon ×2, Shield ×1, General ×1, Physical ×1
- Only source of weapon resources in the game

**Weapons:**
| Weapon | Speed | Damage | Target |
|--------|-------|--------|--------|
| Projectile | 300 px/s | 1 | Player only |
| Missile | 150 px/s | 10 | Base only — interceptable by player projectile |

**Behaviour:** ENTER state (flies in from top) → COMBAT state (strafes with sine oscillation, fires both weapons) → RETREAT (reserved, not yet used)

---

## Turrets

| Stat | Value | File |
|------|-------|------|
| Detection range | 500 px | Turret.gd |
| Fire rate (default) | 1 shot per 2.0s | Turret.gd |
| Fire rate (min) | 1 shot per 0.3s | UpgradeScreen.gd |
| Projectile speed | 450 px/s | TurretProjectile.gd |
| Projectile damage | 1 per hit | TurretProjectile.gd |
| Starting turret | Center: (0, −18) relative to base | Base.tscn |
| Deployable slots | Left: (−45, −20) / Right: (+45, −20) relative to base, z_index −1 | UpgradeScreen.gd |
| Max deployable turrets | 2 (plus the starting center turret = 3 total) | UpgradeScreen.gd |

**Targeting:** Nearest asteroid or enemy within detection range. Auto-rotates to face target.

---

## Upgrades

Shown every day end — 3 drawn randomly from the pool of 10. Game pauses while screen is open.

| Upgrade | Effect | Cost | Resource Source |
|---------|--------|------|-----------------|
| Reinforce Hull | Restore player to full HP | 2 Shield | Asteroid drops |
| Repair Base | Restore +20 base HP | 3 Physical | Asteroid drops |
| Expand Cockpit | Player max HP +3, heal +3 | 3 Shield | Asteroid drops |
| Reinforce Base | Base max HP +10, heal +10 | 3 Physical | Asteroid drops |
| Rapid Fire | Player `fire_rate × 0.95` (5% faster, stacks) | 1 Weapon | Enemy drops only |
| Overcharge | Player projectile damage +1 | 2 Weapon | Enemy drops only |
| Turret Upgrade | All turrets: projectile damage +1 | 2 Weapon | Enemy drops only |
| Afterburners | Player `move_speed + 40` | 2 General | Asteroid/enemy drops |
| Breathing Room | `base_spawn_interval + 0.5s` | 2 General | Asteroid/enemy drops |
| Deploy Turret | Place left then right deployable turret. Once both placed, subsequent purchases: all turrets `fire_rate × 0.75` (min 0.3s) | 3 Weapon | Enemy drops only |

**Upgrade economy notes:**
- Weapon resources only come from enemy drops (1 per drop pool of 5) — all weapon upgrades are gated behind surviving enemy days
- Enemy drops 5 resources per kill; expected ~2 weapon resources per enemy
- Reinforce Hull heals to full (passes 999, clamped to max_hp by HealthComponent)
- Breathing Room stacks — each purchase adds 0.5s to the base spawn interval
- Deploy Turret remains selectable indefinitely for the fire rate upgrade path after both turrets are placed

---

## Potential Future Upgrades & Tunable Stats

### Player
| Stat | Current | Upgrade idea |
|------|---------|-------------|
| Max HP | 15 | Already upgradeable (Expand Cockpit) |
| Fire rate | 0.15s interval | Already upgradeable (Rapid Fire) |
| Move speed | 200 px/s | Already upgradeable (Afterburners) |
| Projectile damage | 1 | Already upgradeable (Overcharge) |
| Projectile speed | 500 px/s | "Hot Rounds" — faster projectiles |
| Multi-shot | 1 projectile | "Spread Shot" — fire 3 in a cone |

### Base
| Stat | Current | Upgrade idea |
|------|---------|-------------|
| Max HP | 50 | Already upgradeable (Reinforce Base) |
| Move speed | User set | Could slow it down to extend days |
| HP regen | None | "Nano-Repair" — passive +1 HP per day survived |

### Turrets
| Stat | Current | Upgrade idea |
|------|---------|-------------|
| Fire rate | 2.0s (upgrades to 0.3s min) | Already upgradeable (Deploy Turret 3rd+ purchase) |
| Detection range | 500 px | "Extended Array" — range +200 px |
| Projectile damage | 1 | Already upgradeable (Turret Upgrade) |
| Projectile speed | 450 px/s | "Velocity Rounds" — faster shots |

### Spawner / Difficulty
| Stat | Current | Upgrade idea |
|------|---------|-------------|
| Base spawn interval | 1.5s | Already upgradeable (Breathing Room) |
| Min spawn interval | 0.4s (floor) | "Safe Zone" — raise the floor |
| HP multiplier | Per day table | No current upgrade — could add "Weak Seam" (asteroids take +1 damage) |

### Enemy
| Stat | Current | Upgrade idea |
|------|---------|-------------|
| Missile fire rate | 5.0s | "Point Defense" — slower missile rate |
| Enemy HP | 40 | No current upgrade |
| Spawn cycle | Every 3rd day | Could become configurable mid-run |
