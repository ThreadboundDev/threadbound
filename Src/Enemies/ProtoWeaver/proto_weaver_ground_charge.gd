class_name ProtoWeaverGroundCharge
extends Node2D

const GROUND_WAVE_TEXTURE := preload(
	"res://Assets/VFX/ProtoWeaver/ground_thread_wave_balance_v1.png"
)
const BALANCE_ENERGY_MATERIAL := preload(
	"res://Src/Enemies/ProtoWeaver/proto_weaver_balance_energy_material.tres"
)

var _duration := 1.0
var _elapsed := 0.0
var _direction := 1.0
var _preview_sprite: Sprite2D

const ORB_SOURCE_CENTER_OFFSET := Vector2(18.5, -27.0)
const ORB_TARGET_POSITION := Vector2(19.5, 2.5)
const ORB_START_SCALE := 0.08
const ORB_RELEASE_SCALE := 0.78
const ORB_FULL_ROTATIONS := 4.0


func configure(direction: int, duration: float) -> void:
	_direction = float(sign(direction)) if direction != 0 else 1.0
	_duration = maxf(0.2, duration)
	position = Vector2(_direction * 154.0, -40.0)
	scale.x = _direction


func _ready() -> void:
	# The boss root sits above the grass, so use an absolute world Z matching
	# the launched wave instead of inheriting the boss's Z index.
	z_as_relative = false
	z_index = 3
	_preview_sprite = Sprite2D.new()
	_preview_sprite.name = "BalanceWavePreview"
	_preview_sprite.texture = GROUND_WAVE_TEXTURE
	_preview_sprite.hframes = 8
	_preview_sprite.frame = 0
	# The painted orb is not centered inside its transparent 350 px cell.
	# Offset the source art so Sprite2D rotation uses the orb itself as pivot.
	_preview_sprite.offset = ORB_SOURCE_CENTER_OFFSET
	_preview_sprite.position = ORB_TARGET_POSITION
	_preview_sprite.material = BALANCE_ENERGY_MATERIAL
	add_child(_preview_sprite)
	_update_preview()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	_update_preview()


func _update_preview() -> void:
	if not _preview_sprite:
		return
	var ratio := clampf(_elapsed / maxf(_duration, 0.001), 0.0, 1.0)
	var gather := smoothstep(0.0, 0.72, ratio)
	var pulse := 0.5 + sin(_elapsed * 12.0) * 0.5
	var alpha := smoothstep(0.0, 0.08, ratio) * (1.0 - smoothstep(0.96, 1.0, ratio))
	var preview_scale := lerpf(ORB_START_SCALE, ORB_RELEASE_SCALE, gather)
	if gather >= 1.0:
		preview_scale *= lerpf(0.985, 1.015, pulse)
	_preview_sprite.scale = Vector2.ONE * preview_scale
	# Smoothstep gives the spin a clean acceleration and deceleration while
	# the integer turn count guarantees the orb returns to frame-one's exact
	# painted orientation before the grounded frame appears.
	var spin_ratio := smoothstep(0.0, 1.0, ratio)
	_preview_sprite.rotation = TAU * ORB_FULL_ROTATIONS * spin_ratio
	_preview_sprite.modulate = Color(1.0, 1.0, 1.0, alpha * lerpf(0.86, 0.98, pulse))
