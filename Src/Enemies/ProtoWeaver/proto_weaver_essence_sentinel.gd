class_name ProtoWeaverEssenceSentinel
extends Area2D

const ESSENCE_YELLOW := Color(1.0, 0.78, 0.08, 1.0)

var source: Node
var target: Node2D
var damage_amount := 24
var trigger_radius := 235.0
var rearm_time := 1.35
var windup_time := 0.38
var active_time := 0.14

var _direction := 1
var _texture: Texture2D
var _hframes := 1
var _vframes := 1
var _hold_frame := 0
var _visual_scale := Vector2.ONE
var _visual_position := Vector2.ZERO
var _sprite: Sprite2D
var _glow: Sprite2D
var _busy := false
var _dismissed := false
var _hit_player := false
var _elapsed := 0.0


func configure(
	hit_source: Node,
	tracked_target: Node2D,
	direction: int,
	texture: Texture2D,
	hframes: int,
	vframes: int,
	hold_frame: int,
	visual_scale: Vector2,
	visual_position: Vector2,
	hit_damage: int,
	activation_radius: float,
	cooldown: float
) -> void:
	source = hit_source
	target = tracked_target
	_direction = signi(direction) if direction != 0 else 1
	_texture = texture
	_hframes = maxi(1, hframes)
	_vframes = maxi(1, vframes)
	_hold_frame = hold_frame
	_visual_scale = visual_scale
	_visual_position = visual_position
	damage_amount = hit_damage
	trigger_radius = activation_radius
	rearm_time = cooldown


func _ready() -> void:
	top_level = true
	z_index = 3
	collision_layer = 0
	collision_mask = 2
	monitoring = false
	area_entered.connect(_on_area_entered)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(350.0, 112.0)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(float(_direction) * 210.0, -118.0)
	collision.shape = shape
	add_child(collision)
	_glow = _make_sprite("SentinelGlow", Color(1.0, 0.68, 0.03, 0.23), 1.035)
	_sprite = _make_sprite("Sentinel", Color(1.0, 0.78, 0.08, 0.52), 1.0)


func _make_sprite(node_name: String, color: Color, extra_scale: float) -> Sprite2D:
	var result := Sprite2D.new()
	result.name = node_name
	result.texture = _texture
	result.hframes = _hframes
	result.vframes = _vframes
	result.position = _visual_position
	# Proto-Weaver's source sheets face left. Match the real boss convention:
	# positive gameplay direction flips the art to face right.
	result.scale = Vector2(-absf(_visual_scale.x) * float(_direction), _visual_scale.y) * extra_scale
	result.modulate = color
	add_child(result)
	return result


func _process(delta: float) -> void:
	_elapsed += delta
	if _dismissed or _busy or not is_instance_valid(target):
		return
	var player_delta := target.global_position - global_position
	if player_delta.length() <= trigger_radius:
		_direction = signi(player_delta.x) if absf(player_delta.x) > 1.0 else _direction
		_update_facing()
		_strike()
	var pulse := 0.5 + sin(_elapsed * 7.0) * 0.5
	if _sprite:
		_sprite.modulate.a = lerpf(0.44, 0.60, pulse)
	if _glow:
		_glow.modulate.a = lerpf(0.16, 0.27, pulse)


func _strike() -> void:
	_busy = true
	_hit_player = false
	await _animate_frames(0, _hold_frame, windup_time)
	if _dismissed or not is_inside_tree():
		return
	monitoring = true
	await _wait_for_gameplay_physics_frame()
	_try_hit_current_overlaps()
	await _animate_frames(_hold_frame, _hframes * _vframes - 1, active_time)
	monitoring = false
	if _dismissed or not is_inside_tree():
		return
	await get_tree().create_timer(rearm_time, false).timeout
	if _dismissed or not is_inside_tree():
		return
	_set_frame(0)
	_busy = false


func _animate_frames(first: int, last: int, duration: float) -> void:
	var timer := 0.0
	while timer < duration and is_inside_tree() and not _dismissed:
		_set_frame(roundi(lerpf(float(first), float(last), timer / maxf(duration, 0.001))))
		await _wait_for_gameplay_frame()
		timer += get_process_delta_time()
	_set_frame(last)


func _set_frame(value: int) -> void:
	var safe := clampi(value, 0, maxi(0, _hframes * _vframes - 1))
	if _sprite:
		_sprite.frame = safe
	if _glow:
		_glow.frame = safe


func _wait_for_gameplay_frame() -> void:
	var tree := get_tree()
	await tree.process_frame
	while tree.paused and is_inside_tree():
		await tree.process_frame


func _wait_for_gameplay_physics_frame() -> void:
	var tree := get_tree()
	while tree.paused and is_inside_tree():
		await tree.process_frame
	await tree.physics_frame


func _update_facing() -> void:
	for visual in [_sprite, _glow]:
		if visual:
			visual.scale.x = -absf(visual.scale.x) * float(_direction)
	var collision := get_child(0) as CollisionShape2D
	if collision:
		collision.position.x = float(_direction) * 210.0


func dismiss() -> void:
	_dismissed = true
	monitoring = false
	var tween := create_tween()
	tween.set_parallel(true)
	if _sprite:
		tween.tween_property(_sprite, "modulate:a", 0.0, 0.18)
	if _glow:
		tween.tween_property(_glow, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


func _on_area_entered(area: Area2D) -> void:
	if not monitoring or _hit_player:
		return
	var hurtbox := area as HurtboxComponent
	if not hurtbox or not hurtbox.hurtbox_owner or not hurtbox.hurtbox_owner.is_in_group("player"):
		return
	var damage := DamageData.new()
	damage.amount = EnemyScaling.scale_damage(damage_amount)
	damage.source = source
	damage.hit_position = hurtbox.global_position
	damage.knockback = Vector2(float(_direction) * 250.0, -90.0)
	damage.hitstun = 0.24
	damage.hit_pause = 0.055
	if hurtbox.receive_hit(damage):
		_hit_player = true
		monitoring = false


func _try_hit_current_overlaps() -> void:
	for area in get_overlapping_areas():
		_on_area_entered(area)
		if _hit_player:
			return
