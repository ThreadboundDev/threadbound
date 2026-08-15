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
const AMBIENT_BUS := &"Ambient"
const BACKGROUND_AUDIO_BUS := AMBIENT_BUS
const LEGACY_BACKGROUND_AUDIO_BUS := &"Background Audio"
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const MIN_BUS_VOLUME_DB := -60.0
const MASTER_OUTPUT_TRIM_DB := -18.0
const DEFAULT_BUS_VOLUME := 1.0
const DEFAULT_MUSIC_FADE_DURATION := 0.6
const MUSIC_PLAYER_COUNT := 2

@export var registry: Resource = DEFAULT_REGISTRY
@export var sfx_pool_size := 16
@export var ui_pool_size := 8
@export var max_one_shot_players := 48

var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _loop_players: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music_name := &""
var _music_tween: Tween
var _music_fade_tweens: Array[Tween] = []
var _music_player_index := 0
var _boss_music_active := false
var _pause_music_active := false
var _game_over_music_active := false
var _paused_music_name := &""
var _paused_music_position := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_ensure_runtime_buses()
	load_audio_settings()
	_build_pool(_sfx_players, sfx_pool_size, SFX_BUS, "SFXPlayer")
	_build_pool(_ui_players, ui_pool_size, UI_BUS, "UIPlayer")
	for index in MUSIC_PLAYER_COUNT:
		var player := _create_player(MUSIC_BUS, "MusicPlayer%d" % (index + 1))
		player.finished.connect(_on_music_finished.bind(player))
		_music_players.append(player)
	_music_player = _music_players[0]

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

	var player := _create_player(_resolve_bus(_get_sound_bus(sound), BACKGROUND_AUDIO_BUS), "Loop_%s" % String(sound_name))
	# Imported audio streams must be played directly; duplicated imported WAVs can report playing while silent.
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

func play_title_screen_music() -> AudioStreamPlayer:
	_boss_music_active = false
	_pause_music_active = false
	_game_over_music_active = false
	_clear_paused_music_resume()
	stop_loop(&"music_cotfw_background")
	return play_music(&"music_title", 0.0, DEFAULT_MUSIC_FADE_DURATION)

func enter_gameplay_music() -> void:
	_game_over_music_active = false
	_pause_music_active = false
	_boss_music_active = false
	_clear_paused_music_resume()
	play_loop(&"music_cotfw_background")
	play_exploration_music()

func play_exploration_music(fade_duration := 0.0) -> AudioStreamPlayer:
	if _game_over_music_active or _pause_music_active or _boss_music_active:
		return _music_player
	return play_music(&"music_exploration", 0.0, maxf(fade_duration, DEFAULT_MUSIC_FADE_DURATION))

func play_boss_music(fade_duration := 0.0) -> AudioStreamPlayer:
	if _game_over_music_active or _pause_music_active:
		return _music_player
	_boss_music_active = true
	return play_music(&"music_boss_proto_weaver", 0.0, maxf(fade_duration, DEFAULT_MUSIC_FADE_DURATION))

func stop_boss_music() -> void:
	_boss_music_active = false
	if not _game_over_music_active and not _pause_music_active:
		play_exploration_music()

func play_pause_music(fade_duration := DEFAULT_MUSIC_FADE_DURATION) -> AudioStreamPlayer:
	if _game_over_music_active:
		return _music_player
	if not _pause_music_active and _music_player and _music_player.playing:
		_paused_music_name = _current_music_name
		_paused_music_position = _music_player.get_playback_position()
	_pause_music_active = true
	return play_music(&"music_pause", 0.0, fade_duration)

func stop_pause_music() -> void:
	_pause_music_active = false
	if _paused_music_name != &"":
		var resume_name := _paused_music_name
		var resume_position := _paused_music_position
		_clear_paused_music_resume()
		play_music(resume_name, 0.0, DEFAULT_MUSIC_FADE_DURATION, resume_position)
		return
	_resume_gameplay_music()

func play_game_over_music(fade_duration := DEFAULT_MUSIC_FADE_DURATION) -> AudioStreamPlayer:
	_game_over_music_active = true
	_pause_music_active = false
	_boss_music_active = false
	_clear_paused_music_resume()
	return play_music(&"music_game_over", 0.0, fade_duration)

func stop_game_over_music() -> void:
	_game_over_music_active = false
	if _current_music_name == &"music_game_over":
		stop_music()

