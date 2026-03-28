extends Node

# Asteroid
var _asteroid_hit_base: Array[AudioStreamPlayer]
var _asteroid_hit_ground: Array[AudioStreamPlayer]

# Enemy
var _enemy_appears: AudioStreamPlayer
var _enemy_missile: AudioStreamPlayer
var _enemy_projectile: AudioStreamPlayer

# Player
var _player_projectile: Array[AudioStreamPlayer]

# Pickups
var _pickup_shield: AudioStreamPlayer
var _pickup_structure: AudioStreamPlayer
var _pickup_weapon: AudioStreamPlayer
var _resource_hit_base: AudioStreamPlayer

func _ready() -> void:
	_asteroid_hit_base = [
		_make("res://assets/sounds/asteroids/asteroid-hit-base.mp3"),
		_make("res://assets/sounds/asteroids/asteroid-hit-base2.mp3"),
	]
	_asteroid_hit_ground = [
		_make("res://assets/sounds/asteroids/asteroid-hit-ground1.wav"),
		_make("res://assets/sounds/asteroids/asteroid-hit-ground2.wav"),
		_make("res://assets/sounds/asteroids/asteroid-hit-ground3.wav"),
		_make("res://assets/sounds/asteroids/asteroid-hit-ground4.wav"),
	]
	_enemy_appears    = _make("res://assets/sounds/enemy/enemy-appears-ambient.mp3")
	_enemy_missile    = _make("res://assets/sounds/enemy/enemy-missile.mp3")
	_enemy_projectile = _make("res://assets/sounds/enemy/enemy-projectile.mp3")

	_player_projectile = [
		_make("res://assets/sounds/player/player-projectile1.mp3"),
		_make("res://assets/sounds/player/player-projectile2.mp3"),
		_make("res://assets/sounds/player/player-projectile3.mp3"),
	]
	_pickup_shield    = _make("res://assets/sounds/pickups/pickup-resource-shield.mp3")
	_pickup_structure = _make("res://assets/sounds/pickups/pickup-resource-structure.mp3")
	_pickup_weapon    = _make("res://assets/sounds/pickups/pickup-resource-weapon.mp3")
	_resource_hit_base = _make("res://assets/sounds/pickups/resource-hit-base.mp3")

# --- Public API ---

func asteroid_hit_base() -> void:
	(_asteroid_hit_base.pick_random() as AudioStreamPlayer).play()

func asteroid_hit_ground() -> void:
	(_asteroid_hit_ground.pick_random() as AudioStreamPlayer).play()

func enemy_appears() -> void:
	_enemy_appears.play()

func enemy_fire_missile() -> void:
	_enemy_missile.play()

func enemy_fire_projectile() -> void:
	_enemy_projectile.play()

func player_fire() -> void:
	(_player_projectile.pick_random() as AudioStreamPlayer).play()

func pickup_resource(resource_type: String) -> void:
	match resource_type:
		"shield":   _pickup_shield.play()
		"weapon":   _pickup_weapon.play()
		_:          _pickup_structure.play()  # general + physical

func resource_hit_base() -> void:
	_resource_hit_base.play()

# --- Helper ---

func _make(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player
