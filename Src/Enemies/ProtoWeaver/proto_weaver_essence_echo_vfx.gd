class_name ProtoWeaverEssenceEchoVFX
extends Area2D

const ESSENCE_YELLOW := Color(1.0, 0.78, 0.08, 1.0)
const ESSENCE_CORE := Color(1.0, 0.97, 0.72, 1.0)
const ESSENCE_DARK := Color(0.17, 0.1, 0.005, 1.0)

var source: Node
var damage_amount := 24
var echo_delay := 0.50
var active_time := 0.13
var telegraph_duration := 0.96
var release_duration := 0.58
var release_impact_delay := 0.10
var dissipate_time := 0.20
var destination_marker_only := false
var _destination := Vector2.ZERO
var _direction := 1.0
var _elapsed := 0.0
var _trigger_elapsed := 0.0
var _release_elapsed := 0.0
var _dissipate_elapsed := 0.0
var _triggered := false
var _arrival_visible := false
var _release_started := false
var _dissipating := false
var _active := false
var _hit_player := false
var _ghost: Sprite2D
var _ghost_glow: Sprite2D
var _ghost_texture: Texture2D
var _ghost_hframes := 1
var _ghost_vframes := 1
var _ghost_frame := 0
var _ghost_scale := Vector2.ONE
var _ghost_position := Vector2.ZERO


func configure(
	hit_source: Node,
	destination: Vector2,
	direction: int,
	texture: Texture2D,
	hframes: int,
	vframes: int,
	frame: int,
	visual_scale: Vector2,
	visual_position: Vector2,
	hit_damage: int,
	windup_duration: float,
	acts_as_destination := false
) -> void:
	source = hit_source
	_destination = destination
	_direction = float(sign(direction)) if direction != 0 else 1.0
	_ghost_texture = texture
	_ghost_hframes = maxi(1, hframes)
	_ghost_vframes = maxi(1, vframes)
	_ghost_frame = frame
	_ghost_scale = visual_scale
	_ghost_position = visual_position
	damage_amount = hit_damage
	telegraph_duration = maxf(0.05, windup_duration)
	destination_marker_only = acts_as_destination


func _ready() -> void:
	top_level = true
	z_index = 3
	collision_layer = 0
	collision_mask = 2
	monitoring = false
	area_entered.connect(_on_area_entered)

	if not destination_marker_only:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(350.0, 112.0)
		var collision := CollisionShape2D.new()
		collision.position = Vector2(_direction * 210.0, -118.0)
		collision.shape = shape
		add_child(collision)

	_ghost_glow = Sprite2D.new()
	_ghost_glow.name = "EssenceEchoGlow"
	_ghost_glow.texture = _ghost_texture
	_ghost_glow.hframes = _ghost_hframes
	_ghost_glow.vframes = _ghost_vframes
	_ghost_glow.position = _ghost_position
	_ghost_glow.scale = Vector2(absf(_ghost_scale.x) * _direction, _ghost_scale.y) * 1.035
	_ghost_glow.modulate = Color(1.0, 0.68, 0.03, 0.24)
	add_child(_ghost_glow)

	_ghost = Sprite2D.new()
	_ghost.name = "EssenceEcho"
	_ghost.texture = _ghost_texture
	_ghost.hframes = _ghost_hframes
	_ghost.vframes = _ghost_vframes
	_ghost.frame = 0
	_ghost.position = _ghost_position
	_ghost.scale = Vector2(absf(_ghost_scale.x) * _direction, _ghost_scale.y)
	_ghost.modulate = Color(1.0, 0.78, 0.08, 0.56)
	add_child(_ghost)
	queue_redraw()


func mark_arrival() -> void:
	_arrival_visible = true
	queue_redraw()


func complete_destination() -> void:
	if not destination_marker_only or _dissipating:
		return
	_triggered = true
	_arrival_visible = true
	_dissipating = true
	_dissipate_elapsed = 0.0
	monitoring = false
	queue_redraw()


func trigger_echo() -> void:
	if destination_marker_only:
		complete_destination()
		return
	if _triggered:
		return
	_triggered = true
	_trigger_elapsed = 0.0
	_set_ghost_frame(_ghost_frame)
	_run_echo_strike()


