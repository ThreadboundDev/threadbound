class_name ThreadMissileLaserMarker
extends Node2D

const LANDING_KNOT_TEXTURE := preload(
	"res://Assets/VFX/ProtoWeaver/threadburst_landing_knot_v2.png"
)

var _flight_progress := 0.0
var _descending := false
var _impacting := false
var _impact_elapsed := 0.0
var _impact_duration := 0.16
var _sprite: Sprite2D


func configure(landing_position: Vector2) -> void:
	top_level = true
	global_position = landing_position
	z_index = 2


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "ThreadburstImpactBurst"
	_sprite.texture = LANDING_KNOT_TEXTURE
	_sprite.hframes = 5
	_sprite.vframes = 1
	_sprite.frame = 4
	_sprite.visible = false
	_sprite.scale = Vector2.ONE * 0.42
	_sprite.position = Vector2(0.0, -100.0 * _sprite.scale.y)
	add_child(_sprite)


func update_flight(_missile_position: Vector2, progress: float, descending: bool) -> void:
	# The falling Power Spindle is the telegraph. Keep only these values for
	# verification and impact timing; nothing is drawn on the ground in flight.
	_flight_progress = clampf(progress, 0.0, 1.0)
	_descending = descending


func trigger_impact() -> void:
	_impacting = true
	_impact_elapsed = 0.0
	if _sprite:
		_sprite.visible = true
		_update_impact_sprite()


func cancel() -> void:
	queue_free()


func _process(delta: float) -> void:
	if not _impacting:
		return
	_impact_elapsed += delta
	if _impact_elapsed >= _impact_duration:
		queue_free()
		return
	_update_impact_sprite()


func _update_impact_sprite() -> void:
	if not _sprite:
		return
	var ratio := clampf(_impact_elapsed / maxf(_impact_duration, 0.001), 0.0, 1.0)
	var wiggle := sin(ratio * TAU * 3.0) * 0.018
	_sprite.frame = 4
	_sprite.scale = Vector2.ONE * 0.42 * (1.0 + wiggle)
	_sprite.position = Vector2(0.0, -100.0 * _sprite.scale.y)
	_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - smoothstep(0.62, 1.0, ratio))
