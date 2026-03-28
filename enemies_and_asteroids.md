# Moonbase Defender — Enemies & Asteroids
## Godot Implementation Plan

---

## Project Context

Top-down 2D arcade game (fixed camera). A small ship defends a moonbase on a curved lunar surface. The base travels slowly left to right across the screen — when it exits, the day ends. The player shoots, collects resources, and survives.

**Tech:** Godot 4, GDScript. Exports to HTML5.  
**Art:** Placeholder sprites for now, final pixel art to be supplied.  
**Controls:** WASD + Left Stick (move/steer), Arrow Keys + Right Stick (shoot direction).

---

## Asteroids

### Design Summary
- Spawn from the top and top-left/top-right diagonals, simulating infall toward a spherical body
- Float downward toward the moon surface
- Vary in size (small, medium, large) — size determines HP and resource drop
- Scale in size and spawn frequency as days progress
- On impact with the base: deal damage
- On impact with the ground (not base): break apart, resources scatter
- Destroyed asteroids drop floating resource pickups

---

### Scene Structure

```
Asteroid (CharacterBody2D or RigidBody2D)
├── Sprite2D              # placeholder, swap for pixel art
├── CollisionShape2D      # convex hull or circle, sized per variant
├── HealthComponent       # Node, tracks HP, emits signal on death
└── HitboxArea2D          # Area2D for weapon collision detection
```

Use a **pool of three PackedScenes**: `AsteroidSmall.tscn`, `AsteroidMedium.tscn`, `AsteroidLarge.tscn`. Scale values and HP are set via exported variables so they can be tuned without changing scenes.

---

### Asteroid Variables

```gdscript
@export var max_hp: int = 3
@export var move_speed: float = 60.0
@export var rotation_speed: float = 0.5       # slow tumble
@export var resource_drop_count: int = 2
@export var resource_drop_scene: PackedScene
@export var size_category: String = "small"   # "small" | "medium" | "large"
```

---

### Movement

Asteroids do not use physics gravity. They move on a fixed velocity vector set at spawn, with a slight random drift on the x-axis to feel organic.

```gdscript
var velocity: Vector2

func _ready():
    var angle = randf_range(deg_to_rad(200), deg_to_rad(340))  # downward spread
    velocity = Vector2(cos(angle), sin(angle)) * move_speed

func _physics_process(delta):
    position += velocity * delta
    rotation += rotation_speed * delta
```

Adjust the angle range to bias spawning toward the center of the screen (toward the base).

---

### Spawner

A dedicated `AsteroidSpawner` node (not part of the asteroid scene) handles timed spawning and difficulty scaling.

```
AsteroidSpawner (Node2D)
└── SpawnTimer (Timer)
```

```gdscript
@export var base_spawn_interval: float = 2.5
@export var min_spawn_interval: float = 0.6
@export var day_number: int = 1

var spawn_zones = [
    # top-left diagonal, top, top-right diagonal
    Vector2(-200, -50),   # offset from screen top-left
    Vector2(0, -80),      # top center
    Vector2(200, -50)     # offset from screen top-right
]

func start_day(day: int):
    day_number = day
    SpawnTimer.wait_time = max(min_spawn_interval, base_spawn_interval - (day * 0.1))
    SpawnTimer.start()

func _on_SpawnTimer_timeout():
    spawn_asteroid()
    SpawnTimer.wait_time = max(min_spawn_interval, base_spawn_interval - (day_number * 0.1))

func spawn_asteroid():
    var scene = pick_scene_for_day()
    var asteroid = scene.instantiate()
    var zone = spawn_zones[randi() % spawn_zones.size()]
    asteroid.position = get_viewport_rect().size / 2 + zone + Vector2(randf_range(-150, 150), 0)
    get_parent().add_child(asteroid)

func pick_scene_for_day() -> PackedScene:
    if day_number < 4:
        return small_asteroid_scene
    elif day_number < 8:
        return [small_asteroid_scene, medium_asteroid_scene].pick_random()
    else:
        return [small_asteroid_scene, medium_asteroid_scene, large_asteroid_scene].pick_random()
```

---

### Collision & Death

The asteroid listens for hits via its `HitboxArea2D`. On reaching zero HP it emits a signal, spawns resource drops, and queues free.

```gdscript
signal asteroid_destroyed(position: Vector2, size_category: String)

func take_damage(amount: int):
    max_hp -= amount
    if max_hp <= 0:
        die()

func die():
    emit_signal("asteroid_destroyed", position, size_category)
    spawn_resources()
    queue_free()

func spawn_resources():
    for i in resource_drop_count:
        var res = resource_drop_scene.instantiate()
        res.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
        get_parent().add_child(res)
```

Connect `asteroid_destroyed` to the GameManager for scoring and day tracking.

---

### Difficulty Scaling Per Day

| Day | Spawn Interval | Size Distribution | HP Multiplier |
|-----|---------------|-------------------|---------------|
| 1–3 | 2.5s | Small only | 1x |
| 4–6 | 1.8s | Small + Medium | 1.2x |
| 7–9 | 1.2s | All sizes | 1.5x |
| 10+ | 0.6s (min) | Weighted Large | 2x |

Apply HP multiplier at spawn via: `asteroid.max_hp = int(asteroid.max_hp * hp_multiplier)`

---

## Enemies

### Design Summary
- Arrive **after** the base exits the screen (end of day, before return animation)
- Larger and more visually advanced than the player ship
- Attack the player directly and fire **interceptable missiles** at the base
- Have a visible HP bar
- Drop resources on defeat (larger drops than asteroids)
- Later game: enemy ships begin appearing **during** the day alongside asteroids (day 10+)
- Attacks arrive on a cycle — every 5th day, or configurable

