extends Node
## Restrained existing-game Foley + retained CC0 NOX ambience; bounded voice pool.
var streams := {}
var voices: Array[AudioStreamPlayer3D] = []
var voice_index := 0
var muted := false
var wind: AudioStreamPlayer
var river: AudioStreamPlayer3D
var music: AudioStreamPlayer
var limiter: AudioEffectHardLimiter

func _ready() -> void:
	limiter = AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiter)
	for key in ["armor", "contact", "sword", "jump", "dash", "grapple_throw", "grapple_connect", "hurt", "enemy_swing", "stomp", "step_grass_1", "step_grass_2", "step_wood_1", "step_wood_2", "land"]:
		streams[key] = load("res://assets/audio/" + key + ".wav")
	for i in range(14):
		var player := AudioStreamPlayer3D.new()
		player.max_distance = 32
		player.unit_size = 5
		add_child(player)
		voices.append(player)
	wind = AudioStreamPlayer.new()
	wind.stream = load("res://assets/audio/wind.wav")
	wind.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wind.stream.loop_end = roundi(wind.stream.get_length()*wind.stream.mix_rate)
	wind.volume_db = -27
	add_child(wind)
	wind.finished.connect(wind.play)
	wind.play()
	river = AudioStreamPlayer3D.new()
	river.stream = load("res://assets/audio/river.wav")
	river.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	river.stream.loop_end = roundi(river.stream.get_length()*river.stream.mix_rate)
	river.volume_db = -24
	river.unit_size = 12
	river.max_distance = 38
	add_child(river)
	river.position = Vector3(12.5, 0, 0)
	river.finished.connect(river.play)
	river.play()
	music = AudioStreamPlayer.new()
	music.stream = load("res://assets/audio/forest_ambient.ogg")
	music.stream.loop = true
	music.volume_db = -25
	add_child(music)
	music.finished.connect(music.play)
	music.play()

func play(key: String, at: Vector3, volume := -12.0, pitch := 1.0) -> void:
	if not streams.has(key): return
	var player := voices[voice_index % voices.size()]
	voice_index += 1
	player.stop()
	player.stream = streams[key]
	player.global_position = at
	player.volume_db = volume
	player.pitch_scale = pitch
	player.play()

func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)

func stop_all() -> void:
	for player in voices:
		player.stop()
		player.stream = null
	for player in [wind, river, music]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	streams.clear()
	for i in range(AudioServer.get_bus_effect_count(0)-1, -1, -1):
		if AudioServer.get_bus_effect(0,i) == limiter: AudioServer.remove_bus_effect(0,i)
	limiter = null

func _exit_tree() -> void:
	stop_all()