func _run_echo_strike() -> void:
	await get_tree().create_timer(echo_delay).timeout
	if not is_inside_tree():
		return
	_begin_echo_release()
	await get_tree().create_timer(release_impact_delay).timeout
	if not is_inside_tree():
		return
	_active = true
	monitoring = true
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	_try_hit_current_overlaps()
	if _ghost:
		_ghost.modulate = Color(1.0, 0.94, 0.58, 0.92)
	CombatFeedback.screen_shake(source if source else self, 2.2, 0.07)
	queue_redraw()
	await get_tree().create_timer(active_time).timeout
	if not is_inside_tree():
		return
	monitoring = false
	_active = false
	var release_tail := maxf(0.0, release_duration - release_impact_delay - active_time)
	if release_tail > 0.0:
		await get_tree().create_timer(release_tail).timeout
	if not is_inside_tree():
		return
	_dissipating = true
	_dissipate_elapsed = 0.0
	await get_tree().create_timer(dissipate_time).timeout
	if is_inside_tree():
		queue_free()


func _begin_echo_release() -> void:
	_triggered = true
	_release_started = true
	_release_elapsed = 0.0
	_set_ghost_frame(_ghost_frame)
	queue_redraw()


func _set_ghost_frame(frame_index: int) -> void:
	var last_frame := maxi(0, _ghost_hframes * _ghost_vframes - 1)
	var safe_frame := clampi(frame_index, 0, last_frame)
	if _ghost:
		_ghost.frame = safe_frame
	if _ghost_glow:
		_ghost_glow.frame = safe_frame


func _process(delta: float) -> void:
	_elapsed += delta
	if _active:
		_try_hit_current_overlaps()
	if not _triggered and _elapsed >= 2.0:
		queue_free()
		return

	if not _triggered:
		var telegraph_ratio := clampf(_elapsed / telegraph_duration, 0.0, 1.0)
		_set_ghost_frame(roundi(lerpf(0.0, float(_ghost_frame), telegraph_ratio)))
	elif destination_marker_only:
		_dissipate_elapsed += delta
		var marker_dissolve := clampf(_dissipate_elapsed / maxf(0.01, dissipate_time), 0.0, 1.0)
		if _ghost:
			_ghost.modulate.a = lerpf(0.72, 0.0, marker_dissolve)
		if _ghost_glow:
			_ghost_glow.modulate.a = lerpf(0.34, 0.0, marker_dissolve)
		if marker_dissolve >= 1.0:
			queue_free()
			return
	elif not _release_started:
		_trigger_elapsed += delta
		_set_ghost_frame(_ghost_frame)
	elif not _dissipating:
		_trigger_elapsed += delta
		_release_elapsed = minf(_release_elapsed + delta, release_duration)
		var release_ratio := clampf(_release_elapsed / maxf(0.01, release_duration), 0.0, 1.0)
		var last_frame := maxi(_ghost_frame, _ghost_hframes * _ghost_vframes - 1)
		_set_ghost_frame(roundi(lerpf(float(_ghost_frame), float(last_frame), release_ratio)))
	else:
		_dissipate_elapsed += delta
		var dissolve_ratio := clampf(_dissipate_elapsed / maxf(0.01, dissipate_time), 0.0, 1.0)
		if _ghost:
			_ghost.modulate.a = lerpf(0.9, 0.0, dissolve_ratio)
		if _ghost_glow:
			_ghost_glow.modulate.a = lerpf(0.28, 0.0, dissolve_ratio)

	if _ghost and not _active and not _dissipating:
		var pulse := 0.5 + sin(_elapsed * 13.0) * 0.5
		_ghost.modulate.a = lerpf(0.50, 0.72, pulse) if not _release_started else lerpf(0.72, 0.9, pulse)
	if _ghost_glow and not _dissipating:
		var glow_pulse := 0.5 + sin(_elapsed * 11.0) * 0.5
		_ghost_glow.modulate.a = lerpf(0.18, 0.34, glow_pulse)
	queue_redraw()