func play_music(
	sound_name: StringName,
	volume_offset_db := 0.0,
	fade_duration := 0.0,
	start_position := 0.0
) -> AudioStreamPlayer:
	if _current_music_name == sound_name and _music_player and _music_player.playing:
		return _music_player

	var sound := _get_sound(sound_name)
	if not sound:
		return null

	_kill_music_fade_tweens()

	var target_volume := _get_sound_volume_db(sound) + volume_offset_db
	var previous_player := _music_player
	var next_player := _get_next_music_player()
	_current_music_name = sound_name
	next_player.stop()
	# Keep crossfades on separate players, but keep the imported stream instance intact for reliable playback.
	next_player.stream = _get_sound_stream(sound)
	next_player.bus = _resolve_bus(_get_sound_bus(sound), MUSIC_BUS)
	next_player.volume_db = MIN_BUS_VOLUME_DB if fade_duration > 0.0 else target_volume
	next_player.pitch_scale = _get_sound_pitch_scale(sound)
	next_player.play(maxf(0.0, start_position))
	_music_player = next_player

	if previous_player and previous_player != next_player and previous_player.playing:
		if fade_duration > 0.0:
			var fade_out := create_tween()
			fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_music_fade_tweens.append(fade_out)
			fade_out.tween_property(previous_player, "volume_db", MIN_BUS_VOLUME_DB, fade_duration)
			fade_out.tween_callback(_stop_music_player.bind(previous_player))
		else:
			_stop_music_player(previous_player)

	if fade_duration > 0.0:
		_music_tween = create_tween()
		_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_music_fade_tweens.append(_music_tween)
		_music_tween.tween_property(next_player, "volume_db", target_volume, fade_duration)
	return _music_player

func stop_music() -> void:
	_kill_music_fade_tweens()
	for player in _music_players:
		_stop_music_player(player)
	_current_music_name = &""
	_clear_paused_music_resume()

func _clear_paused_music_resume() -> void:
	_paused_music_name = &""
	_paused_music_position = 0.0

func get_volume_categories() -> Array[StringName]:
	return [&"master", &"music", &"ambient", &"sfx", &"ui"]

func get_volume_category_label(category: StringName) -> String:
	match category:
		&"master":
			return "Master"
		&"music":
			return "Music"
		&"sfx":
			return "SFX"
		&"ui":
			return "UI"
		&"ambient", &"background_audio", &"ambience":
			return "Ambient"
		_:
			return String(category).capitalize()

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
	set_background_audio_volume(volume, save_settings)

func get_ambience_volume() -> float:
	return get_background_audio_volume()

func set_background_audio_volume(volume: float, save_settings := true) -> void:
	set_category_volume(&"background_audio", volume, save_settings)

func get_background_audio_volume() -> float:
	return get_category_volume(&"background_audio")

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

	var volume_db := linear_to_db(clamped_volume)
	if bus == MASTER_BUS:
		volume_db += MASTER_OUTPUT_TRIM_DB
	AudioServer.set_bus_volume_db(bus_index, volume_db)

func get_bus_volume_linear(bus: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(String(bus))
	if bus_index == -1:
		push_warning("AudioManager could not find audio bus '%s'." % String(bus))
		return DEFAULT_BUS_VOLUME

	if AudioServer.is_bus_mute(bus_index):
		return 0.0

	var volume_db := AudioServer.get_bus_volume_db(bus_index)
	if bus == MASTER_BUS:
		volume_db -= MASTER_OUTPUT_TRIM_DB
	return clampf(db_to_linear(volume_db), 0.0, 1.0)

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
		var key := String(category)
		if category == &"ambient" and not config.has_section_key("audio", key):
			key = "background_audio"
		var saved_volume := float(config.get_value("audio", key, DEFAULT_BUS_VOLUME))
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
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player

func _get_next_music_player() -> AudioStreamPlayer:
	if _music_players.is_empty():
		_music_player = _create_player(MUSIC_BUS, "MusicPlayer")
		_music_player.finished.connect(_on_music_finished.bind(_music_player))
		_music_players.append(_music_player)
		return _music_player

	_music_player_index = (_music_player_index + 1) % _music_players.size()
	return _music_players[_music_player_index]

func _stop_music_player(player: AudioStreamPlayer) -> void:
	if not player:
		return
	player.stop()
	player.stream = null

func _kill_music_fade_tweens() -> void:
	for tween in _music_fade_tweens:
		if tween:
			tween.kill()
	_music_fade_tweens.clear()
	_music_tween = null

func _resume_gameplay_music() -> void:
	if _game_over_music_active or _pause_music_active:
		return
	if _boss_music_active:
		play_music(&"music_boss_proto_weaver")
	else:
		play_exploration_music()

func _resolve_bus(bus: StringName, fallback_bus: StringName) -> StringName:
	if AudioServer.get_bus_index(String(bus)) != -1:
		return bus
	if AudioServer.get_bus_index(String(fallback_bus)) != -1:
		return fallback_bus
	return MASTER_BUS

func _ensure_runtime_buses() -> void:
	var legacy_bus_index := AudioServer.get_bus_index(String(LEGACY_BACKGROUND_AUDIO_BUS))
	if legacy_bus_index != -1 and AudioServer.get_bus_index(String(AMBIENT_BUS)) == -1:
		AudioServer.set_bus_name(legacy_bus_index, String(AMBIENT_BUS))

	var required_buses := [MUSIC_BUS, SFX_BUS, UI_BUS, BACKGROUND_AUDIO_BUS]
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
		&"ambient", &"background_audio", &"ambience":
			return BACKGROUND_AUDIO_BUS
		_:
			return &""

func _on_loop_finished(sound_name: StringName) -> void:
	if _loop_players.has(sound_name):
		var player := _loop_players[sound_name] as AudioStreamPlayer
		if player and player.stream:
			player.play()
		else:
			_loop_players.erase(sound_name)

func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == _music_player and _current_music_name != &"" and player.stream:
		player.play()
