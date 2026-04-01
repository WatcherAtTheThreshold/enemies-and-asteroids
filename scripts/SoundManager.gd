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
var _ship_explosion: AudioStreamPlayer
var _base_explosion: AudioStreamPlayer

# Pickups
var _pickup_shield: AudioStreamPlayer
var _pickup_structure: AudioStreamPlayer
var _pickup_weapon: AudioStreamPlayer
var _resource_hit_base: AudioStreamPlayer

# Music
var _music_tracks: Array[AudioStreamPlayer]
var _last_music_index: int = -1

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
	_ship_explosion = _make("res://assets/sounds/player/ship-explosion.wav")
	_base_explosion = _make("res://assets/sounds/base/base-explosion.wav")
	_pickup_shield    = _make("res://assets/sounds/pickups/pickup-resource-shield.mp3")
	_pickup_structure = _make("res://assets/sounds/pickups/pickup-resource-structure.mp3")
	_pickup_weapon    = _make("res://assets/sounds/pickups/pickup-resource-weapon.mp3")
	_resource_hit_base = _make("res://assets/sounds/pickups/resource-hit-base.mp3")

	_music_tracks = [
		_make_music("res://assets/music/spaceMusic1.ogg"),
		_make_music("res://assets/music/spaceMusic2.ogg"),
		_make_music("res://assets/music/spaceMusic3.ogg"),
		_make_music("res://assets/music/spaceMusic4.ogg"),
		_make_music("res://assets/music/spaceMusic5.ogg"),
		_make_music("res://assets/music/spaceMusic6.ogg"),
		_make_music("res://assets/music/spaceMusic7.ogg"),
		_make_music("res://assets/music/spaceMusic8.ogg"),
	]
	for track in _music_tracks:
		track.finished.connect(_on_music_finished)
	_play_next_track()

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
		"shield", "ship-health":   _pickup_shield.play()
		"weapon":                  _pickup_weapon.play()
		_:                         _pickup_structure.play()  # general + physical + base-health

func resource_hit_base() -> void:
	_resource_hit_base.play()

func ship_explode() -> void:
	_ship_explosion.play()

func base_explode() -> void:
	_base_explosion.play()

# --- Music ---

func _play_next_track() -> void:
	var available: Array = range(_music_tracks.size())
	available.erase(_last_music_index)
	_last_music_index = available.pick_random()
	_music_tracks[_last_music_index].play()

func _on_music_finished() -> void:
	_play_next_track()

# --- Helpers ---

func _make(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player

func _make_music(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = -6.0
	add_child(player)
	return player