func _draw() -> void:
	var destination_local := _destination - global_position
	var pulse := 0.5 + sin(_elapsed * 12.0) * 0.5
	var path_y := -92.0
	var start := Vector2(_direction * 72.0, path_y)
	var finish := Vector2(destination_local.x, path_y)
	var distance := absf(finish.x - start.x)
	var stitch_count := maxi(4, ceili(distance / 54.0))
	var route_visibility := 1.0 if not _triggered else clampf(1.0 - _trigger_elapsed / 0.14, 0.0, 1.0)
	if route_visibility > 0.0 and not destination_marker_only:
		for stitch in range(stitch_count):
			var from_ratio := float(stitch) / float(stitch_count)
			var to_ratio := minf(1.0, from_ratio + 0.55 / float(stitch_count))
			var color := ESSENCE_CORE if stitch % 3 == 0 else ESSENCE_YELLOW
			draw_line(start.lerp(finish, from_ratio), start.lerp(finish, to_ratio), Color(color.r, color.g, color.b, (0.62 + pulse * 0.18) * route_visibility), 2.0, true)

	for thread in range(5):
		var y := -220.0 + float(thread) * 52.0
		var unravel := Vector2(_direction * (76.0 + float(thread) * 10.0), y)
		draw_line(Vector2(_direction * 18.0, y + 10.0), unravel, Color(ESSENCE_YELLOW.r, ESSENCE_YELLOW.g, ESSENCE_YELLOW.b, 0.38), 1.5, true)
	if destination_marker_only and not _dissipating:
		for ring in range(3):
			var radius := 82.0 + float(ring) * 22.0 + pulse * 5.0
			draw_arc(Vector2(0.0, -118.0), radius, _elapsed * (1.2 + ring * 0.2), _elapsed * (1.2 + ring * 0.2) + 4.7, 24, Color(ESSENCE_YELLOW.r, ESSENCE_YELLOW.g, ESSENCE_YELLOW.b, 0.52 / float(ring + 1)), 2.0, true)

	if _arrival_visible and route_visibility > 0.0:
		for ray in range(8):
			var direction := Vector2.from_angle(float(ray) * TAU / 8.0 + _elapsed * 0.8)
			var arrival_color := Color(ESSENCE_YELLOW.r, ESSENCE_YELLOW.g, ESSENCE_YELLOW.b, route_visibility)
			draw_line(destination_local + direction * 20.0, destination_local + direction * (34.0 + pulse * 12.0), arrival_color, 2.0, true)
	if _release_started and not _dissipating:
		var charge_ratio := clampf(_release_elapsed / maxf(0.01, release_impact_delay), 0.0, 1.0)
		for arc in range(3):
			var radius := 78.0 + float(arc) * 20.0 + pulse * 6.0
			draw_arc(Vector2(0.0, -118.0), radius, -2.7, 0.25, 20, Color(ESSENCE_YELLOW.r, ESSENCE_YELLOW.g, ESSENCE_YELLOW.b, (0.28 + charge_ratio * 0.32) / float(arc + 1)), 2.0, true)
	if _active:
		var slash_start := Vector2(_direction * 45.0, -190.0)
		var slash_end := Vector2(_direction * 390.0, -92.0)
		draw_line(slash_start, slash_end, Color(ESSENCE_DARK.r, ESSENCE_DARK.g, ESSENCE_DARK.b, 0.9), 12.0, true)
		draw_line(slash_start, slash_end, ESSENCE_CORE, 4.0, true)


func _on_area_entered(area: Area2D) -> void:
	if not _active or _hit_player:
		return
	var hurtbox := area as HurtboxComponent
	if not hurtbox or not hurtbox.hurtbox_owner or not hurtbox.hurtbox_owner.is_in_group("player"):
		return
	var damage := DamageData.new()
	damage.amount = EnemyScaling.scale_damage(damage_amount)
	damage.source = source
	damage.hit_position = hurtbox.global_position
	damage.knockback = Vector2(_direction * 250.0, -90.0)
	damage.hitstun = 0.24
	damage.hit_pause = 0.055
	if hurtbox.receive_hit(damage):
		_hit_player = true
		monitoring = false


func _try_hit_current_overlaps() -> void:
	if not _active or _hit_player or not monitoring:
		return
	for area in get_overlapping_areas():
		_on_area_entered(area)
		if _hit_player:
			return
