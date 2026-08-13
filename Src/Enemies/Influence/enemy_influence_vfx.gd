class_name EnemyInfluenceVFX
extends Node2D

const RED := Color(1.0, 0.12, 0.08, 1.0)
const BLUE := Color(0.18, 0.58, 1.0, 1.0)
const YELLOW := Color(1.0, 0.82, 0.28, 1.0)
const IVORY := Color(1.0, 0.96, 0.78, 1.0)
const YELLOW_AFTERIMAGE_ALPHAS := [0.38, 0.24, 0.12]

var enemy
var influence := EnemyInfluenceController.Influence.NONE
var _effect_enabled := true
var _aggro_flash := 0.0
var _elapsed := 0.0
var _sample_timer := 0.0
var _blue_history: Array[Vector2] = []
var _yellow_history: Array[Vector2] = []
var _yellow_afterimages: Array[Sprite2D] = []
var _yellow_afterimage_elapsed := 0.0
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
	_yellow_history.clear()
	_clear_yellow_afterimages()
	queue_redraw()

func set_effect_enabled(enabled: bool) -> void:
	_effect_enabled = enabled
	if not enabled:
		_blue_history.clear()
		_yellow_history.clear()
		_clear_yellow_afterimages()
	queue_redraw()

func trigger_aggro() -> void:
	_aggro_flash = 1.0

func begin_yellow_unravel() -> void:
	_yellow_phase_mode = 1
	_yellow_phase_progress = 0.0
	_yellow_afterimage_elapsed = 0.0
	_create_yellow_afterimages()

func begin_yellow_reform() -> void:
	_yellow_phase_mode = 2
	_yellow_phase_progress = 0.0

func set_yellow_phase_progress(progress: float) -> void:
	_yellow_phase_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()

func finish_yellow_phase() -> void:
	_yellow_phase_mode = 0
	_yellow_phase_progress = 0.0
	_clear_yellow_afterimages()
	queue_redraw()

func _process(delta: float) -> void:
	if not enemy or not is_instance_valid(enemy):
		queue_free()
		return
	_elapsed += delta
	_aggro_flash = move_toward(_aggro_flash, 0.0, delta * 2.8)
	if influence == EnemyInfluenceController.Influence.BLUE:
		_update_blue_history(delta)
	elif influence == EnemyInfluenceController.Influence.YELLOW:
		_update_yellow_history(delta)
		_update_yellow_afterimages(delta)
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

func _update_yellow_history(delta: float) -> void:
	if _yellow_phase_mode != 0:
		return
	_sample_timer -= delta
	if _sample_timer > 0.0:
		return
	_sample_timer = 0.075
	_yellow_history.push_front(enemy.global_position)
	while _yellow_history.size() > 5:
		_yellow_history.pop_back()

func _create_yellow_afterimages() -> void:
	_clear_yellow_afterimages()
	var source: Sprite2D = _find_yellow_sprite(enemy.visuals)
	if not source:
		return
	var positions := _yellow_history.duplicate()
	if positions.is_empty():
		positions.append(enemy.global_position)
	while positions.size() < 3:
		positions.append(positions.back())
	var sample_indices: Array[int] = [
		0,
		mini(2, positions.size() - 1),
		mini(4, positions.size() - 1),
	]
	for image_index in 3:
		var afterimage := Sprite2D.new()
		afterimage.texture = source.texture
		afterimage.centered = source.centered
		afterimage.offset = source.offset
		afterimage.region_enabled = source.region_enabled
		afterimage.region_rect = source.region_rect
		afterimage.hframes = source.hframes
		afterimage.vframes = source.vframes
		afterimage.frame = source.frame
		afterimage.flip_h = source.flip_h
		afterimage.flip_v = source.flip_v
		afterimage.z_index = -image_index
		add_child(afterimage)
		afterimage.global_transform = source.global_transform
		afterimage.global_position += positions[sample_indices[image_index]] - enemy.global_position
		var alpha: float = YELLOW_AFTERIMAGE_ALPHAS[image_index]
		afterimage.modulate = Color(1.25, 0.92, 0.22, alpha)
		_yellow_afterimages.append(afterimage)

func _find_yellow_sprite(root: Node) -> Sprite2D:
	if not root:
		return null
	for child in root.get_children():
		if child is Sprite2D and (child as Sprite2D).visible:
			return child as Sprite2D
		var nested := _find_yellow_sprite(child)
		if nested:
			return nested
	return null

func _update_yellow_afterimages(delta: float) -> void:
	if _yellow_afterimages.is_empty():
		return
	_yellow_afterimage_elapsed += delta
	var decay := clampf(1.0 - _yellow_afterimage_elapsed / 0.48, 0.0, 1.0)
	var shimmer := 0.82 + sin(_yellow_afterimage_elapsed * 42.0) * 0.18
	for image_index in _yellow_afterimages.size():
		var afterimage := _yellow_afterimages[image_index]
		if not is_instance_valid(afterimage):
			continue
		var base_alpha: float = YELLOW_AFTERIMAGE_ALPHAS[image_index]
		afterimage.modulate.a = base_alpha * decay * shimmer
	if decay <= 0.0:
		_clear_yellow_afterimages()

func _clear_yellow_afterimages() -> void:
	for afterimage in _yellow_afterimages:
		if is_instance_valid(afterimage):
			afterimage.queue_free()
	_yellow_afterimages.clear()

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
	if _yellow_phase_mode == 1:
		var shimmer_alpha := sin(progress * PI) * 0.5
		for ring in 2:
			draw_arc(
				center,
				26.0 + float(ring) * 11.0 + progress * 9.0,
				-2.8 + progress * 2.0,
				0.35 + progress * 2.0,
				18,
				Color(YELLOW.r, YELLOW.g, YELLOW.b, shimmer_alpha / float(ring + 1)),
				1.8 - float(ring) * 0.35,
				true
			)
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
