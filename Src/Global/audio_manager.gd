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
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const MIN_BUS_VOLUME_DB := -60.0
const DEFAULT_BUS_VOLUME := 1.0

@export var registry: Resource = DEFAULT_REGISTRY
@export var sfx_pool_size := 16
@export var ui_pool_size := 8
@export var max_one_shot_players := 48

var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _loop_players: Dictionary = {}
var _music_player: AudioStreamPlayer
var _current_music_name := &""

func _ready() -> void:
	randomize()
	_ensure_runtime_buses()
	load_audio_settings()
	_build_pool(_sfx_players, sfx_pool_size, SFX_BUS, "SFXPlayer")
	_build_pool(_ui_players, ui_pool_size, UI_BUS, "UIPlayer")
	_music_player = _create_player(MUSIC_BUS, "MusicPlayer")

func _exit_tree() -> void:
	stop_all_loops()
	stop_music()

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
	player.stream = null
	player.queue_free()

func stop_all_loops() -> void:
	for sound_name in _loop_players.keys():
		stop_loop(sound_name)

func play_music(sound_name: StringName, volume_offset_db := 0.0) -> AudioStreamPlayer:
	if _current_music_name == sound_name and _music_player and _music_player.playing:
		return _music_player

	var sound := _get_sound(sound_name)
	if not sound:
		return null

	_music_player.stop()
	_current_music_name = sound_name
	_music_player.stream = _get_sound_stream(sound)
	_music_player.bus = _resolve_bus(_get_sound_bus(sound), MUSIC_BUS)
	_music_player.volume_db = _get_sound_volume_db(sound) + volume_offset_db
	_music_player.pitch_scale = _get_sound_pitch_scale(sound)
	_music_player.play()
	return _music_player

func stop_music() -> void:
	if _music_player:
		_music_player.stop()
		_music_player.stream = null
	_current_music_name = &""

func get_volume_categories() -> Array[StringName]:
	return [&"master", &"music", &"sfx", &"ui", &"ambience"]

func set_category_volume(category: StringName, volume: float, save_settings := true) -> void:
	var bus := _category_to_bus(category)
	if bus == &"":
		push_warning("AudioManager could not find volume category '%s'." % String(category))
		return

	set_bus_volume_linear(bus, volume)
	if save_settings:
		save_audio_settings()

func get_category_volume(category: StringName) -> float:
	var bus := _category_to_bus(category)
	if bus == &"":
		push_warning("AudioManager could not find volume category '%s'." % String(category))
		return DEFAULT_BUS_VOLUME

	return get_bus_volume_linear(bus)

func set_master_volume(volume: float, save_settings := true) -> void:
	set_category_volume(&"master", volume, save_settings)

func get_master_volume() -> float:
	return get_category_volume(&"master")

func set_music_volume(volume: float, save_settings := true) -> void:
	set_category_volume(&"music", volume, save_settings)

func get_music_volume() -> float:
	return get_category_volume(&"music")

func set_sfx_volume(volume: float, save_settings := true) -> void:
	set_category_volume(&"sfx", volume, save_settings)

func get_sfx_volume() -> float:
	return get_category_volume(&"sfx")

func set_ui_volume(volume: float, save_settings := true) -> void:
	set_category_volume(&"ui", volume, save_settings)

func get_ui_volume() -> float:
	return get_category_volume(&"ui")

func set_ambience_volume(volume: float, save_settings := true) -> void:
	set_category_volume(&"ambience", volume, save_settings)

func get_ambience_volume() -> float:
	return get_category_volume(&"ambience")

func set_bus_volume_linear(bus: StringName, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(String(bus))
	if bus_index == -1:
		push_warning("AudioManager could not find audio bus '%s'." % String(bus))
		return

	var clamped_volume := clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, clamped_volume <= 0.0)
	if clamped_volume <= 0.0:
		AudioServer.set_bus_volume_db(bus_index, MIN_BUS_VOLUME_DB)
		return

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_volume))

func get_bus_volume_linear(bus: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(String(bus))
	if bus_index == -1:
		push_warning("AudioManager could not find audio bus '%s'." % String(bus))
		return DEFAULT_BUS_VOLUME

	if AudioServer.is_bus_mute(bus_index):
		return 0.0

	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)

func save_audio_settings() -> void:
	var config := ConfigFile.new()
	for category in get_volume_categories():
		config.set_value("audio", String(category), get_category_volume(category))

	var error := config.save(AUDIO_SETTINGS_PATH)
	if error != OK:
		push_warning("AudioManager could not save audio settings: %s." % error_string(error))

func load_audio_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(AUDIO_SETTINGS_PATH)
	if error != OK:
		_apply_default_audio_settings()
		return

	for category in get_volume_categories():
		var saved_volume := float(config.get_value("audio", String(category), DEFAULT_BUS_VOLUME))
		set_category_volume(category, saved_volume, false)

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
	var stream := _get_sound_stream(sound)
	var player := _get_available_one_shot_player(pool, fallback_bus)
	if not player:
		push_warning("AudioManager has no available one-shot player for %s." % stream.resource_path)
		return null

	player.stream = stream
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
	if sound.has_method("get_stream"):
		return sound.get_stream() as AudioStream
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

func _apply_default_audio_settings() -> void:
	for category in get_volume_categories():
		set_category_volume(category, DEFAULT_BUS_VOLUME, false)

func _category_to_bus(category: StringName) -> StringName:
	match category:
		&"master":
			return MASTER_BUS
		&"music":
			return MUSIC_BUS
		&"sfx":
			return SFX_BUS
		&"ui":
			return UI_BUS
		&"ambience":
			return AMBIENCE_BUS
		_:
			return &""

func _on_loop_finished(sound_name: StringName) -> void:
	if _loop_players.has(sound_name):
		_loop_players.erase(sound_name)