---

### Scene Structure

```
EnemyShip (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── HealthComponent
├── HitboxArea2D
├── WeaponMount (Marker2D)       # projectile spawn point
├── MissileLauncher (Marker2D)   # missile spawn point
├── HPBar (ProgressBar or custom)
└── AIController (Node)          # state machine lives here
```

---

### Enemy Variables

```gdscript
@export var max_hp: int = 40
@export var move_speed: float = 80.0
@export var fire_rate: float = 1.5          # seconds between shots
@export var missile_fire_rate: float = 5.0  # seconds between missile volleys
@export var resource_drop_count: int = 6
@export var resource_drop_scene: PackedScene
@export var missile_scene: PackedScene
@export var projectile_scene: PackedScene
```

---

### AI — State Machine

The enemy uses a simple state machine with three states.

```gdscript
enum State { ENTER, COMBAT, RETREAT }
var state = State.ENTER

var player: Node2D
var base: Node2D
var fire_timer: float = 0.0
var missile_timer: float = 0.0

func _physics_process(delta):
    match state:
        State.ENTER:    _state_enter(delta)
        State.COMBAT:   _state_combat(delta)
        State.RETREAT:  _state_retreat(delta)   # future use

func _state_enter(delta):
    # Fly onto screen from top, transition to COMBAT when in position
    position.y += move_speed * delta
    if position.y > 150:
        state = State.COMBAT

func _state_combat(delta):
    _strafe(delta)
    _shoot_at_player(delta)
    _shoot_missile_at_base(delta)

func _strafe(delta):
    # Simple horizontal oscillation to feel aggressive
    position.x += sin(Time.get_ticks_msec() * 0.001 * move_speed) * delta * 60
```

---

### Enemy Weapons

**Direct fire at player:**
```gdscript
func _shoot_at_player(delta):
    fire_timer -= delta
    if fire_timer <= 0:
        fire_timer = fire_rate
        var proj = projectile_scene.instantiate()
        proj.position = $WeaponMount.global_position
        proj.direction = (player.global_position - $WeaponMount.global_position).normalized()
        get_parent().add_child(proj)
```

**Missile at base (interceptable):**
```gdscript
func _shoot_missile_at_base(delta):
    missile_timer -= delta
    if missile_timer <= 0:
        missile_timer = missile_fire_rate
        var missile = missile_scene.instantiate()
        missile.position = $MissileLauncher.global_position
        missile.target_position = base.global_position
        missile.is_enemy_missile = true      # flag so player weapons can destroy it
        get_parent().add_child(missile)
```

Enemy missiles travel on a fixed arc toward the base. The player can shoot them down. Mark them clearly (e.g. red trail) so interception feels intentional.

---

### Enemy Death

```gdscript
signal enemy_destroyed(position: Vector2)

func take_damage(amount: int):
    max_hp -= amount
    $HPBar.value = max_hp
    if max_hp <= 0:
        die()

func die():
    emit_signal("enemy_destroyed", position)
    spawn_resources()
    queue_free()

func spawn_resources():
    for i in resource_drop_count:
        var res = resource_drop_scene.instantiate()
        res.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
        get_parent().add_child(res)
```

Connect `enemy_destroyed` to GameManager to trigger post-enemy upgrade offering.

---

### Enemy Spawner

```
EnemySpawner (Node2D)
```

```gdscript
@export var enemy_scene: PackedScene
@export var enemy_day_cycle: int = 5       # every 5th day

var day_number: int = 1

func check_for_enemy_day(day: int):
    day_number = day
    if day % enemy_day_cycle == 0:
        spawn_enemy()

func spawn_enemy():
    var enemy = enemy_scene.instantiate()
    enemy.position = Vector2(get_viewport_rect().size.x / 2, -100)  # enters from top
    get_parent().add_child(enemy)
```

For later-game overlap (enemies during the day), call `spawn_enemy()` mid-day from the GameManager based on day number threshold.

---

## Shared: Resource Drop Scene

Both asteroids and enemies drop the same resource scenes. Resource type is assigned at spawn.

```
Resource (Area2D)
├── Sprite2D         # color indicates type: grey, blue, red, white
├── CollisionShape2D
└── DriftComponent   # slight downward float toward surface
```

```gdscript
@export var resource_type: String = "general"   # "general" | "shield" | "weapon" | "physical"
var drift_speed: float = 30.0

func _physics_process(delta):
    position.y += drift_speed * delta

func _on_body_entered(body):
    if body.is_in_group("base"):
        body.take_damage(1)     # resources damage base on impact
        queue_free()
    elif body.is_in_group("ground"):
        queue_free()            # rover collects at end of round (handled by GameManager)
    elif body.is_in_group("player"):
        GameManager.add_resource(resource_type)
        queue_free()
```

---

## GameManager Signals to Implement

These signals coordinate the systems above with the rest of the game:

```gdscript
signal day_started(day_number: int)
signal day_ended(day_number: int)
signal enemy_day_started(day_number: int)
signal enemy_defeated()
signal asteroid_destroyed(position: Vector2, size: String)
signal resource_collected(type: String)
```

---

## Notes for Implementation Order

1. Get a single asteroid spawning, moving, and dying with resource drops
2. Add the spawner with timer and difficulty scaling
3. Get a single enemy on screen with strafe movement
4. Add enemy direct fire at player
5. Add enemy missile targeting base, verify interception works
6. Wire death signals to GameManager
7. Test enemy-day cycle trigger
8. Test late-game asteroid + enemy overlap
