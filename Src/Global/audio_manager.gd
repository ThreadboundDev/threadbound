extends Node

## Central audio entry point.
## Example calls:
## AudioManager.play_sfx(&"grapple")
## AudioManager.play_ui(&"menu_confirm")
## AudioManager.play_loop(&"grapple_hanging")
## AudioManager.stop_loop(&"grapple_hanging")

const DEFAULT_REGISTRY: Resource = preload("res://Src/Global/audio_registry.tres")
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const UI_BUS := &"UI"
const AMBIENCE_BUS := &"Ambience"

@export var registry: Resource = DEFAULT_REGISTRY
@export var sfx_pool_size := 16
@export var ui_pool_size := 8
@export var max_one_shot_players := 48

var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _loop_players: Dictionary = {}
var _music_player: AudioStreamPlayer

func _ready() -> void:
	randomize()
	_ensure_runtime_buses()
	_build_pool(_sfx_players, sfx_pool_size, SFX_BUS, "SFXPlayer")
	_build_pool(_ui_players, ui_pool_size, UI_BUS, "UIPlayer")
	_music_player = _create_player(MUSIC_BUS, "MusicPlayer")

func play_sfx(sound_name: StringName, volume_offset_db := 0.0, pitch_variation_override := -1.0) -> AudioStreamPlayer:
	var sound := _get_sound(sound_name)
	if not sound:
		return null

	return _play_one_shot(sound, _sfx_players, SFX_BUS, volume_offset_db, pitch_variation_override)

func play_ui(sound_name: StringName, volume_offset_db := 0.0, pitch_variation_override := -1.0) -> AudioStreamPlayer:
	var sound := _get_sound(sound_name)
	if not sound:
		return null

	return _play_one_shot(sound, _ui_players, UI_BUS, volume_offset_db, pitch_variation_override)

func play_loop(sound_name: StringName, volume_offset_db := 0.0, pitch_variation_override := -1.0) -> AudioStreamPlayer:
	if _loop_players.has(sound_name):
		var existing_player := _loop_players[sound_name] as AudioStreamPlayer
		if existing_player and existing_player.playing:
			return existing_player

	var sound := _get_sound(sound_name)
	if not sound:
		return null

	var player := _create_player(_resolve_bus(_get_sound_bus(sound), AMBIENCE_BUS), "Loop_%s" % String(sound_name))
	player.stream = _get_sound_stream(sound)
	player.volume_db = _get_sound_volume_db(sound) + volume_offset_db
	player.pitch_scale = _get_sound_pitch_scale(sound, pitch_variation_override)
	player.finished.connect(_on_loop_finished.bind(sound_name), CONNECT_ONE_SHOT)
	_loop_players[sound_name] = player
	player.play()
	return player

func stop_loop(sound_name: StringName) -> void:
	if not _loop_players.has(sound_name):
		return

	var player := _loop_players[sound_name] as AudioStreamPlayer
	_loop_players.erase(sound_name)
	if not player:
		return

	player.stop()
	player.queue_free()

func stop_all_loops() -> void:
	for sound_name in _loop_players.keys():
		stop_loop(sound_name)

func play_music(sound_name: StringName, volume_offset_db := 0.0) -> AudioStreamPlayer:
	var sound := _get_sound(sound_name)
	if not sound:
		return null

	_music_player.stop()
	_music_player.stream = _get_sound_stream(sound)
	_music_player.bus = _resolve_bus(_get_sound_bus(sound), MUSIC_BUS)
	_music_player.volume_db = _get_sound_volume_db(sound) + volume_offset_db
	_music_player.pitch_scale = _get_sound_pitch_scale(sound)
	_music_player.play()
	return _music_player

func stop_music() -> void:
	if _music_player:
		_music_player.stop()

func has_sound(sound_name: StringName) -> bool:
	return registry != null and registry.has_sound(sound_name)

func register_sound(sound_name: StringName, sound: Resource) -> void:
	if not registry or not sound:
		return

	registry.sounds[sound_name] = sound

func _play_one_shot(
	sound: Resource,
	pool: Array[AudioStreamPlayer],
	fallback_bus: StringName,
	volume_offset_db: float,
	pitch_variation_override: float
) -> AudioStreamPlayer:
	var player := _get_available_one_shot_player(pool, fallback_bus)
	if not player:
		var stream := _get_sound_stream(sound)
		push_warning("AudioManager has no available one-shot player for %s." % stream.resource_path)
		return null

	player.stream = _get_sound_stream(sound)
	player.bus = _resolve_bus(_get_sound_bus(sound), fallback_bus)
	player.volume_db = _get_sound_volume_db(sound) + volume_offset_db
	player.pitch_scale = _get_sound_pitch_scale(sound, pitch_variation_override)
	player.play()
	return player

func _get_available_one_shot_player(pool: Array[AudioStreamPlayer], fallback_bus: StringName) -> AudioStreamPlayer:
	for player in pool:
		if not player.playing:
			return player

	var current_total := _sfx_players.size() + _ui_players.size()
	if current_total >= max_one_shot_players:
		return null

	var player := _create_player(fallback_bus, "OneShotPlayer")
	pool.append(player)
	return player

func _get_sound(sound_name: StringName) -> Resource:
	if not registry:
		push_warning("AudioManager has no AudioRegistry assigned.")
		return null

	var sound: Resource = registry.get_sound(sound_name) as Resource
	if not sound:
		push_warning("AudioManager could not find sound '%s'." % String(sound_name))
		return null

	if not _get_sound_stream(sound):
		push_warning("AudioManager sound '%s' has no AudioStream." % String(sound_name))
		return null

	return sound

func _get_sound_stream(sound: Resource) -> AudioStream:
	return sound.get("stream") as AudioStream

func _get_sound_bus(sound: Resource) -> StringName:
	var bus: Variant = sound.get("bus")
	if bus is StringName:
		return bus
	return StringName(String(bus))

func _get_sound_volume_db(sound: Resource) -> float:
	return float(sound.get("volume_db"))

func _get_sound_pitch_scale(sound: Resource, pitch_variation_override: float = -1.0) -> float:
	if sound.has_method("get_pitch_scale"):
		return float(sound.get_pitch_scale(pitch_variation_override))
	return float(sound.get("pitch_scale"))

func _build_pool(pool: Array[AudioStreamPlayer], pool_size: int, bus: StringName, player_name: String) -> void:
	for index in pool_size:
		pool.append(_create_player(bus, "%s%d" % [player_name, index + 1]))

func _create_player(bus: StringName, player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = _resolve_bus(bus, MASTER_BUS)
	add_child(player)
	return player

func _resolve_bus(bus: StringName, fallback_bus: StringName) -> StringName:
	if AudioServer.get_bus_index(String(bus)) != -1:
		return bus
	if AudioServer.get_bus_index(String(fallback_bus)) != -1:
		return fallback_bus
	return MASTER_BUS

func _ensure_runtime_buses() -> void:
	var required_buses := [MUSIC_BUS, SFX_BUS, UI_BUS, AMBIENCE_BUS]
	for bus in required_buses:
		if AudioServer.get_bus_index(String(bus)) == -1:
			var bus_index := AudioServer.bus_count
			AudioServer.add_bus(bus_index)
			AudioServer.set_bus_name(bus_index, String(bus))
			AudioServer.set_bus_send(bus_index, String(MASTER_BUS))

func _on_loop_finished(sound_name: StringName) -> void:
	if _loop_players.has(sound_name):
		_loop_players.erase(sound_name)
