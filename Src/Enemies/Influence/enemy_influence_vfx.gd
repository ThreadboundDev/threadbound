class_name EnemyInfluenceVFX
extends Node2D

const RED := Color(1.0, 0.12, 0.08, 1.0)
const BLUE := Color(0.18, 0.58, 1.0, 1.0)
const YELLOW := Color(1.0, 0.82, 0.28, 1.0)
const IVORY := Color(1.0, 0.96, 0.78, 1.0)

var enemy
var influence := EnemyInfluenceController.Influence.NONE
var _effect_enabled := true
var _aggro_flash := 0.0
var _elapsed := 0.0
var _sample_timer := 0.0
var _blue_history: Array[Vector2] = []
var _yellow_phase_mode := 0
var _yellow_phase_progress := 0.0

func configure(owner_enemy, new_influence: int) -> void:
	enemy = owner_enemy
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_as_relative = false
	z_index = enemy.z_index + 1
	set_influence(new_influence)

func set_influence(new_influence: int) -> void:
	influence = new_influence
	_blue_history.clear()
	queue_redraw()

func set_effect_enabled(enabled: bool) -> void:
	_effect_enabled = enabled
	if not enabled:
		_blue_history.clear()
	queue_redraw()

func trigger_aggro() -> void:
	_aggro_flash = 1.0

func begin_yellow_unravel() -> void:
	_yellow_phase_mode = 1
	_yellow_phase_progress = 0.0

func begin_yellow_reform() -> void:
	_yellow_phase_mode = 2
	_yellow_phase_progress = 0.0

func set_yellow_phase_progress(progress: float) -> void:
	_yellow_phase_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()

func finish_yellow_phase() -> void:
	_yellow_phase_mode = 0
	_yellow_phase_progress = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if not enemy or not is_instance_valid(enemy):
		queue_free()
		return
	_elapsed += delta
	_aggro_flash = move_toward(_aggro_flash, 0.0, delta * 2.8)
	if influence == EnemyInfluenceController.Influence.BLUE:
		_update_blue_history(delta)
	queue_redraw()

func _update_blue_history(delta: float) -> void:
	_sample_timer -= delta
	if enemy.velocity.length() < 55.0:
		if not _blue_history.is_empty():
			_blue_history.pop_back()
		return
	if _sample_timer > 0.0:
		return
	_sample_timer = 0.045
	_blue_history.push_front(enemy.global_position + Vector2(0.0, -48.0))
	while _blue_history.size() > 6:
		_blue_history.pop_back()

func _draw() -> void:
	if not _effect_enabled or not enemy or enemy.is_dead:
		return
	match influence:
		EnemyInfluenceController.Influence.RED:
			_draw_red_threads()
		EnemyInfluenceController.Influence.BLUE:
			_draw_blue_threads()
		EnemyInfluenceController.Influence.YELLOW:
			_draw_yellow_threads()

func _draw_red_threads() -> void:
	var center: Vector2 = enemy.global_position + Vector2(0.0, -48.0)
	var quiet_pulse := maxf(0.0, sin(_elapsed * 2.2)) * 0.1
	var strength := 0.13 + quiet_pulse + _aggro_flash * 0.52
	for strand in 3:
		var side := -1.0 if strand % 2 == 0 else 1.0
		var phase := _elapsed * (1.7 + strand * 0.18)
		var points := PackedVector2Array([
			center + Vector2(side * (17.0 + strand * 3.0), 30.0),
			center + Vector2(side * (8.0 + sin(phase) * 5.0), 8.0),
			center + Vector2(-side * (5.0 + cos(phase) * 4.0), -12.0),
			center + Vector2(side * 11.0, -31.0),
		])
		draw_polyline(points, Color(RED.r, RED.g, RED.b, strength), 1.6, true)
	if _aggro_flash > 0.02:
		draw_arc(center, 36.0 + (1.0 - _aggro_flash) * 12.0, -2.6, 0.45, 18, Color(RED.r, RED.g, RED.b, _aggro_flash * 0.34), 2.0, true)

func _draw_blue_threads() -> void:
	if _blue_history.size() < 2:
		return
	var speed_ratio: float = clampf(enemy.velocity.length() / 380.0, 0.0, 1.0)
	for strand in 3:
		var points := PackedVector2Array()
		var offset_y := float(strand - 1) * 8.0
		for index in _blue_history.size():
			var taper := float(index) / float(maxi(_blue_history.size() - 1, 1))
			points.append(_blue_history[index] + Vector2(0.0, offset_y + sin(_elapsed * 5.0 + index + strand) * 2.0 * taper))
		var alpha := (0.28 - strand * 0.045) * speed_ratio
		draw_polyline(points, Color(BLUE.r, BLUE.g, BLUE.b, alpha), 1.8 - strand * 0.25, true)

func _draw_yellow_threads() -> void:
	var center: Vector2 = enemy.global_position + Vector2(0.0, -48.0)
	if _yellow_phase_mode == 0:
		if enemy.target:
			return
		var flicker := maxf(0.0, sin(_elapsed * 3.7 + enemy.get_instance_id() * 0.01))
		if flicker < 0.72:
			return
		var alpha := (flicker - 0.72) * 0.42
		draw_line(center + Vector2(-18.0, 25.0), center + Vector2(-8.0, -18.0), Color(YELLOW.r, YELLOW.g, YELLOW.b, alpha), 1.3, true)
		draw_line(center + Vector2(13.0, 18.0), center + Vector2(19.0, -24.0), Color(IVORY.r, IVORY.g, IVORY.b, alpha * 0.72), 1.1, true)
		return

	var progress := _yellow_phase_progress
	var outward := progress if _yellow_phase_mode == 1 else 1.0 - progress
	for strand in 8:
		var ratio := float(strand) / 7.0
		var angle := -2.7 + ratio * 5.4
		var radial := Vector2(cos(angle), sin(angle))
		var tangent := Vector2(-radial.y, radial.x)
		var start := center + tangent * lerpf(-24.0, 24.0, ratio)
		var finish := start + radial * lerpf(12.0, 58.0, outward)
		var color := YELLOW if strand % 2 == 0 else IVORY
		var alpha := lerpf(0.72, 0.12, outward)
		draw_line(start, finish, Color(color.r, color.g, color.b, alpha), 1.4 + (strand % 3) * 0.25, true)
