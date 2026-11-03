class_name PlayerAnimationClock
extends Node
## Logical action timing, independent of textures and rendered poses.
## The live 3D visual owns animation playback; this clock preserves gameplay
## events and equipment synchronization that previously used sprite frames.

signal frame_changed
signal animation_changed
signal animation_finished
signal animation_looped

const TIMING := preload("res://Src/Characters/Player/player_animation_timing.gd")
const _clips: Dictionary = TIMING.CLIPS
var _animation: StringName = &"Idle"
var _frame := 0
var _progress := 0.0
var _playing := false
var _custom_speed := 1.0

var animation: StringName:
	get: return _animation
	set(value):
		if value == _animation or not has_animation(value): return
		_animation = value
		animation_changed.emit()
		set_frame_and_progress(get_frame_count(value)-1 if get_playing_speed()<0.0 else 0,1.0 if get_playing_speed()<0.0 else 0.0)
var frame: int:
	get: return _frame
	set(value): set_frame_and_progress(value,1.0 if get_playing_speed()<0.0 else 0.0)
var frame_progress: float:
	get: return _progress
	set(value): _progress = clampf(value,0.0,1.0)
var speed_scale := 1.0:
	set(value): speed_scale = Vector2(value,0.0).x

func _process(_delta: float) -> void:
	advance(get_process_delta_time())

func has_animation(name: StringName) -> bool:
	return _clips.has(String(name))

func get_animation_names() -> PackedStringArray:
	var names := PackedStringArray(_clips.keys())
	names.sort()
	return names

func get_frame_count(name: StringName) -> int:
	return int(_clips[String(name)].frames) if has_animation(name) else 0

func get_animation_speed(name: StringName) -> float:
	return float(_clips[String(name)].fps) if has_animation(name) else 0.0

func get_animation_loop(name: StringName) -> bool:
	return bool(_clips[String(name)].loop) if has_animation(name) else false

func get_frame_duration(_name: StringName,_index: int) -> float:
	# Every captured frame has unit weight; no texture resources are required.
	return 1.0

func play(name: StringName = &"",custom_speed := 1.0,from_end := false) -> void:
	if name == &"": name = animation
	if not has_animation(name): return
	_playing = true
	_custom_speed = Vector2(custom_speed,0.0).x
	var end := get_frame_count(name)-1
	if name != animation:
		_animation = name
		set_frame_and_progress(end if from_end else 0,1.0 if from_end else 0.0)
		animation_changed.emit()
	elif from_end and get_playing_speed()<0.0 and frame==0 and frame_progress<=0.0:
		set_frame_and_progress(end,1.0)
	elif not from_end and get_playing_speed()>=0.0 and frame==end and frame_progress>=1.0:
		set_frame_and_progress(0,0.0)

func play_backwards(name: StringName = &"") -> void:
	play(name,-1.0,true)

func pause() -> void:
	_playing = false

func stop() -> void:
	_playing = false
	_custom_speed = 1.0
	set_frame_and_progress(0,0.0)

func is_playing() -> bool:
	return _playing

func get_playing_speed() -> float:
	return speed_scale * _custom_speed if _playing else 0.0

func set_frame_and_progress(index: int,progress: float) -> void:
	var next := clampi(index,0,maxi(0,get_frame_count(animation)-1))
	var changed := next != _frame
	_frame = next
	_progress = clampf(progress,0.0,1.0)
	if changed: frame_changed.emit()

func advance(delta: float) -> void:
	if not _playing or is_zero_approx(get_playing_speed()) or delta <= 0.0: return
	var direction := 1 if get_playing_speed() > 0.0 else -1
	var budget := delta
	var steps := 0
	while budget > 0.0 and _playing:
		# Like the engine clock, leave an exact end boundary on the current
		# frame until another positive slice of time advances it.
		if (direction>0 and _progress>=1.0) or (direction<0 and _progress<=0.0):
			var next := _frame+direction
			if next < 0 or next >= get_frame_count(animation):
				if not get_animation_loop(animation):
					_playing = false
					animation_finished.emit()
					break
				next = 0 if direction>0 else get_frame_count(animation)-1
				animation_looped.emit()
			_frame = next
			_progress = 0.0 if direction>0 else 1.0
			frame_changed.emit()
		var rate := get_animation_speed(animation)*absf(speed_scale*_custom_speed)/get_frame_duration(animation,_frame)
		var remaining := (1.0-_progress if direction>0 else _progress)/rate
		var slice := minf(budget,remaining)
		# Godot's real_t frame progress is single precision in standard builds.
		# Preserve its rounding so frame-triggered gameplay keeps the same tick.
		_progress = Vector2(_progress + float(direction)*slice*rate,0.0).x
		budget -= slice
		steps += 1
		if steps > get_frame_count(animation): return
