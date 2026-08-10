class_name ProtoWeaverSmashVFX
extends Node2D

enum PresentationMode { CHARGE, IMPACT }

const POWER_CHARGE_TEXTURE := preload(
	"res://Assets/VFX/ProtoWeaver/threadburst_power_charge_v2.png"
)

@export var lifetime := 0.54
@export var visual_scale := 0.82

var _elapsed := 0.0
var _mode := PresentationMode.IMPACT
var _sprite: Sprite2D


func configure_charge(duration: float, _direction: int = 1, _needle_count: int = 5) -> void:
	_mode = PresentationMode.CHARGE
	lifetime = maxf(0.2, duration)


func configure_impact() -> void:
	_mode = PresentationMode.IMPACT
	lifetime = 0.34


func _ready() -> void:
	z_index = 3
	_sprite = Sprite2D.new()
	_sprite.name = "PowerThreadSpiral"
	_sprite.texture = POWER_CHARGE_TEXTURE
	_sprite.hframes = 6
	_sprite.vframes = 1
	_sprite.scale = Vector2.ONE * visual_scale
	# Every authored cell shares a ground baseline near y=623 of 640.
	_sprite.position = Vector2(0.0, -303.0 * visual_scale)
	add_child(_sprite)
	_update_sprite()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	_update_sprite()


func _update_sprite() -> void:
	if not _sprite:
		return
	var ratio := clampf(_elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	if _mode == PresentationMode.CHARGE:
		# Frames 0-4 build the helix. The separate impact instance owns frame 5,
		# so the charge never flashes the release before the actual slam.
		_sprite.frame = mini(4, floori(ratio * 5.0))
		_sprite.modulate = Color(1.0, 1.0, 1.0, smoothstep(0.0, 0.08, ratio))
		return
	_sprite.frame = 5
	var expansion := lerpf(0.88, 1.08, smoothstep(0.0, 1.0, ratio))
	_sprite.scale = Vector2.ONE * visual_scale * expansion
	_sprite.position = Vector2(0.0, -303.0 * _sprite.scale.y)
	_sprite.modulate = Color(1.0, 1.0, 1.0, pow(1.0 - ratio, 1.25))
