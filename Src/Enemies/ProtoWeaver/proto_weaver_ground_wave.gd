class_name ProtoWeaverGroundWave
extends Area2D

const BALANCE_ENERGY_MATERIAL := preload(
	"res://Src/Enemies/ProtoWeaver/proto_weaver_balance_energy_material.tres"
)
const GROUND_WAVE_TEXTURE := preload(
	"res://Assets/VFX/ProtoWeaver/ground_thread_wave_balance_v1.png"
)
const TRAVEL_FRAME_SEQUENCE := [2, 3, 4, 5, 6, 5, 4, 3]
# These values come from the opaque bounds of the authored travel cells:
# 221x54, 206x78, 318x115, 304x132, and 287x141. Independent X/Y
# correction gives the crest a gradual 284x106 to 300x114 rise and fall.
const TRAVEL_SCALE_X_SEQUENCE := [1.285, 1.398, 0.918, 0.974, 1.045, 0.974, 0.918, 1.398]
const TRAVEL_SCALE_Y_SEQUENCE := [1.963, 1.397, 0.974, 0.856, 0.809, 0.856, 0.974, 1.397]
const TRAVEL_FRONT_X_OFFSETS := [103.0, 100.0, 164.0, 152.0, 146.0, 152.0, 164.0, 100.0]
const TRAVEL_BOTTOM_OFFSETS := [71.0, 74.0, 76.0, 78.0, 77.0, 78.0, 76.0, 74.0]
const TRAVEL_FRONT_ANCHOR_X := 164.0

@export var travel_speed := 820.0
@export var lifetime := 1.7
@export var damage_amount := 30
@export var knockback_strength := 230.0
@export var visual_scale := 0.78
@export var growth_time := 0.12
@export var travel_animation_fps := 15.0

var source: Node
var _direction := 1.0
var _travel_direction := Vector2.RIGHT
var _elapsed := 0.0
var _hit_player := false
var _impacting := false
var _impact_elapsed := 0.0
var _impact_duration := 0.22
var _collision_shape: CollisionShape2D
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 3
	z_index = 3
	material = BALANCE_ENERGY_MATERIAL
	area_entered.connect(_on_area_entered)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(150.0, 122.0)
	_collision_shape = CollisionShape2D.new()
	_collision_shape.position = Vector2(18.0, -50.0)
	_collision_shape.shape = shape
	_collision_shape.scale = Vector2(0.78, 0.78 * 0.72)
	add_child(_collision_shape)

	_sprite = Sprite2D.new()
	_sprite.name = "GroundThreadWaveSprite"
	_sprite.texture = GROUND_WAVE_TEXTURE
	_sprite.hframes = 8
	_sprite.vframes = 1
	_sprite.frame = 0
	_sprite.use_parent_material = true
	add_child(_sprite)
	_update_visual()


func launch(direction: int, hit_source: Node) -> void:
	_direction = float(sign(direction)) if direction != 0 else 1.0
	_travel_direction = Vector2(_direction, 0.0)
	source = hit_source
	rotation = 0.0
	scale = Vector2(_direction, 1.0)


func launch_surface(travel_direction: Vector2, surface_side: int, hit_source: Node) -> void:
	_travel_direction = travel_direction.normalized() if travel_direction.length() > 0.01 else Vector2.DOWN
	_direction = 1.0
	source = hit_source
	rotation = _travel_direction.angle()
	# The painted ground seam must face inward from either arena wall.
	scale = Vector2(1.0, float(sign(surface_side)) if surface_side != 0 else 1.0)
	scale.x = _direction


func _physics_process(delta: float) -> void:
	if _impacting:
		_impact_elapsed += delta
		_update_visual()
		if _impact_elapsed >= _impact_duration:
			queue_free()
		return

	_elapsed += delta
	if _elapsed >= lifetime:
		_start_impact()
		return

	global_position += _travel_direction * travel_speed * delta
	if _collision_shape:
		var growth := _get_travel_growth()
		# Preserve a broad horizontal lane while keeping the vertical damage
		# region entirely inside the tallest visible travel frame.
		_collision_shape.scale = Vector2(growth, growth * 0.72)
	_update_visual()


func _update_visual() -> void:
	if not _sprite:
		return
	if _impacting:
		var impact_ratio := clampf(
			_impact_elapsed / maxf(_impact_duration, 0.001),
			0.0,
			1.0
		)
		_sprite.frame = 7
		_sprite.scale = Vector2.ONE * visual_scale * lerpf(1.0, 1.08, impact_ratio)
		_sprite.position = Vector2(
			18.0 + 14.5 * _sprite.scale.x,
			4.0 - 77.0 * _sprite.scale.y
		)
		_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - impact_ratio)
		return

	var growth := _get_travel_growth()
	var scale_x := visual_scale * growth
	var scale_y := visual_scale * growth
	var front_x_offset := 0.0
	var bottom_offset := 73.0
	if _elapsed < growth_time:
		# Frame zero belongs exclusively to the charge orb. The projectile
		# begins on the authored grounded release frame.
		_sprite.frame = 1
	else:
		var travel_phase := (_elapsed - growth_time) * travel_animation_fps
		var sequence_index := floori(travel_phase) % TRAVEL_FRAME_SEQUENCE.size()
		_sprite.frame = TRAVEL_FRAME_SEQUENCE[sequence_index]
		scale_x *= TRAVEL_SCALE_X_SEQUENCE[sequence_index]
		scale_y *= TRAVEL_SCALE_Y_SEQUENCE[sequence_index]
		front_x_offset = TRAVEL_FRONT_X_OFFSETS[sequence_index]
		bottom_offset = TRAVEL_BOTTOM_OFFSETS[sequence_index]
	_sprite.scale = Vector2(scale_x, scale_y)
	# Anchor the painted leading tip and lowest opaque pixel. The eye follows
	# the front of a moving projectile, so center anchoring made differently
	# sized cells appear to jump forward and backward despite steady movement.
	_sprite.position = Vector2(
		TRAVEL_FRONT_ANCHOR_X - front_x_offset * scale_x if _elapsed >= growth_time else 18.0,
		4.0 - bottom_offset * scale_y
	)
	var life_ratio := clampf(_elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - smoothstep(0.88, 1.0, life_ratio))


func _get_travel_growth() -> float:
	return lerpf(0.94, 1.0, smoothstep(0.0, growth_time, _elapsed))


func _on_area_entered(area: Area2D) -> void:
	if _hit_player:
		return
	var hurtbox := area as HurtboxComponent
	if not hurtbox or not hurtbox.hurtbox_owner or not hurtbox.hurtbox_owner.is_in_group("player"):
		return

	var damage := DamageData.new()
	damage.amount = EnemyScaling.scale_damage(damage_amount)
	damage.source = source
	damage.hit_position = global_position
	damage.knockback = _travel_direction * knockback_strength + Vector2.UP * 120.0
	damage.hitstun = 0.22
	damage.hit_pause = 0.045
	if hurtbox.receive_hit(damage):
		_hit_player = true
		set_deferred("monitoring", false)
		_start_impact()


func _start_impact() -> void:
	if _impacting:
		return
	_impacting = true
	_impact_elapsed = 0.0
	set_deferred("monitoring", false)
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)
	_update_visual()
